# Copyright (c) 2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative '../client'
require_relative '../../constants'
Cisco::Client.silence_warnings do
  require 'grpc'
end
require 'json'
require_relative 'ems_services'

include IOSXRExtensibleManagabilityService
include Cisco::Logger

module Cisco
  class Client
    # Client implementation using gRPC API for IOS XR
    class GRPC < Client
      register_client(self)

      attr_accessor :timeout

      # Let commands in general take up to 2 minutes
      DEFAULT_TIMEOUT = 120

      def initialize(**kwargs)
        # Defaults for gRPC:
        kwargs[:host] ||= '127.0.0.1'
        kwargs[:port] ||= 57_400
        # rubocop:disable Style/HashSyntax
        super(platform:     :ios_xr,
              **kwargs)
        # rubocop:enable Style/HashSyntax
        @config = GRPCConfigOper::Stub.new(@address, :this_channel_is_insecure, timeout: DEFAULT_TIMEOUT)
        @exec = GRPCExec::Stub.new(@address, :this_channel_is_insecure, timeout: DEFAULT_TIMEOUT)

        # Make sure we can actually connect (with a short timeout)
        @timeout = 10

        begin
          base_msg = 'gRPC client creation failure: '
          get(command: '{"Cisco-IOS-XR-shellutil-oper:system-time": "clock"}', mode: :get_oper)
        rescue Cisco::ClientError => e
          error 'initial connect failed: ' + e.to_s
          # Some peer police connection attempt rate require some time between connection attempts.
          if e.message[/deadline exceeded/i]
            raise Cisco::ConnectionRefused, \
                  base_msg + 'timed out during initial connection: ' + e.message
          end
          raise e.class, base_msg + e.message
        end

        @timeout = DEFAULT_TIMEOUT
      end

      def raise_cisco(e)
        case e.code
        when ::GRPC::Core::StatusCodes::UNAVAILABLE
          fail Cisco::ConnectionRefused, "Connection refused: #{e.details}"
        when ::GRPC::Core::StatusCodes::UNAUTHENTICATED
          fail Cisco::AuthenticationFailed, e.details
        else
          fail Cisco::ClientError, e.details
        end
      end

      def self.validate_args(**kwargs)
        super
        base_msg = 'gRPC client creation failure: '
        # Connection to remote system - username and password are required
        fail TypeError, base_msg + 'username must be specified' \
          if kwargs[:username].nil?
        fail TypeError, base_msg + 'password must be specified' \
          if kwargs[:password].nil?
      end

      # Configure the given command(s) on the device.
      #
      # @param values [Array<String>] One or more commands to execute /
      #                               config strings to send
      # @param kwargs data-format-specific args
      def set(values: nil,
              **kwargs)
        super
        mode = kwargs[:mode] || :merge_config
        fail ArgumentError unless Cisco::Util::YANG_SET_MODE.include? mode
        yang_req(@config, mode.to_s, ConfigArgs.new(yangjson: values))
      end

      def get(command: nil,
              **kwargs)
        super
        fail ArgumentError if command.nil?
        mode = kwargs[:mode] || :get_config
        yang_req(@config, mode, ConfigGetArgs.new(yangpathjson: command))
      end

      # Send a YANG request via gRPC
      def yang_req(stub, type, args)
        debug "Sending '#{type}' request:"
        if args.is_a?(ConfigGetArgs)
          debug "  with yangpathjson: #{args.yangpathjson}"
        elsif args.is_a?(ConfigArgs)
          debug " with yangjson: #{args.yangjson}"
        end

        output = Cisco::Client.silence_warnings do
          metadata = {
            'timeout'  => "#{@timeout}",
            'username' => "#{@username}",
            'password' => "#{@password}",
          }
          deadline = Time.new + @timeout
          response = stub.send(type, args, deadline: deadline,  metadata: metadata)
          #          response = stub.send(type, args, timeout: @timeout, username: "#{@username}", password: "#{@password}")

          # gRPC server may split the response into multiples
          response = response.is_a?(Enumerator) ? response.to_a : [response]
          debug "Got responses: #{response.map(&:class).join(', ')}"
          debug "response: #{response}"
          # Check for errors first
          handle_errors(args, response.select { |r| !r.errors.empty? })

          # If we got here, no errors occurred
          return handle_response(args, response)
        end
        return output

      rescue ::GRPC::BadStatus => e
        warn "gRPC error '#{e.code}' during '#{type}' request: "
        if args.is_a?(ConfigGetArgs)
          debug "  with yangpathjson: #{args.yangpathjson}"
        elsif args.is_a?(ConfigArgs)
          debug " with yangjson: #{args.yangjson}"
        end

        warn "  '#{e.details}'"
        raise_cisco(e)
      end

      def get_cli(command, regex=nil)
        args = ShowCmdArgs.new(cli: command)
        output = cli_req(@exec, 'show_cmd_text_output', args)

        return regex.match(output)[1] if regex

        output
      end

      def cli_req(stub, type, args)
        debug "Sending '#{type}' request:"
        if args.is_a?(ShowCmdArgs) || args.is_a?(CliConfigArgs)
          debug "  with cli: '#{args.cli}'"
        end
        output = Cisco::Client.silence_warnings do
          metadata = {
            'timeout'  => "#{@timeout}",
            'username' => "#{@username}",
            'password' => "#{@password}",
          }
          deadline = Time.new + @timeout
          response = stub.send(type, args, deadline: deadline,  metadata: metadata)

          # gRPC server may split the response into multiples
          response = response.is_a?(Enumerator) ? response.to_a : [response]
          debug "Got responses: #{response.map(&:class).join(', ')}"
          # Check for errors first
          handle_errors(args, response.select { |r| !r.errors.empty? })

          # If we got here, no errors occurred
          handle_response(args, response)
        end

        return output
      rescue ::GRPC::BadStatus => e
        warn "gRPC error '#{e.code}' during '#{type}' request: "
        if args.is_a?(ShowCmdArgs) || args.is_a?(CliConfigArgs)
          warn "  with cli: '#{args.cli}'"
        end
        warn "  '#{e.details}'"
        raise_cisco(e)
      end

      def handle_response(args, replies)
        klass = replies[0].class
        unless replies.all? { |r| r.class == klass }
          fail Cisco::ClientError, 'reply class inconsistent: ' +
            replies.map(&:class).join(', ')
        end
        debug "Handling #{replies.length} '#{klass}' reply(s):"
        case klass.to_s
        when /ShowCmdJSONReply/
          # TODO: not yet supported by server to test against
          replies.each { |r| debug "  jsonoutput:\n#{r.jsonoutput}" }
          output = replies.map(&:jsonoutput).join("\n---\n")
        when /ShowCmdTextReply/
          replies.each { |r| debug "  output:\n#{r.output}" }
          output = replies.map(&:output).join('')
          output = handle_text_output(args, output)
        when /CliConfigReply/
          # nothing to process
          output = ''
        when /ConfigGetReply/
          replies.each { |r| debug "  yangjson:\n#{r.yangjson}" }
          output = replies.map(&:yangjson).join('')
        when /GetOperReply/
          replies.each { |r| debug "  yangjson:\n#{r.yangjson}" }
          output = replies.map(&:yangjson).join('')
        when /ConfigReply/
          # nothing to process
          output = ''
        else
          fail Cisco::ClientError, "unsupported reply class #{klass}"
        end
        debug "Success with output:\n#{output}"
        output
      end

      def handle_errors(args, error_responses)
        return if error_responses.empty?
        debug "#{error_responses.length} response(s) had errors:"
        error_responses.each { |r| debug "  error:\n#{r.errors}" }
        first_error = error_responses.first.errors
        # Conveniently for us, all *Reply protobufs in EMS have an errors field
        # Less conveniently, some are JSON and some are not.
        begin
          msg = JSON.parse(first_error)
          handle_json_error(args, msg)
        rescue JSON::ParserError
          handle_text_error(args, first_error)
        end
      end

      def handle_text_output(args, output)
        # For a successful show command, gRPC presents the output as:
        # \n--------- <cmd> ----------
        # \n<output of command>
        # \n\n

        # For an invalid CLI, gRPC presents the output as:
        # \n--------- <cmd> --------
        # \n<cmd>
        # \n<error output>
        # \n\n

        # Discard the leading whitespace, header, and trailing whitespace
        output = output.split("\n").drop(2)
        return '' if output.nil? || output.empty?

        # Now we have either [<output_line_1>, <output_line_2>, ...] or
        # [<cmd>, <error_line_1>, <error_line_2>, ...]
        if output[0].strip == args.cli.strip
          fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
            rejected_input: args.cli,
            clierror:       output.join("\n"),
          )
        end
        output.join("\n")
      end

      # Generate an error from a failed request
      def handle_text_error(args, msg)
        if /^Disallowed commands:/ =~ msg
          fail Cisco::RequestNotSupported, msg
        elsif args.is_a?(ConfigGetArgs) || args.is_a?(ConfigArgs)
          fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
            rejected_input: args.yangpathjson,
            error:          msg,
          )
        else
          fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
            rejected_input: args.cli,
            clierror:       msg,
          )
        end
      end

      # Generate a CliError from a failed CliConfigReply
      def handle_json_error(args, msg)
        # {
        #   "cisco-grpc:errors": {
        #   "error": [
        #     {
        #       "error-type": "application",
        #       "error-tag": "operation-failed",
        #       "error-severity": "error",
        #       "error-message": "....",
        #     },
        #     {
        #       ...

        # {
        #   "cisco-grpc:errors": [
        #     {
        #       "error-type": "protocol",
        #       "error-message": "Failed authentication"
        #     }
        #   ]
        # }

        msg = msg['cisco-grpc:errors']
        msg = msg['error'] unless msg.is_a?(Array)
        msg.each do |m|
          type = m['error-type']
          message = m['error-message'] || m['error-tag']
          message += ': ' + m['error-path'] if m['error-path']
          if type == 'protocol' && message == 'Failed authentication'
            fail Cisco::AuthenticationFailed, message
          elsif type == 'application'
            # Example message:
            # !! SYNTAX/AUTHORIZATION ERRORS: This configuration failed due to
            # !! one or more of the following reasons:
            # !!  - the entered commands do not exist,
            # !!  - the entered commands have errors in their syntax,
            # !!  - the software packages containing the commands are not active,
            # !!  - the current user is not a member of a task-group that has
            # !!    permissions to use the commands.
            #
            # foo
            # bar
            #
            if m['error-path']
              fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
                message
              )
            end
          elsif type == 'protocol'
            if args.is_a?(ConfigGetArgs)
              input = args.yangpathjson
            elsif args.is_a?(ConfigArgs)
              input = args.yangjson
            end
            fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
              rejected_input: input,
              error:          message,
            )
          else
            fail Cisco::ClientError, message
          end
        end
      end

      def system_time
        unless defined? @system_time
          filter = '{"Cisco-IOS-XR-shellutil-oper:system-time":"uptime"}'
          reply = get(command: filter, mode: :get_oper)
          @system_time = JSON.parse(reply)
        end
        @system_time
      end

      def diag
        unless defined? @diag
          filter = '{"Cisco-IOS-XR-sdr-invmgr-diag-oper:diag":"racks"}'
          reply = get(command: filter, mode: :get_oper)
          begin
            @diag = JSON.parse(reply)
            puts "Successfully parsed GRPC reply from get_oper in \"diag\""
          rescue => e
            puts "Failed to parse GRPC reply \"#{reply}\" from get_oper in \"diag\" with error #{e}"
          end
        end
        @diag
      end

      def inventory
        unless defined? @inventory
          filter = '{"Cisco-IOS-XR-invmgr-oper:inventory":"racks"}'
          reply = get(command: filter, mode: :get_oper)
          @inventory = JSON.parse(reply)
        end
        @inventory
      end

      def host_name
        return '' unless system_time
        system_time['Cisco-IOS-XR-shellutil-oper:system-time']['uptime']['host-name']
      end

      def product_id
        return diag['Cisco-IOS-XR-sdr-invmgr-diag-oper:diag']['racks']['rack'][0]['chassis']['pid']
      rescue
        puts "Unexpected diag value: #{diag}"
        return ''
      end

      def system
        get_cli('sh install active', /^\s*(\S*)\s*version.*\[Boot image\]$/)
      end

      def yang_target(module_name, _namespace, container)
        "{\"#{module_name}:#{container}\": [null]}"
      end
    end
  end
end

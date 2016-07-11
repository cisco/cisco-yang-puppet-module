#!/usr/bin/env ruby
#
# October 2015, Glenn F. Matthews
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
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

# Client implementation using gRPC API for IOS XR
class Cisco::Client::GRPC < Cisco::Client
  register_client(self)

  attr_accessor :timeout

  def initialize(**kwargs)
    # Defaults for gRPC:
    kwargs[:host] ||= '127.0.0.1'
    kwargs[:port] ||= 57_400
    # rubocop:disable Style/HashSyntax
    super(data_formats: [:cli, :yang_json],
          platform:     :ios_xr,
          **kwargs)
    # rubocop:enable Style/HashSyntax
    @config = GRPCConfigOper::Stub.new(@address, :this_channel_is_insecure)
    @exec = GRPCExec::Stub.new(@address, :this_channel_is_insecure)

    # Make sure we can actually connect
    @timeout = 10
    begin
      base_msg = 'gRPC client creation failure: '
      get(command: 'show clock')
    rescue Cisco::ClientError => e
      error 'initial connect failed: ' + e.to_s
      # Some peer police connection attempt rate require some time between connection attempts.
      sleep(1)
      if e.message[/deadline exceeded/i]
        raise Cisco::ConnectionRefused, \
              base_msg + 'timed out during initial connection: ' + e.message
      end
      raise e.class, base_msg + e.message
    end

    # Let commands in general take up to 2 minutes
    @timeout = 120
  end

  def wants_cmd_ref
    false
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

  def cache_flush
    @cache_hash = {
      'cli_config'           => {},
      'show_cmd_text_output' => {},
      'show_cmd_json_output' => {},
    }
  end

  # Configure the given CLI command(s) on the device.
  #
  # @param data_format one of Cisco::DATA_FORMATS. Default is :cli
  # @param context [Array<String>] Zero or more configuration commands used
  #                to enter the desired CLI sub-mode
  # @param values [Array<String>] One or more commands to execute /
  #                               config strings to send
  # @param kwargs data-format-specific args
  def set(data_format: :cli,
          context:     nil,
          values:      nil,
          **kwargs)
    context = munge_to_array(context)
    values = munge_to_array(values)
    super
    if data_format == :yang_json
      mode = kwargs[:mode] || :merge_config
      fail ArgumentError unless Cisco::YANG_SET_MODE.include? mode
      values.each do |yang|
        yang_req(@config, mode.to_s, ConfigArgs.new(yangjson: yang))
      end
    else
      # IOS XR lets us concatenate submode commands together.
      # This makes it possible to guarantee we are in the correct context:
      #   context: ['foo', 'bar'], values: ['baz', 'bat']
      #   ---> values: ['foo bar baz', 'foo bar bat']
      # However, there's a special case for 'no' commands:
      #   context: ['foo', 'bar'], values: ['no baz']
      #   ---> values: ['no foo bar baz'] ---- the 'no' goes at the start
      context = context.join(' ')
      unless context.empty?
        values.map! do |cmd|
          match = cmd[/^\s*no\s+(.*)/, 1]
          if match
            cmd = "no #{context} #{match}"
          else
            cmd = "#{context} #{cmd}"
          end
          cmd
        end
      end
      # CliConfigArgs wants a newline-separated string of commands
      args = CliConfigArgs.new(cli: values.join("\n"))
      req(@config, 'cli_config', args)
    end
  end

  def get(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil,
          **kwargs)
    super
    fail ArgumentError if command.nil?

    if data_format == :yang_json
      mode = kwargs[:mode] || :get_config
      yang_req(@config, mode, ConfigGetArgs.new(yangpathjson: command))
    else
      args = ShowCmdArgs.new(cli: command)
      output = req(@exec, 'show_cmd_text_output', args)
      self.class.filter_cli(cli_output: output, context: context, value: value)
    end
  end

  def req(stub, type, args)
    if cache_enable? && @cache_hash[type] && @cache_hash[type][args.cli]
      return @cache_hash[type][args.cli]
    end

    debug "Sending '#{type}' request:"
    if args.is_a?(ShowCmdArgs) || args.is_a?(CliConfigArgs)
      debug "  with cli: '#{args.cli}'"
    end
    output = Cisco::Client.silence_warnings do
      response = stub.send(type, args,
                           timeout:  @timeout,
                           username: @username,
                           password: @password)
      # gRPC server may split the response into multiples
      response = response.is_a?(Enumerator) ? response.to_a : [response]
      debug "Got responses: #{response.map(&:class).join(', ')}"
      # Check for errors first
      handle_errors(args, response.select { |r| !r.errors.empty? })

      # If we got here, no errors occurred
      handle_response(args, response)
    end

    @cache_hash[type][args.cli] = output if cache_enable? && !output.empty?
    return output
  rescue ::GRPC::BadStatus => e
    warn "gRPC error '#{e.code}' during '#{type}' request: "
    if args.is_a?(ShowCmdArgs) || args.is_a?(CliConfigArgs)
      warn "  with cli: '#{args.cli}'"
    end
    warn "  '#{e.details}'"
    case e.code
    when ::GRPC::Core::StatusCodes::UNAVAILABLE
      raise Cisco::ConnectionRefused, "Connection refused: #{e.details}"
    when ::GRPC::Core::StatusCodes::UNAUTHENTICATED
      raise Cisco::AuthenticationFailed, e.details
    else
      raise Cisco::ClientError, e.details
    end
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
      response = stub.send(type, args,
                           timeout:  @timeout,
                           username: @username,
                           password: @password)
      # gRPC server may split the response into multiples
      response = response.is_a?(Enumerator) ? response.to_a : [response]
      debug "Got responses: #{response.map(&:class).join(', ')}"
      debug "response: #{response}"
      # Check for errors first
      handle_errors(args, response.select { |r| !r.errors.empty? })

      # If we got here, no errors occurred
      handle_response(args, response)
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
    case e.code
    when ::GRPC::Core::StatusCodes::UNAVAILABLE
      raise Cisco::ConnectionRefused, "Connection refused: #{e.details}"
    when ::GRPC::Core::StatusCodes::UNAUTHENTICATED
      raise Cisco::AuthenticationFailed, e.details
    else
      raise Cisco::ClientError, e.details
    end
  end

  def handle_response(args, replies)
    klass = replies[0].class
    unless replies.all? { |r| r.class == klass }
      fail Cisco::ClientError, 'reply class inconsistent: ' +
        replies.map(&:class).join(', ')
    end
    debug "Handling #{replies.length} '#{klass}' reply(s):"
    case klass.to_s
    when /ShowCmdTextReply/
      replies.each { |r| debug "  output:\n#{r.output}" }
      output = replies.map(&:output).join('')
      output = handle_text_output(args, output)
    when /ShowCmdJSONReply/
      # TODO: not yet supported by server to test against
      replies.each { |r| debug "  jsonoutput:\n#{r.jsonoutput}" }
      output = replies.map(&:jsonoutput).join("\n---\n")
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

  def handle_errors(args, error_responses)
    return if error_responses.empty?
    debug "#{error_responses.length} response(s) had errors:"
    error_responses.each { |r| debug "  error:\n#{r.errors}" }
    first_error = error_responses.first.errors
    # Conveniently for us, all *Reply protobufs in EMS have an errors field
    # Less conveniently, some are JSON and some are not.
    begin
      msg = JSON.parse(first_error)
      handle_json_error(msg)
    rescue JSON::ParserError
      handle_text_error(args, first_error)
    end
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
  def handle_json_error(msg)
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
        else
          match = /\n\n(.*)\n\n\Z/m.match(message)
          if match.nil?
            rejected = '(unknown, see error message)'
          else
            rejected = match[1].split("\n")
          end
          fail Cisco::CliError.new( # rubocop:disable Style/RaiseArgs
            rejected_input: rejected,
            clierror:       message,
          )
        end
      else
        fail Cisco::ClientError, message
      end
    end
  end

  def get_os
    output = get(command:     'show version',
                 data_format: :cli)
    return /Cisco.*Software/.match(output).to_s
  end

  def get_os_version
    output = get(command:     'show version',
                 data_format: :cli)
    return /IOS XR.*Version (.*)$/.match(output)[1]
  end

  def get_product_description
    output = get(command:     'show inventory',
                  data_format: :cli)
    return /NAME: "Rack 0".*DESCR: "(.*)"/.match(output)[1]
  end

  def get_product_id
    output = get(command:     'show inventory',
                  data_format: :cli)
    return /NAME: "Rack 0".*\nPID: (\S+)/.match(output)[1]
  end

  def get_product_version_id
    output = get(command:     'show inventory',
                  data_format: :cli)
    return /"Rack 0".*\n.*VID: ([^ ,]+)/.match(output)[1]
  end

  def get_product_serial_number
    output = get(command:     'show inventory',
                  data_format: :cli)
    return /Rack 0".*\n.*SN: ([^ ,]+)/.match(output)[1]
  end

  def get_host_name
    output = get(command:     'show running | i hostname',
                  data_format: :cli)
    return /^hostname (.*)$/.match(output)[1]
  end

  def get_domain_name
    output = get(command:     'show running-config all',
                  data_format: :cli)
    return /^domain name (\S+)$/.match(output)[1]
  end

  def get_system_uptime
    output = get(command:     'show version',
                  data_format: :cli)
    t = /.*System uptime is (?:(\d+) days)?,?\s?(?:(\d+) hours)?,?\s?(?:(\d+) minutes)?,?\s?(?:(\d+) seconds)?/.match(output).to_a
    fail 'failed to retrieve system uptime' if t.nil?
    t.shift
    # time units: t = ["0", "23", "15", "49"]
    t.map!(&:to_i)
    d, h, m, s = t
    (s + 60 * (m + 60 * (h + 24 * (d))))
  end

  # show_version.yaml last_reset_time excludes ios_xr. Not supported ?
  #def get_last_reset_time
  #end

  # show_version.yaml last_reset_reason excludes ios_xr. Not supported ?
  #def get_last_reset_reason
  #end

  # system.yaml resources excludes ios_xr. Not supported ?
  #def get_system_cpu_utilization
  #end

  # show_version.yaml boot_image excludes ios_xr. Not supported ?
  #def get_boot
  #end

  def get_system
    output = get(command:     'show version',
                  data_format: :cli)
    return /IOS XR.*Version (.*)$/.match(output)[1]
  end


end

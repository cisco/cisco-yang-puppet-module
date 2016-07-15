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

require_relative '../environment'
require_relative '../exceptions'
require_relative 'utils'
require_relative '../constants'
require_relative '../logger'

include Cisco::Logger

# Base class for clients of various RPC formats
class Cisco::Client
  @@clients = [] # rubocop:disable Style/ClassVars

  def self.clients
    @@clients
  end

  # Each subclass should call this method to register itself.
  def self.register_client(client)
    @@clients << client
  end

  attr_reader :platform, :host, :port, :address, :username, :password

  def initialize(platform:     nil,
                 **kwargs)
    if self.class == Cisco::Client
      fail NotImplementedError, 'Cisco::Client is an abstract class. ' \
        "Instantiate one of #{@@clients} or use Cisco::Client.create() instead"
    end
    self.class.validate_args(**kwargs)
    @host = kwargs[:host]
    @port = kwargs[:port]
    @address = @port.nil? ? @host : "#{@host}:#{@port}"
    @username = kwargs[:username]
    @password = kwargs[:password]
    self.platform = platform
  end

  def self.validate_args(**kwargs)
    host = kwargs[:host]
    unless host.nil?
      fail TypeError, 'invalid address' unless host.is_a?(String)
      fail ArgumentError, 'empty address' if host.empty?
    end
    username = kwargs[:username]
    unless username.nil?
      fail TypeError, 'invalid username' unless username.is_a?(String)
      fail ArgumentError, 'empty username' if username.empty?
    end
    password = kwargs[:password]
    unless password.nil?
      fail TypeError, 'invalid password' unless password.is_a?(String)
      fail ArgumentError, 'empty password' if password.empty?
    end
  end

  def self.environment_name(client_class)
    client_class.name.split('::').last.downcase
  end

  def self.environment(client_class)
    Cisco::Environment.environment(environment_name(client_class))
  end

  # Try to create an instance of the specified subclass
  def self.create(client_class)
    env = environment(client_class)
    env_name = environment_name(client_class)

    fail Cisco::ClientError, "No client environment configured for '#{env_name}'" unless env

    host = env[:host]
    port = env[:port]
    debug "Trying to connect to #{host}:#{port} as #{client_class}"
    errors = []
    begin
      client = client_class.new(**env)
      debug "#{client_class} connected successfully"
      return client
    rescue Cisco::ClientError, TypeError, ArgumentError => e
      debug "Unable to connect to #{host} as #{client_class}: #{e.message}"
      debug e.backtrace.join("\n  ")
      errors << e
    end
    handle_errors(errors)
  end

  def self.handle_errors(errors)
    # ClientError means we tried to connect but failed,
    # so it's 'more significant' than input validation errors.
    client_errors = errors.select { |e| e.kind_of? Cisco::ClientError }
    if !client_errors.empty?
      # Reraise the specific error if just one
      fail client_errors[0] if client_errors.length == 1
      # Otherwise clump them together into a new error
      e_cls = client_errors[0].class
      unless client_errors.all? { |e| e.class == e_cls }
        e_cls = Cisco::ClientError
      end
      fail e_cls, ("Unable to establish any client connection:\n" +
                   errors.each(&:message).join("\n"))
    elsif errors.any? { |e| e.kind_of? ArgumentError }
      fail ArgumentError, ("Invalid arguments:\n" +
                           errors.each(&:message).join("\n"))
    elsif errors.any? { |e| e.kind_of? TypeError }
      fail TypeError, ("Invalid arguments:\n" +
                       errors.each(&:message).join("\n"))
    end
    fail Cisco::ClientError, 'No client connected, but no errors were reported?'
  end

  def to_s
    @address.to_s
  end

  def inspect
    "<#{self.class} of #{@address}>"
  end

  # Configure the given state on the device.
  #
  # @param values [String, Array<String>] Actual configuration to set
  # @param kwargs data-format-specific args
  def set(values:      nil,
          **_kwargs)
    # subclasses will generally want to call Client.munge_to_array()
    # on values before calling super()
    Cisco::Logger.debug("values: #{values})") \
      unless values.nil? || values.empty?
    # to be implemented by subclasses
  end

  # Get the given state from the device.
  #
  # @param command [String] the get command to execute
  # @param value [String, Regexp] Specific key or regexp to look up
  # @param kwargs data-format-specific args
  # @return [String, Hash, nil] The state found, or nil if not found.
  def get(command:     nil,
          value:       nil,
          **_kwargs)
    # subclasses will generally want to call Client.munge_to_array()
    # on value before calling super()
    Cisco::Logger.debug("  executing command:\n    #{command}") \
      unless command.nil? || command.empty?
    Cisco::Logger.debug("  to get value:     #{value}") \
      unless value.nil?
    # to be implemented by subclasses
  end

  private

 # Set the platform of the node managed by this client.
  def platform=(platform)
    fail ArgumentError, "unknown platform #{platform}" \
      unless Cisco::PLATFORMS.include?(platform)
    @platform = platform
  end
end

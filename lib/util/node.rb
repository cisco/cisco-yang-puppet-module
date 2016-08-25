# Cisco node helper class. Abstracts away the details of the underlying
# transport (grpc/netconf) and provides various convenience methods.

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

require_relative 'client'
require_relative 'client/client'
require_relative 'exceptions'
require_relative 'logger'

# Add node management classes and APIs to the Cisco namespace.
module Cisco
  # class Cisco::Node
  # Pseudo-singleton representing the network node (switch/router) that is
  # running this code. The singleton is lazily instantiated, meaning that
  # it doesn't exist until some client requests it (with Node.instance(...))
  class Node
    @instance_hash = {}
    @instance = nil

    # Here and below are implementation details and private APIs that most
    # providers shouldn't need to know about or use.

    attr_reader :client

    # Return a node instance that wraps a client of the specified class.
    def self.instance(client_class=nil)
      return @instance_hash[client_class] ||= new(client_class) unless client_class.nil?

      # just return one of the cached instances
      return @instance_hash[hash.keys[0]] unless @instance_hash.empty?

      # no nodes currently cached, so create one
      debug 'Attempting to create a client (type not specified)...'
      env_names = Cisco::Util::Environment.environment_names

      Cisco::Client.clients.each do |c|
        client_env_name = Cisco::Client.environment_name(c)
        if env_names.include?(client_env_name)
          debug "Environment configuration found for client #{c}"
          return instance(c)
        end
      end

      error 'No clients configured'
    end

    def self.instance_exists(client_class)
      !@instance_hash[client_class].nil?
    end

    def initialize(client_class)
      @client = Cisco::Client.create(client_class)
    end

    def to_s
      client.to_s
    end

    def inspect
      "Node: client:'#{client.inspect}'"
    end

    # Send a config command to the device.
    # @raise [Cisco::RequestFailed] if any command is rejected by the device.
    def set(**kwargs)
      @client.set(**kwargs)
    end

    # Send a show command to the device.
    # @raise [Cisco::RequestFailed] if any command is rejected by the device.
    def get(**kwargs)
      @client.get(**kwargs)
    end

    # Merge the specified config with the running config on the device.
    # using netconf
    def merge_netconf(config)
      @client.set(values: config, mode: :merge)
    end

    # Replace the running config on the device with the specified
    # config using netconf client.
    def replace_netconf(config)
      @client.set(values: config, mode: :replace)
    end

    # Retrieve config from the device for the specified path using netconf.
    def get_netconf(xpath)
      @client.get(command: xpath)
    end

    # Merge the specified JSON YANG config with the running config on
    # the device.
    def merge_yang(yang)
      @client.set(values: yang, mode: :merge_config)
    end

    # Replace the running config on the device with the specified
    # JSON YANG config.
    def replace_yang(yang)
      @client.set(values: yang,
                  mode:   :replace_config)
    end

    # Delete the specified JSON YANG config from the device.
    def delete_yang(yang)
      @client.set(values: yang, mode: :delete_config)
    end

    # Retrieve JSON YANG config from the device for the specified path.
    def get_yang(yang_path)
      @client.get(command: yang_path)
    end

    # Retrieve JSON YANG operational data for the specified path.
    def get_yang_oper(yang_path)
      @client.get(command: yang_path, mode: :get_oper)
    end

    # @return [String] such as "Cisco Nexus Operating System (NX-OS) Software"
    def os
      @client.os
    end

    # @return [String] such as "6.0(2)U5(1) [build 6.0(2)U5(0.941)]"
    def os_version
      @client.os_version
    end

    # @return [String] such as "Nexus 3048 Chassis"
    def product_description
      @client.product_description
    end

    # @return [String] such as "N3K-C3048TP-1GE"
    def product_id
      @client.product_id
    end

    # @return [String] such as "V01"
    def product_version_id
      @client.product_version_id
    end

    # @return [String] such as "FOC1722R0ET"
    def product_serial_number
      @client.product_serial_number
    end

    # @return [String] such as "bxb-oa-n3k-7"
    def host_name
      @client.host_name
    end

    # @return [String] such as "example.com"
    def domain_name
      @client.domain_name
    end

    # @return [Integer] System uptime, in seconds
    def system_uptime
      @client.system_uptime
    end

    # @return [String] timestamp of last reset time
    def last_reset_time
      @client.get_last_reset_time
    end

    # @return [String] such as "Reset Requested by CLI command reload"
    def last_reset_reason
      @client.get_last_reset_reason
    end

    # @return [Float] combined user/kernel CPU utilization
    def system_cpu_utilization
      @client.system_cpu_utilization
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9-kickstart.6.0.2.U5.0.941.bin"
    def boot
      @client.get_boot
    end

    # @return [String] such as
    #   "bootflash:///n3000-uk9.6.0.2.U5.0.941.bin"
    def system
      @client.system
    end
  end
end

# Copyright (c) 2013-2016 Cisco and/or its affiliates.
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

# Minitest needs to have this path in order to discover our plugins
$LOAD_PATH.push File.expand_path('../../../lib', __FILE__)

require 'ipaddr'
require 'resolv'
require_relative 'platform_info'
gem 'minitest', '~> 5.0'
require 'minitest/autorun'
require 'net/telnet'
require_relative '../../lib/util/client'
require_relative '../../lib/util/client/grpc/client'
require_relative '../../lib/util/node'
require_relative '../../lib/util/environment'
require_relative '../../lib/util/logger'

include Cisco

# CiscoTestCase - base class for all node utility minitests
class CiscoTestCase < Minitest::Test
  # rubocop:disable Style/ClassVars
  @@node = nil
  @@device_hash = {}
  # rubocop:enable Style/ClassVars

  @my_node = nil
  @my_device = nil

  # The feature (lib/cisco_node_utils/cmd_ref/<feature>.yaml) that this
  # test case is associated with, if applicable.
  # If the YAML file excludes this entire feature for this platform
  # (top-level _exclude statement, not individual attributes), then
  # all tests in this test case will be skipped.
  @skip_unless_supported = nil

  class << self
    attr_accessor :skip_unless_supported
  end

  def self.runnable_methods
    return super if skip_unless_supported.nil?
    #    return super if node.cmd_ref.supports?(skip_unless_supported)
    # If the entire feature under test is unsupported,
    # undefine the setup/teardown methods (if any) and skip the whole test case
    remove_method :setup if instance_methods(false).include?(:setup)
    remove_method :teardown if instance_methods(false).include?(:teardown)
    [:all_skipped]
  end

  def all_skipped
    skip("Skipping #{self.class}; feature " \
         "'#{self.class.skip_unless_supported}' is unsupported on this node")
  end

  def client_class
    # to be implemented by subclasses

    # for now, default to the GRPC client
    Cisco::Client::GRPC
  end

  def node
    return nil unless client_class

    is_new = !Node.instance_exists(client_class)

    # rubocop:disable Style/ClassVars
    @my_node = Node.instance(client_class)
    # rubocop:enable Style/ClassVars

    if is_new
      @my_node.cache_enable = true
      @my_node.cache_auto = true
      # Record the platform we're running on
      puts "\nNode under test:"
      puts "  - name  - #{@my_node.host_name}"
      puts "  - type  - #{@my_node.product_id}"
      puts "  - image - #{@my_node.system}\n\n"
    end

    @my_node
  rescue Cisco::AuthenticationFailed
    abort "Unauthorized to connect as #{username}:#{password}@#{address}"
  rescue Cisco::ClientError, TypeError, ArgumentError => e
    abort "Error in establishing connection: #{e}"
  end

  def client
    node.client
  end

  def environment
    Cisco::Client.environment(client.class)
  end

  def device
    @@device_hash[node.client.class] ||= create_device
  end

  def create_device
    login = proc do
      puts "====> ciscotest.create_device - login address: #{node.client.host}, username: #{node.client.username}, object_id: #{object_id}"
      d = Net::Telnet.new('Host'    => node.client.host,
                          'Timeout' => 240,
                          # NX-OS has a space after '#', IOS XR does not
                          'Prompt'  => /[$%#>] *\z/n,
                         )
      d.login('Name'        => node.client.username,
              'Password'    => node.client.password,
              # NX-OS uses 'login:' while IOS XR uses 'Username:'
              'LoginPrompt' => /(?:[Ll]ogin|[Uu]sername)[: ]*\z/n,
             )
      d
    end

    begin
      new_device = login.call
    rescue Errno::ECONNRESET
      new_device.close
      puts 'Connection reset by peer? Try again'
      sleep 1

      new_device = login.call
    end
    new_device.cmd('term len 0')
    new_device
  rescue Errno::ECONNREFUSED
    puts 'Telnet login refused - please check that the IP address is correct'
    puts "  and that you have configured 'telnet ipv4 server...' on the UUT"
    exit
  end

  def teardown
    #    @my_device.close unless @my_device.nil?
    #    @my_device = nil
  end

  def cmd_ref
    node.cmd_ref
  end

  def platform
    node.client.platform
  end

  def config_and_warn_on_match(warn_match, *args)
    if node.client.platform == :ios_xr
      result = super(warn_match, *args, 'commit')
    else
      result = super
    end
    node.cache_flush
    result
  end
end

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
  @@device_hash = {}
  # rubocop:enable Style/ClassVars

  @node = nil

  @client_class = nil

  class << self
    attr_accessor :client_class
  end

  def client_class
    self.class.client_class
  end

  def self.runnable_methods
    return [] if self.class == CiscoTestCase
    cc = client_class
    return super unless cc
    env = cc ? cc.environment(cc) : nil
    return super if env

    # no environment configured for this test suite, so skip all tests
    remove_method :setup if instance_methods(false).include?(:setup)
    remove_method :teardown if instance_methods(false).include?(:teardown)
    [:all_skipped]
  end

  def all_skipped
    skip("Skipping #{self.class}; #{client_class} is not configured/supported on this node")
  end

  def node
    cc = client_class
    assert(cc, 'No client_class defined')

    return nil unless cc

    is_new = !Node.instance_exists(cc)
    @node = Node.instance(cc)

    if is_new
      @node.cache_enable = true
      @node.cache_auto = true
      # Record the platform we're running on
      puts "\nNode under test:"
      puts "  - name  - #{@node.host_name}"
      puts "  - type  - #{@node.product_id}"
      puts "  - image - #{@node.system}\n\n"
    end

    @node
  rescue Cisco::AuthenticationFailed
    abort "Unauthorized to connect as #{username}:#{password}@#{address}"
  rescue Cisco::ClientError, TypeError, ArgumentError => e
    abort "Error in establishing connection: #{e}"
  end

  def client
    node ? node.client : nil
  end

  def environment(default=nil)
    Cisco::Client.environment(client.class) || default
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

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

require 'ipaddr'
require 'resolv'
require_relative 'basetest'
require_relative 'platform_info'
require_relative '../../lib/util/node'

include Cisco

# CiscoTestCase - base class for all node utility minitests
class CiscoTestCase < TestCase
  # rubocop:disable Style/ClassVars
  @@node = nil
  # rubocop:enable Style/ClassVars

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
    return super if node.cmd_ref.supports?(skip_unless_supported)
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

  def self.node
    unless @@node
      # rubocop:disable Style/ClassVars
      @@node = Node.instance
      # rubocop:enable Style/ClassVars
      @@node.cache_enable = true
      @@node.cache_auto = true
      # Record the platform we're running on
      puts "\nNode under test:"
      puts "  - name  - #{@@node.host_name}"
      puts "  - type  - #{@@node.product_id}"
      puts "  - image - #{@@node.system}\n\n"
    end
    @@node
  rescue Cisco::AuthenticationFailed
    abort "Unauthorized to connect as #{username}:#{password}@#{address}"
  rescue Cisco::ClientError, TypeError, ArgumentError => e
    abort "Error in establishing connection: #{e}"
  end

  def node
    self.class.node
  end

  def setup
    super
    node
  end

  def cmd_ref
    node.cmd_ref
  end

  def self.platform
    node.client.platform
  end

  def platform
    self.class.platform
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

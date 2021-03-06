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

require 'rexml/document'
require_relative '../client'
require_relative 'netconf_client'

include Cisco::Logger

# Client implementation using Netconf API for IOS XR
class Cisco::Client::NETCONF < Cisco::Client
  register_client(self)

  attr_accessor :timeout

  def initialize(**kwargs)
    super(:data_formats => [:xml],
          :platform => :ios_xr,
          **kwargs)

    @login = { target:   kwargs[:host],
               username: kwargs[:username],
               password: kwargs[:password] }

    @netconf_client = Netconf::NetconfClient.new(@login)
    begin
      @netconf_client.connect
    rescue => e
      puts "Attempted to connect and got class:#{e.class}/error:#{e}"
      raise_cisco(e)
    end
  end

  def raise_cisco(e)
    # Net::SSH::Disconnect
    # Net::SSH::AuthenticationFailed
    # Errno::EHOSTUNREACH
    # Errno::ECONNREFUSED

    fail e
  rescue Net::SSH::AuthenticationFailed => e
    raise Cisco::AuthenticationFailed, \
          'Netconf client creation failure: ' + e.message
  rescue Net::SSH::Disconnect
    raise Cisco::YangError.new(error: e.message) # rubocop:disable Style/RaiseArgs
  rescue Errno::EHOSTUNREACH
    raise Cisco::YangError.new(error: e.message) # rubocop:disable Style/RaiseArgs
  rescue Errno::ECONNREFUSED
    raise Cisco::YangError.new(error: e.message) # rubocop:disable Style/RaiseArgs
  rescue Errno::ECONNRESET
    raise Cisco::YangError.new(error: e.message) # rubocop:disable Style/RaiseArgs
  end

  def self.validate_args(**kwargs)
    super
    base_msg = 'Netconf client creation failure: '
    # Connection to remote system - username and password are required
    fail TypeError, base_msg + 'username must be specified' \
      if kwargs[:username].nil?
    fail TypeError, base_msg + 'password must be specified' \
      if kwargs[:password].nil?
  end

  def set(values: nil,
          **kwargs)
    return if values.nil? || values.empty?
    begin
      mode = kwargs[:mode] || :merge
      fail ArgumentError unless Cisco::Util::NETCONF_SET_MODE.include? mode
      reply = @netconf_client.edit_config('candidate', mode.to_s, values)
      if reply.errors?
        fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
          rejected_input: "apply of #{values}",
          error:          reply.errors_as_string)
      end
      reply = @netconf_client.commit_changes
      if reply.errors?
        fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
          rejected_input: "commit of #{values}",
          error:          reply.errors_as_string)
      end
    rescue => e
      raise_cisco(e)
    end
  end

  def get(command: nil,
          **kwargs)
    begin
      doc = REXML::Document.new(command)
    rescue => e
      raise Cisco::YangError.new(rejected_input: command, # rubocop:disable Style/RaiseArgs
                                 error:          e.message)
    end

    return nil if doc.root.nil?

    begin
      mode = kwargs[:mode] || :get_config

      if mode == :get_oper
        reply = @netconf_client.get_oper(command)
      else
        reply = @netconf_client.get_config(command)
      end

      if reply.errors?
        fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
          rejected_input: command,
          error:          reply.errors_as_string)
      else
        reply.data_as_string
      end

    rescue => e
      raise_cisco(e)
    end
  end

  def wants_cmd_ref
    false
  end

  def inventory
    unless defined? @inventory
      filter = '<inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-invmgr-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @inventory = reply.response unless reply.errors?
    end
    @inventory
  end

  def chas_inventory
    unless defined? @chas_inventory
      filter = '<platform-inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-plat-chas-invmgr-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @chas_inventory = reply.response unless reply.errors?
    end
    @chas_inventory
  end

  def ip_domain
    unless defined? @ip_domain
      filter = '<ip-domain xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-ip-domain-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @ip_domain = reply.response unless reply.errors?
    end
    @ip_domain
  end

  def system_time
    unless defined? @system_time
      filter = '<system-time xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-shellutil-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @system_time = reply.response unless reply.errors?
    end
    @system_time
  end

  def software_install
    unless defined? @software_install
      filter = '<software-install xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-spirit-install-instmgr-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @software_install = reply.response unless reply.errors?
    end
    @software_install
  end

  def diag
    unless defined? @diag
      filter = '<diag xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-sdr-invmgr-diag-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @diag = reply.response unless reply.errors?
    end
    @diag
  end

  def redundancy
    unless defined? @redundancy
      filter = '<redundancy xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rmf-oper"/>'
      reply = @netconf_client.get_oper(filter)
      @redundancy = reply.response unless reply.errors?
    end
    @redundancy
  end

  def software_revision
    return '' unless inventory
    sr = ''
    inventory.elements.each('rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/software-revision') do |e|
      sr = e.text
    end
    sr
  end

  def os
    return '' unless software_install
    os = ''
    software_install.elements.each('rpc-reply/data/software-install/version/log') do |e|
      os = /Cisco.*Software/.match(e.text).to_s
    end
    os
  end

  def os_version
    return '' unless inventory
    sr = ''
    inventory.elements.each('rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/software-revision') do |e|
      sr = e.text
    end
    sr
  end

  def product_description
    return '' unless diag
    product_description = ''
    diag.elements.each('rpc-reply/data/diag/racks/rack/chassis/udi-description') do |e|
      product_description = e.text
    end
    product_description
  end

  def product_id
    return '' unless diag
    product_id = ''
    diag.elements.each('rpc-reply/data/diag/racks/rack/chassis/pid') do |e|
      product_id = e.text
    end
    product_id
  end

  def product_version_id
    return '' unless inventory
    vid = ''
    inventory.elements.each('rpc-reply/data/inventory/racks/rack/entity/slot/tsi1s/tsi1/attributes/inv-eeprom-info/eeprom/vid') do |e|
      vid = e.text
    end
    vid
  end

  def product_serial_number
    return '' unless chas_inventory
    product_id = ''
    chas_inventory.elements.each('rpc-reply/data/platform-inventory/racks/rack/attributes/basic-info/serial-number') do |e|
      product_id = e.text
    end
    product_id
  end

  def host_name
    return '' unless system_time
    host_name = ''
    system_time.elements.each('rpc-reply/data/system-time/uptime/host-name') do |e|
      host_name = e.text
    end
    host_name
  end

  def domain_name
    return '' unless ip_domain
    domain_name = ''
    ip_domain.elements.each('rpc-reply/data/ip-domain/vrfs/vrf/server/domain-name') do |e|
      domain_name = e.text
    end
    domain_name
  end

  def system_uptime
    return '' unless software_install
    uptime = ''
    software_install.elements.each('rpc-reply/data/software-install/version/log') do |e|
      output = /Cisco.*Software/.match(e.text).to_s
      t = /.*System uptime is (?:(\d+) day)?s?,?\s?(?:(\d+) hour)?s?,?\s?(?:(\d+) minute)?s?,?\s?(?:(\d+) second)?s?/.match(output).to_a
      fail 'failed to retrieve system uptime' if t.nil?
      t.shift
      # time units: t = ["0", "23", "15", "49"]
      t.map!(&:to_i)
      d, h, m, s = t
      uptime = (s + 60 * (m + 60 * (h + 24 * (d))))
    end
    uptime
  end

  def last_reset_time
    return '' unless redundancy
    last_reset_time = ''
    redundancy.elements.each('rpc-reply/data/redundancy/nodes/node/log') do |e|
      output = e.text
      t = /^Active.*:\s*(?:(\d+) day)?s?,?\s?(?:(\d+) hour)?s?,?\s?(?:(\d+) minute)?s?,?\s?(?:(\d+) second)?s?,?\s?/.match(output).to_a
      fail 'failed to retrieve system uptime' if t.nil?
      t.shift
      # time units: t = ["0", "23", "15", "49"]
      t.map!(&:to_i)
      d, h, m, s = t
      last_reset_time = (s + 60 * (m + 60 * (h + 24 * (d))))
    end
    last_reset_time
  end

  def last_reset_reason
    return '' unless redundancy
    reason = ''
    redundancy.elements.each('rpc-reply/data/redundancy/nodes/node/active-reboot-reason') do |e|
      reason = e.text
    end
    reason
  end

  def system_cpu_utilization
    'foo'
    # <system-monitoring xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-wdsysmon-fd-oper"/>
    # rpc-reply/data/system-monitoring/cpu-utilization/total-cpu-fifteen-minute
  end

  def boot
    return '' unless software_install
    boot_image = ''
    software_install.elements.each('rpc-reply/data/software-install/committed/committed-package-info/committed-packages') do |e|
      boot_image = /^\s*(.*)version=.*\[Boot image\]$/.match(e.text)[1]
    end
    boot_image
  end

  def system
    return '' unless inventory
    sr = ''
    inventory.elements.each('rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/software-revision') do |e|
      sr = e.text
    end
    sr
  end

  def yang_target(_module_name, namespace, container)
    "<#{container} xmlns=\"#{namespace}\" />"
  end
end

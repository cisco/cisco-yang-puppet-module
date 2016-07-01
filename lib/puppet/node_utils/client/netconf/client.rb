#!/usr/bin/env ruby
#
# June 2016, Sushrut Shirole
#
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
    super(data_formats: [:xml],
          platform:     :ios_xr,
          **kwargs)

    @login = { :target => kwargs[:host],
      :username => kwargs[:username],
      :password => kwargs[:password]}

    @client = Netconf::Client.new(@login)
    begin
      @client.connect
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
    begin
      raise e
    rescue Net::SSH::AuthenticationFailed => e
      raise Cisco::AuthenticationFailed, \
        'Netconf client creation failure: ' + e.message
    rescue Net::SSH::Disconnect
      fail Cisco::YangError.new( error: e.message)
    rescue Errno::EHOSTUNREACH
      fail Cisco::YangError.new( error: e.message)
    rescue Errno::ECONNREFUSED
      fail Cisco::YangError.new( error: e.message)
    rescue Errno::ECONNRESET
      fail Cisco::YangError.new( error: e.message)
    end
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

  def set(data_format: :xml,
          context:     nil,
          values:      nil,
          **kwargs)
    if values.nil? || values.empty?
      return
    end
    begin
      mode = kwargs[:mode] || :merge
      fail ArgumentError unless Cisco::NETCONF_SET_MODE.include? mode
      reply = @client.edit_config("candidate", mode.to_s, values)
      if reply.errors?
        fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
                                 rejected_input: "apply of #{values}",
                                 error:       reply.errors_as_string)
      end
      reply = @client.commit_changes()
      if reply.errors?
        fail Cisco::YangError.new( # rubocop:disable Style/RaiseArgs
                                 rejected_input: "commit of #{values}",
                                 error:       reply.errors_as_string)
      end
    rescue => e
      raise_cisco(e)
    end
  end

  def get(data_format: :cli,
          command:     nil,
          context:     nil,
          value:       nil)
    begin
      doc = REXML::Document.new(command)
    rescue => e
      fail Cisco::YangError.new(rejected_input: command,
                                error: e.message)
    end

    if doc.root == nil
      return nil
    end

    begin
      reply = @client.get_config(command)

      if reply.errors?
        fail Cisco::YangError.new(# rubocop:disable Style/RaiseArgs
                                  rejected_input: command,
                                  error: reply.errors_as_string)
      else
        reply.config_as_string
      end
    rescue => e
      raise_cisco(e)
    end
  end

  def wants_cmd_ref
    false
  end

  def inventory
    if !@inventory
      filter = '<inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-invmgr-oper"/>'
      reply = @client.get(filter)
      if !reply.errors?
        @inventory = reply.response
      end
    end
    @inventory
  end

  def chas_inventory
    if !@chas_inventory
      filter = '<platform-inventory xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-plat-chas-invmgr-oper"/>'
      reply = @client.get(filter)
      if !reply.errors?
        @chas_inventory = reply.response
      end
    end
    @chas_inventory
  end

  def get_domain_name
    "foo"
    #later
  end

  def get_host_name
    filter = '<host-name xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-shellutil-cfg"/>'
    reply = @client.get_config(filter)
    if reply.errors?
      ""
    else
      name = ""
      reply.response.elements.each("rpc-reply/data/host-name") do |e|
        name = e.text
      end
      name
    end
  end

  def get_system
    "foo"
    #later
  end

  def get_product_serial_number
    return "" if !chas_inventory
    product_id = ""
    chas_inventory.elements.each("rpc-reply/data/platform-inventory/racks/rack/attributes/basic-info/serial-number") do |e|
      product_id = e.text
    end
    product_id
  end

  def get_product_id
    return "" if !inventory
    product_id = ""
    inventory.elements.each("rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/model-name") do |e|
      product_id = e.text
    end
    product_id
  end

  def get_software_revision
    return "" if !inventory
    software_revision = ""
    inventory.elements.each("rpc-reply/data/inventory/racks/rack/attributes/inv-basic-bag/software-revision") do |e|
      software_revision = e.text
    end
    software_revision
  end

end

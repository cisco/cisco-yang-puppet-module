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

require_relative 'ciscotest'

# Test case for Cisco::Client::NETCONF::Client class
class TestNetconf < CiscoTestCase
  def client_class
    Cisco::Client::NETCONF
  end

  RED_VRF = \
    "<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">\n  <vrf>\n    <vrf-name>\n      red\n    </vrf-name>\n    <create/>\n  </vrf>\n</vrfs>"
  BLUE_VRF = \
      "<vrfs xmlns=\"http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg\">\n  <vrf>\n    <vrf-name>\n      blue\n    </vrf-name>\n    <create/>\n  </vrf>\n</vrfs>"
  ROOT_VRF = '<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'
  INVALID_VRF = '<infra-rsi-cfg:vrfs-invalid xmlns:infra-rsi-cfg-invalid="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg-invalid"/>'

  def self.runnable_methods
    # TODO: Skip all tests if the netconf client did not load
    # return [:all_skipped] unless environment[:port] == 830
    super
  end

  def all_skipped
    skip 'No Netconf client was loaded.'
  end

  def test_auth_failure
    env = environment.merge(password: 'wrong password')
    e = assert_raises Cisco::AuthenticationFailed do
      Cisco::Client::NETCONF.new(**env)
    end
    assert_equal('Netconf client creation failure: Authentication failed for user ' \
      + environment[:username] + '@' + environment[:host], e.message)
  end

  def test_connection_failure
    # Failure #1: connecting to a host that's listening for a non-Netconf protocol
    env = environment.merge(host: '1.1.1.1')
    e = assert_raises Cisco::YangError do
      Cisco::Client::NETCONF.new(**env)
    end
    assert_match('No route to host - connect(2)',
                 e.message)
  end

  def test_set_string
    client.set(context: nil,
               values:  RED_VRF,
               mode:    :replace)
    run = client.get(command: ROOT_VRF)
    assert_match(RED_VRF, run)
  end

  def test_set_invalid
    e = assert_raises Cisco::YangError do
      client.set(context: nil,
                 values:  INVALID_VRF)
    end
    assert_equal('The config \'apply of <infra-rsi-cfg:vrfs-invalid ' \
      'xmlns:infra-rsi-cfg-invalid="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg-invalid"/>\' was rejected with error:
error-type => rpc
error-tag => malformed-message
error-severity => error
', e.message)
    ## rubocop:enable Style/TrailingWhitespace
    ## Unlike NXAPI, a Netconf config command is always atomic
    assert_empty(e.successful_input)
    assert_equal('apply of <infra-rsi-cfg:vrfs-invalid xmlns:infra-rsi-cfg-invalid="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg-invalid"/>', e.rejected_input)
  end

  def test_get_invalid
    assert_raises Cisco::YangError do
      client.get(command: INVALID_VRF)
    end
  end

  def test_get_incomplete
    assert_raises Cisco::YangError do
      client.get(command: INVALID_VRF)
    end
  end

  def test_get_empty
    result = client.get(command: BLUE_VRF)
    assert_empty(result)
  end

  def test_supports
    assert(client.supports?(:xml))
    refute(client.supports?(:cli))
    refute(client.supports?(:yang_json))
  end
end

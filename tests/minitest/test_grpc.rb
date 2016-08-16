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

require_relative 'ciscotest'

# Test case for Cisco::Client::GRPC::Client class
class TestGRPC < CiscoTestCase
  @client_class = Cisco::Client::GRPC
  RED_VRF = \
  "{\n \"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": {\n  \"vrf\": [\n   {\n    \"vrf-name\": \"RED\",\n    \"create\": [\n     null\n    ]\n   }\n  ]\n }\n}\n"
  FOO_VRF = \
  "{\n \"Cisco-IOS-XR-infra-rsi-cfg:vrfs\": {\n  \"vrf\": "\
  "[\n   {\n    \"vrf-name\": \"foo-should-not-be-there\",\n    \"create\": [\n     null\n    ]\n   }\n  ]\n }\n}\n"
  ROOT_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}'
  INVALID_VRF = '{"Cisco-IOS-XR-infra-rsi-cfg:invalid": [null]}'

  def test_auth_failure
    env = environment.merge(password: 'wrong password')
    # Cisco::Client::GRPC.new(**env)
    e = assert_raises Cisco::AuthenticationFailed do
      Cisco::Client::GRPC.new(**env)
    end
    assert_equal('gRPC client creation failure: Failed authentication',
                 e.message)
  end

  def test_connection_failure
    # Failure #1: connecting to a port that's listening for a non-gRPC protocol
    env = environment.merge(port: '57722') # sshd
    e = assert_raises Cisco::ConnectionRefused do
      Cisco::Client::GRPC.new(**env)
    end
    assert_equal('gRPC client creation failure: Connection refused: ',
                 e.message)
    # Failure #2: Connecting to a port that's not listening at all
    env = environment.merge(port: '0')
    e = assert_raises Cisco::ConnectionRefused do
      Cisco::Client::GRPC.new(**env)
    end
    assert_equal('gRPC client creation failure: ' \
                 'timed out during initial connection: Deadline Exceeded',
                 e.message)
  end

  def test_set_string
    client.set(values: RED_VRF,
               mode:   :replace_config)
    run = client.get(command: ROOT_VRF)
    assert_match(RED_VRF, run)
  end

  def test_set_invalid
    e = assert_raises Cisco::YangError do
      client.set(values: INVALID_VRF)
    end
    assert_equal("The config '{\"Cisco-IOS-XR-infra-rsi-cfg:invalid\": [null]}' was rejected with error:
unknown-element: Cisco-IOS-XR-infra-rsi-cfg:ns1:invalid", e.message)
    assert_empty(e.successful_input)
    assert_equal(INVALID_VRF,
                 e.rejected_input)
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
    result = client.get(command: FOO_VRF)
    assert_empty(result)
  end
end

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
    env = environment.merge(port: 23)
    e = assert_raises Cisco::ConnectionRefused do
      Cisco::Client::GRPC.new(**env)
    end
    assert_equal('gRPC client creation failure: Connection refused: ',
                 e.message)
    # Failure #2: Connecting to a port that's not listening at all
    env = environment.merge(port: 0)
    e = assert_raises Cisco::ConnectionRefused do
      Cisco::Client::GRPC.new(**env)
    end
    assert_equal('gRPC client creation failure: ' \
                 'timed out during initial connection: Deadline Exceeded',
                 e.message)
  end

  def test_set_cli_string
    client.set(context: 'int gi0/0/0/0',
               values:  'description panda')
    run = client.get(command: 'show run int gi0/0/0/0')
    assert_match(/description panda/, run)
  end

  def test_set_cli_array
    client.set(context: ['int gi0/0/0/0'],
               values:  ['description elephant'])
    run = client.get(command: 'show run int gi0/0/0/0')
    assert_match(/description elephant/, run)
  end

  def test_set_cli_invalid
    e = assert_raises Cisco::CliError do
      client.set(context: ['int gi0/0/0/0'],
                 values:  ['wark', 'bark bark'])
    end
    assert_equal('The following commands were rejected:
  int gi0/0/0/0 wark
  int gi0/0/0/0 bark bark
with error:
!! SYNTAX/AUTHORIZATION ERRORS: This configuration failed due to
!! one or more of the following reasons:
!!  - the entered commands do not exist,
!!  - the entered commands have errors in their syntax,
!!  - the software packages containing the commands are not active,
!!  - the current user is not a member of a task-group that has
!!    permissions to use the commands.
int gi0/0/0/0 wark
int gi0/0/0/0 bark bark
', e.message.gsub(/\s+\n+/, "\n"))
    # rubocop:enable Style/TrailingWhitespace
    # Unlike NXAPI, a gRPC config command is always atomic
    assert_empty(e.successful_input)
    assert_equal(['int gi0/0/0/0 wark', 'int gi0/0/0/0 bark bark'],
                 e.rejected_input)
  end

  def test_get_cli_default
    result = client.get(command: 'show debug')
    s = device.cmd('show debug')
    # Strip the leading timestamp and trailing prompt from the telnet output
    s = s.split("\n")[2..-2].join("\n")
    assert_equal(s, result)
  end

  def test_get_cli_invalid
    assert_raises Cisco::CliError do
      client.get(command: 'show fuzz')
    end
  end

  def test_get_cli_incomplete
    assert_raises Cisco::CliError do
      client.get(command: 'show ')
    end
  end

  def test_get_cli_explicit
    result = client.get(command: 'show debug', data_format: :cli)
    s = device.cmd('show debug')
    # Strip the leading timestamp and trailing prompt from the telnet output
    s = s.split("\n")[2..-2].join("\n")
    assert_equal(s, result)
  end

  def test_get_cli_empty
    result = client.get(command:     'show debug | include foo | exclude foo',
                        data_format: :cli)
    assert_nil(result)
  end

  def test_supports
    assert(client.supports?(:cli))
    assert(client.supports?(:yang_json))
    refute(client.supports?(:xml))
  end
end

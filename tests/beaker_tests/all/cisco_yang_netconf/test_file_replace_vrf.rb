###############################################################################
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
###############################################################################
require File.expand_path('../../../lib/utilitylib.rb', __FILE__)
require File.expand_path('../../../lib/yang_netconf_util.rb', __FILE__)

# Test hash top-level keys
tests = {
  master:        master,
  agent:         agent,
  ensurable:     false,
  resource_name: 'cisco_yang_netconf',
}
tests[:replace_merge] = NETCONF_FILE_REPLACE

skip_unless_supported(tests)

step 'Setup' do
  clear_vrf
  on(agent, puppet_resource('file', '/root/temp/', 'ensure=directory'))
  on(agent, puppet_resource('file', \
                            '/root/temp/vrfs.xml', \
                            'source="puppet:///modules/ciscoyang/models/defaults/vrfs.xml"', \
                            'ensure=present'))
end

teardown do
  clear_vrf
  on(agent, puppet_resource('file', \
                            '/root/temp/vrfs.xml', \
                            'ensure=absent'))
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name 'TestCase :: read config from vrfs.xml file and replace current config with it' do
  id = :replace_merge
  test_harness_run(tests, id)
  skipped_tests_summary(tests)
end

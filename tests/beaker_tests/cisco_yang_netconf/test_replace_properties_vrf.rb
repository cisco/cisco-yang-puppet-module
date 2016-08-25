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
require File.expand_path('../../lib/utilitylib.rb', __FILE__)
require File.expand_path('../util.rb', __FILE__)

# Test hash top-level keys
tests = {
  master:        master,
  agent:         agent,
  ensurable:     false,
  resource_name: 'cisco_yang_netconf',
}
tests[:replace12] = NETCONF_REPLACE12

skip_unless_supported(tests)

step 'Setup' do
  clear_vrf
  title_string = NETCONF_BLUE_VRF_WO_PROPERTY
  cmd = PUPPET_BINPATH + "resource cisco_yang_netconf '#{title_string}' mode=merge"
  on(agent, cmd)
end

teardown do
  clear_vrf
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name 'TestCase :: VRF Present' do
  id = :replace12
  test_harness_run(tests, id)
  skipped_tests_summary(tests)
end

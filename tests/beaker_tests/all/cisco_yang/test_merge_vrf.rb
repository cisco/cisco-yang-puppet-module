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
require File.expand_path('../../../lib/yang_util.rb', __FILE__)

# Test hash top-level keys
tests = {
  master:        master,
  agent:         agent,
  resource_name: 'cisco_yang',
}
tests[:merge] = MERGE

skip_unless_supported(tests)

step 'Setup' do
  resource_absent_by_title(agent, 'cisco_yang', ROOT_VRF)
  resource = {
    name:     'cisco_yang',
    title:    GREEN_VRF_WO_PROPERTY,
    property: 'ensure',
    value:    'present',
  }
  resource_set(agent, resource, 'Create a VRF GREEN.')
end

teardown do
  resource_absent_by_title(agent, 'cisco_yang', ROOT_VRF)
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name 'TestCase :: Merge VRF BLUE' do
  id = :merge
  tests[id][:ensure] = :present
  test_harness_run(tests, id)
  skipped_tests_summary(tests)
end

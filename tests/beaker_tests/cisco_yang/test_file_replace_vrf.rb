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
#
# See README-develop-beaker-scripts.md (Section: Test Script Variable Reference)
# for information regarding:
#  - test script general prequisites
#  - command return codes
#  - A description of the 'tests' hash and its usage
#
###############################################################################
require File.expand_path('../../lib/utilitylib.rb', __FILE__)
require File.expand_path('../util.rb', __FILE__)

# Test hash top-level keys
tests = {
  master:        master,
  agent:         agent,
  resource_name: 'cisco_yang',
}
tests[:replace_merge] = FILE_REPLACE

step 'Setup' do
  on(agent, puppet_resource('file', '/root/temp/', 'ensure=directory'))
  on(agent, puppet_resource('file', \
                            '/root/temp/vrfs.json', \
                            'source="puppet:///modules/ciscoyang/models/defaults/vrfs.json"', \
                            'ensure=present'))
end

teardown do
  on(agent, puppet_resource('cisco_yang', '\'' + ROOT_VRF + '\'', 'ensure=absent'))
  on(agent, puppet_resource('file', \
                            '/root/temp/vrfs.json', \
                            'ensure=absent'))
end

#################################################################
# TEST CASE EXECUTION
#################################################################
test_name "TestCase :: read config from vrfs.json file and replace current config with it" do
  id = :replace_merge
  tests[id][:ensure] = :present
  test_harness_run(tests, id)
  skipped_tests_summary(tests)
end

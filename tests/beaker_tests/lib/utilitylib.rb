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

# TestCase Utility Library:
# --------------------------
# utilitylib.rb
#
# This is the utility library for the Cisco provider Beaker test cases that
# contains the common methods used across the testsuite's cases. The library
# is implemented as a module with related methods and constants defined inside
# it for use as a namespace. All of the methods are defined as module methods.
#
# Every Beaker test script that runs an instance of TestCase requires this lib.
#
# The library has 4 sets of methods:
# -- Method to define PUPPETMASTER_MANIFESTPATH constant using puppet
#    config command output on puppet master.
# -- Method to search for RegExp patterns in command execution output and
#    raise fail_test exceptions for failed pattern matches in the output.
# -- Method to raise pass_test or fail_test exception based on testcase
#    result.

# Group of constants for use by the Beaker::TestCase instances.
# Binary executable path for puppet on master and agent.
PUPPET_BINPATH = '/opt/puppetlabs/bin/puppet '
# Binary executable path for facter on master and agent.
FACTER_BINPATH = '/opt/puppetlabs/bin/facter '
# Location of the main Puppet manifest
PUPPETMASTER_MANIFESTPATH = '/etc/puppetlabs/code/environments/production/manifests/site.pp'
# Indicates that we want to ignore the value when matching (essentially
# testing the presence of a key, regardless of value)
IGNORE_VALUE = :ignore_value

PARAMETER_KEYS = [:mode, :force]

def scrub_yang(yang)
  yang
end

# These methods are defined outside of a module so that
# they can access the Beaker DSL API's.

# Method to parse a Hash literal into an array of RegExp literals.
# @param hash [hash] Comma-separated list of key/value pairs.
# @result regexparr [Array] Array of RegExp literals.
def hash_to_patterns(hash)
  regexparr = []
  hash.each do |key, value|
    if value == IGNORE_VALUE
      regexparr << Regexp.new("#{key}\s+=>?")
      next
    end
    value = value.to_s
    if key == :source
      value = Regexp.escape(scrub_yang(value) || '')
    elsif PARAMETER_KEYS.include?(key)
      # skip parameters, since they won't be in the output
      next
    elsif /^\[.*\]$/.match(value)
      # Need to escape '[', ']', '"' characters for nested array of arrays.
      # Example:
      #   [["192.168.5.0/24", "nrtemap1"], ["192.168.6.0/32"]]
      # Becomes:
      #   \[\['192.168.5.0\/24', 'nrtemap1'\], \['192.168.6.0\/32'\]\]
      value.gsub!(/[\[\]]/) { |s| '\\' + "#{s}" }.gsub!(/\"/) { |_s| '\'' }
    end
    regexparr << Regexp.new("#{key}\s*=>\s*'?#{value}'?")
  end
  regexparr
end

# Method to check if RegExp pattern array exists in Beaker::Result object's
# stdout or output instance attributes.
# @param output [IO] IO attribute output or stdout of Result object.
# @param patarr [Array, Hash] Array of RegExp patterns or Hash of key/value
# pairs to search in output object.
# @param inverse [Boolean] Boolean flag to indicate Boolean NOT matching op.
# @param testcase [TestCase] An instance of Beaker::TestCase.
# @param logger [Logger] A default instance of Beaker::Logger.
# @result none [None] Returns no object.
def search_pattern_in_output(output, patarr, inverse, testcase,\
                             logger)
  patarr = hash_to_patterns(patarr) if patarr.instance_of?(Hash)
  output = scrub_yang(output)
  patarr.each do |pattern|
    inverse ? (match = (output !~ pattern)) : (match = (output =~ pattern))
    match_kind = inverse ? 'Inverse ' : ''
    if match
      logger.debug("TestStep :: #{match_kind}Match #{pattern.inspect} :: PASS")
    else
      logger.debug("Beaker Test :: output #{output}")
      testcase.fail_test("TestStep :: #{match_kind}Match #{pattern.inspect} :: FAIL")
    end
  end
end

# Method to raise and handle Beaker::DSL::Outcomes::PassTest or
# Beaker::DSL::Outcomes::FailTest exception based on testresult value.
# @param testresult [String] String object set to 'PASS' or 'FAIL'.
# @param message [String] String object to represent testcase.
# @param testcase [TestCase] An instance of Beaker::TestCase.
# @param logger [Logger] A default instance of Beaker::Logger.
# @result none [None] Returns no object.
def raise_passfail_exception(testresult, message, testcase, logger)
  if testresult == 'PASS'
    testcase.pass_test("\nTestCase :: #{message} :: PASS")
  else
    testcase.fail_test("\nTestCase :: #{message} :: FAIL")
  end
rescue Beaker::DSL::Outcomes::PassTest
  logger.success("TestCase :: #{message} :: PASS")
rescue Beaker::DSL::Outcomes::FailTest
  logger.error("TestCase :: #{message} :: FAIL")
end

# Raise a Beaker::DSL::Outcomes::SkipTest exception.
# @param message [String] String object to represent testcase.
# @param testcase [TestCase] An instance of Beaker::TestCase.
# @result none [None] Returns no object.
def raise_skip_exception(message, testcase)
  testcase.skip_test("\nTestCase :: #{message} :: SKIP")
end

# Full command string for puppet agent
def puppet_agent_cmd
  PUPPET_BINPATH + 'agent -t'
end

# Auto generation of properties for manifests
# attributes: hash of property names and values
# return: a manifest friendly string of property names / values
def prop_hash_to_manifest(attributes)
  return '' if attributes.nil?
  manifest_str = ''
  attributes.each do |k, v|
    next if v.nil?
    if v.is_a?(String)
      manifest_str += sprintf("    %-40s => '#{v.strip}',\n", k)
    else
      manifest_str += sprintf("    %-40s => #{v},\n", k)
    end
  end
  manifest_str
end

# Wrapper for processing all tests for each test scenario.
#
# Inputs:
# tests - a hash of control values
# id - identifies the specific test case hash key
#
# Top-level keys set by caller:
# tests[:master] - the master object
# tests[:agent] - the agent object
#
# tests[id] keys set by caller:
# tests[id][:desc] - a string to use with logs & debugs
# tests[id][:manifest] - the complete manifest, as used by test_harness_common
# tests[id][:resource] - a hash of expected states, used by test_resource
# tests[id][:resource_cmd] - 'puppet resource' command to use with test_resource
# tests[id][:ensure] - (Optional) set to :present or :absent before calling
# tests[id][:code] - (Optional) override the default exit code in some tests.
#
# Reserved keys
# tests[id][:log_desc] - the final form of the log description
#
def test_harness_common(tests, id)
  tests[id][:ensure] = :present if tests[id][:ensure].nil?
  tests[id][:state] = false if tests[id][:state].nil?
  tests[id][:desc] = '' if tests[id][:desc].nil?
  tests[id][:log_desc] = tests[id][:desc] + " [ensure => #{tests[id][:ensure]}]"
  logger.info("\n--------\n#{tests[id][:log_desc]}")

  test_manifest(tests, id)
  test_resource(tests, id)
  test_idempotence(tests, id)
  tests[id].delete(:log_desc)
end

# Wrapper for formatting test log entries
def format_stepinfo(tests, id, test_str)
  logger.debug("format_stepinfo :: (#{tests[id][:desc]}) (#{test_str})")
  tests[id][:log_desc] = tests[id][:desc] if tests[id][:log_desc].nil?
  tests[id][:log_desc] + sprintf(' :: %-12s', test_str)
end

# helper to match stderr buffer against :stderr_pattern
def test_stderr(tests, id)
  if stderr =~ tests[id][:stderr_pattern]
    logger.debug("TestStep :: Match #{tests[id][:stderr_pattern]} :: PASS")
  else
    fail_test("TestStep :: Match #{tests[id][:stderr_pattern]} :: FAIL")
  end
end

# Wrapper for manifest tests
# Pass code = [0], as an alternative to 'test_idempotence'
def test_manifest(tests, id)
  stepinfo = format_stepinfo(tests, id, 'MANIFEST')
  step "TestStep :: #{stepinfo}" do
    logger.debug("test_manifest :: manifest:\n#{tests[id][:manifest]}")
    on(tests[:master], tests[id][:manifest])
    code = tests[id][:code] ? tests[id][:code] : [2]
    logger.debug("test_manifest :: check puppet agent cmd (code: #{code})")
    on(tests[:agent], puppet_agent_cmd, acceptable_exit_codes: code)
    test_stderr(tests, id) if tests[id][:stderr_pattern]
  end
  logger.info("#{stepinfo} :: PASS")
  tests[id].delete(:log_desc)
end

# Wrapper for 'puppet resource' command tests
def test_resource(tests, id, state=false)
  stepinfo = format_stepinfo(tests, id, 'RESOURCE')
  step "TestStep :: #{stepinfo}" do
    logger.debug("test_resource :: cmd:\n#{tests[id][:resource_cmd]}")
    on(tests[:agent], tests[id][:resource_cmd]) do
      search_pattern_in_output(
        stdout, tests[id][:resource],
        state, self, logger)
    end
    logger.info("#{stepinfo} :: PASS")
    tests[id].delete(:log_desc)
  end
end

# Wrapper for idempotency tests
def test_idempotence(tests, id)
  stepinfo = format_stepinfo(tests, id, 'IDEMPOTENCE')
  step "TestStep :: #{stepinfo}" do
    logger.debug('test_idempotence :: BEGIN')
    on(tests[:agent], puppet_agent_cmd, acceptable_exit_codes: [0])
    logger.info("#{stepinfo} :: PASS")
    tests[id].delete(:log_desc)
  end
end

# Helper to clean a specific resource by title name
def resource_absent_by_title(agent, res_name, title)
  res_cmd = PUPPET_BINPATH + "resource #{res_name}"
  on(agent, "#{res_cmd} '#{title}' ensure=absent")
end

# Helper method to create a puppet resource command string
# [:title] (required) This string will become the entire cmd string
def puppet_resource_cmd_from_params(tests, id)
  fail 'tests[:resource_name] is not defined' unless tests[:resource_name]

  title_string = tests[id][:title]
  cmd = PUPPET_BINPATH + "resource #{tests[:resource_name]} '#{title_string}'"

  logger.info("\ntitle_string: '#{title_string}'")
  tests[id][:resource_cmd] = cmd
end

# Create manifest and resource command strings for a given test scenario.
# Returns true if a valid/non-empty manifest was created, false otherwise.
# Test hash keys used by this method:
# [:resource_name] (REQUIRED) This is the resource name to use in the manifest
#   the for puppet resource command strings
# [:manifest_props] (REQUIRED) This is a hash of properties to use in building
#   the manifest; they are also used to populate [:resource] when that key is
#   not defined.
# [:resource] (OPTIONAL) This is a hash of properties to use for validating the
#   output from puppet resource.
# [:title] (OPTIONAL) The title to use in the manifest
#
def create_manifest_and_resource(tests, id)
  fail 'tests[:resource_name] is not defined' unless tests[:resource_name]

  tests[id][:title] = id if tests[id][:title].nil?

  # Create the cmd string for puppet_resource
  puppet_resource_cmd_from_params(tests, id)

  # Setup the ensure state, manifest string, and resource command state
  state = ''
  if tests[id][:ensure] == :absent
    state = 'ensure => absent,'
    tests[id][:resource] = { 'ensure' => 'absent' }
  else
    state = 'ensure => present,' unless tests[:ensurable] == false
    tests[id][:resource]['ensure'] = nil unless
      tests[id][:resource].nil? || tests[:ensurable] == false

    manifest_props = tests[id][:manifest_props]

    # Create the property string for the manifest
    manifest = prop_hash_to_manifest(manifest_props) if manifest_props

    # Automatically create a hash of expected states for puppet resource
    # -or- use a static hash
    # TBD: Need a prop_hash_to_resource to handle array patterns
    tests[id][:resource] = manifest_props unless tests[id][:resource]
  end

  tests[id][:manifest] = "cat <<EOF >#{PUPPETMASTER_MANIFESTPATH}
  \nnode default {
  #{dependency_manifest(tests, id)}
  #{tests[:resource_name]} { '#{tests[id][:title]}':
    #{state}\n#{manifest}
  }\n}\nEOF"

  true
end

# dependency_manifest
#
# This method returns a string representation of a manifest that contains
# any dependencies needed for a particular test to run.
# Override this in a particular test file as needed.
def dependency_manifest(_tests, _id)
  nil # indicates no manifest dependencies
end

# test_harness_run
#
# This method is a front-end for test_harness_common.
# - Creates manifests
# - Sets 'ensure' if needed
# - Calls test_harness_common
def test_harness_run(tests, id)
  return if skip_unless_supported(tests, id)

  begin
    tests[id][:ensure] = :present if tests[id][:ensure].nil?

    # Build the manifest for this test
    unless create_manifest_and_resource(tests, id)
      logger.error("\n#{tests[id][:desc]} :: #{id} :: SKIP")
      logger.error('No supported properties remain for this test.')
      return
    end

    test_harness_common(tests, id)
    tests[id][:ensure] = nil
  rescue => exception
    logger.debug(exception.backtrace)
    raise
  end
end

# test_harness_run_clean
#
# This method is for running a test with cleanup before
# and after.
# - Cleans resources by title
# - Calls test_harness_run
# - Cleans resources by title
def test_harness_run_clean(tests, id)
  # clean out any resources
  resource_absent_by_title(tests[:agent], tests[:resource_name], tests[id][:title])

  # run manifest, resource, idempotence tests  
  test_harness_run(tests, id)
  
  # clean out any resources
  resource_absent_by_title(tests[:agent], tests[:resource_name], tests[id][:title])
end

# Helper to set properties using the puppet resource command.
def resource_set(agent, resource, msg='')
  logger.info("\n#{msg}")
  cmd = "resource #{resource[:name]} '#{resource[:title]}' " \
                  "#{resource[:property]}='#{resource[:value]}'"
  cmd = PUPPET_BINPATH + cmd
  on(agent, cmd, acceptable_exit_codes: [0, 2])
end

# Helper to raise skip when prereqs are not met
def prereq_skip(testheader, testcase, message)
  testheader = '' if testheader.nil?
  logger.error("** PLATFORM PREREQUISITE NOT MET: #{message}")
  raise_skip_exception(testheader, testcase)
end

# Facter command builder helper method
def facter_cmd(cmd)
  FACTER_BINPATH + cmd
end

@os = nil
# Use facter to return operating system information
def os
  return @os unless @os.nil?
  @os = on(agent, facter_cmd('os.name')).stdout.chomp
end

@os_version = nil
# Use facter to return operating system version information
def os_version
  return @os_version unless @os_version.nil?
  @os_version = on(agent, facter_cmd('os.release.full')).stdout.chomp
end

@client_envs = nil
# Use facter to return cisco operating system information
def client_envs
  return @client_envs unless @client_envs.nil?
  @client_envs = on(agent, facter_cmd('-p cisco_yang.configured_envs')).stdout.chomp.split(',')
end

# Method for any extra checks to be done to determine support.
# Override this in a particular test file as needed.
def agent_supports_test?(tests, id=nil)
  true
end  

# Helper to skip tests on unsupported agents.
# Returns true if skipped, false if not skipped.
def skip_unless_supported(tests, id=nil)
  return false if agent_supports_test_private?(tests, id)
  
  if id
    tests[:skipped] ||= []
    tests[:skipped] << tests[id][:desc]
  else
    msg = "Tests in '#{File.basename(path)}' "\
          'are unsupported on this node.'
    banner = '#' * msg.length
    raise_skip_exception("\n#{banner}\n#{msg}\n#{banner}\n", self)
  end
  true
end

def client_pattern(tests)
  return tests[:client] if tests[:client]
  case tests[:resource_name]
  when 'cisco_yang'
    return 'grpc'
  when 'cisco_yang_netconf'
    return 'netconf'
  else
    return nil
  end  
end

def skipped_tests_summary(tests)
  return unless tests[:skipped]
  logger.info("\n#{'-' * 60}\n  SKIPPED TESTS SUMMARY\n#{'-' * 60}")
  tests[:skipped].each do |desc|
    logger.error(sprintf('%-40s :: SKIP', desc))
  end
  raise_skip_exception(tests[:resource_name], self)
end

private 

# Returns true if the actual_version is greater than 
# or equal to the test version.
def version_matches(actual_version, test_version)
  av = Gem::Version.new(actual_version)
  tv = Gem::Version.new(test_version)
  return (av <=> tv) >= 0
end

# Helper to determine if agent supports specified test(s).
#
# Variables used to determine support:
#   tests[:resource_name] - puppet type (e.g. 'cisco_yang', 'cisco_yang_netconf')
#   tests[:os] - An OS regexp pattern for all tests (caller set)
#   tests[:os_version] - The minimum client OS version for all tests (caller set)
#   tests[:client] - A client regexp pattern for all tests (caller set)
#
# Conditional (if id is specified)
#   tests[id][:os] - An OS regexp pattern for specified test (caller set)
#   tests[id][:os_version] - The minimum client OS version for specified test (caller set)
#   tests[id][:client] - A client regexp pattern for specified test (caller set)
def agent_supports_test_private?(tests, id=nil)
  return false unless agent_supports_test?(tests, id)
  
  # Prefer specific test key over the all tests key
  os_regex = (id ? tests[id][:os] : nil) || tests[:os]
  os_version_test = (id ? tests[id][:os_version] : nil) || tests[:os_version]
  client_regex = (id ? tests[id][:client] : nil) || client_pattern(tests)
  if os_regex && !os.match(os_regex)
    logger.info("\n#{tests[id][:desc]} :: #{id} :: SKIP") if id
    logger.info("Operating system (#{os}) does not match testcase os regex: /#{os_regex}/")
  elsif client_regex && client_envs.grep(client_regex).empty?
    logger.info("\n#{tests[id][:desc]} :: #{id} :: SKIP") if id
    logger.info("No client environments (#{client_envs.join(', ')}) match testcase client regexp: /#{client_regex}/")
  elsif os_version_test && !version_matches(os_version, os_version_test)
    logger.info("\n#{tests[id][:desc]} :: #{id} :: SKIP") if id
    logger.info("OS version (#{os_version}) is not >= testcase version: /#{os_version_test}/")
  else
    return true
  end
  false
end

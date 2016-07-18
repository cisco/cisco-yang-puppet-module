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
#
# This is a utility to output the current state of an XR configuration.
# In order to run, this utility needs access to one or more *.yang files
# (found in the /pkg/yang directory on the XR box, as well as from other
# sources).

require 'optparse'
require_relative 'yang_accessor'

# Utility class to output the current state of an XR configuration.

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby [path]show_running_yang.rb [options] [file_or_directory_path]'

  opts.on('-m', '--manifest', 'Output config in a form suitable '\
          'for inclusion in a Puppet manifest') do |_arg|
    options[:manifest] = true
  end

  opts.on('-o', '--oper',
          'Retrieve operational data instead of configuration '\
          '(warning: possibly returns a lot of data; use at own risk)') do
    options[:oper] = true
  end

  opts.on('-c', '--client CLIENT', 'The client to use to connect.',
          'grpc|netconf (defaults to grpc') do |client|
    options[:client] = client
  end

  # opts.on('-e', '--environment node', 'The node in cisco_node_utils.yaml '\
  #        'from which to retrieve data') do |env|
  #  options[:environment] = env
  # end

  opts.on('-d', '--debug', 'Enable debug-level logging') do
    Cisco::Logger.level = Logger::DEBUG
  end

  opts.on('-v', '--verbose', 'Enable verbose messages') do
    options[:verbose] = true
  end

  opts.on('-h', '--help', 'Print this help') do
    puts optparse
    exit(0)
  end
end
optparse.parse!

if options[:oper] && options[:manifest]
  STDERR.puts '!! Operational data cannot be set in a manifest, '\
      'so option -m does not make sense in conjunction with -o.'
  exit(-1)
end

case options[:client]
when 'netconf'
  options[:client_class] = Cisco::Client::NETCONF
when 'grpc', nil
  options[:client_class] = Cisco::Client::GRPC
else
  STDERR.puts "!! Invalid client specified: #{options[:client]}"
  exit(-1)
end

# If there is a single ARGV left, use is as the file/dir path
if ARGV.length == 1
  options[:path] = ARGV[0]
elsif ARGV.length > 1
  puts optparse
  exit(-1)
end

ya = Cisco::YangAccessor.new
ya.process(options)

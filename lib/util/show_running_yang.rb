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
require_relative 'node_util'

module Cisco
  # Utility class to output the current state of an XR configuration.
  class YangViewer
    def process(options)
      @options = options

      client # initialize the client

      dir_or_file = options[:path]

      file = nil
      dir = nil

      if File.exist?(dir_or_file)
        if File.directory?(dir_or_file)
          dir = dir_or_file
        else
          file = dir_or_file
        end
      else
        puts "Directory or file not found: #{dir_or_file}"
        exit(-1)
      end

      puts "File found: #{file}" if file
      puts "Directory found: #{dir}" if dir
      puts 'Searching for configuration data...' unless @options[:oper]
      puts 'Searching for operational data...' if @options[:oper]

      t1 = Time.now

      @files = 0
      @cnrs = 0
      @errors = 0
      if file
        process_file(file)
        @files += 1
      else
        Dir.glob(dir + '/*.yang').sort.each do |item|
          process_file(item)
          @files += 1
        end
      end

      delta = Time.now - t1
      puts '---------------------------------------------'
      puts "Files Processed: #{@files}"
      puts "Containers Processed: #{@cnrs}"
      puts "Errors: #{@errors}"
      puts "Time: #{delta.round(2)} seconds"
      puts # spacer
    end

    def process_file(file)
      @module = nil
      @namespace = nil
      @containers = {}
      puts "[ Processing file #{file} ]" if @options[:verbose]

      File.open(file) do |f|
        loop do
          break if (line = f.gets).nil?
          process_line(line, f)
        end
      end
    end

    def process_line(line, file)
      if @module.nil?
        @module = Regexp.last_match(1) if line =~ /^module (.+) {/
      elsif @namespace.nil?
        @namespace = Regexp.last_match(1) if line =~ /^  namespace "(.+)"/
      elsif line =~ /^  container (.+) {/
        process_root_container(@module, @namespace, Regexp.last_match(1), file)
      end
    end

    def process_root_container(module_name, namespace, container, file)
      operation = :get_config
      loop do
        line = file.gets
        break if !line || line.strip == ''
        if line =~ /^    config false;/ # abort cnr if not config
          operation = :get_oper
          break
        end
      end

      # only output config or operational data, depending on options
      if @options[:oper]
        return if operation == :get_config
      else
        return if operation != :get_config
      end

      # guard against duplicate containers
      if @containers.key?(container)
        puts "[   Duplicate container #{container} ]" if @options[:verbose]
        return
      end

      yang_target = client.yang_target(module_name, namespace, container)

      @containers[container] = true
      @cnrs += 1

      begin
        data = client.get(data_format: :yang_json,
                          command:     yang_target,
                          mode:        operation)
        if data && data.strip.length > 0
          puts "[   Processing container #{container} ]"\
              if @options[:verbose]
          output_data(yang_target, data)
        else
          puts "[   Processing container #{container}: no data returned ]"\
              if @options[:verbose]
        end
      rescue Cisco::ClientError, Cisco::YangError => e
        puts "[   Processing container #{container} ]" if @options[:verbose]
        @errors += 1
        puts "!!Error on '#{yang_target}': #{e}"
        debug e.backtrace
        puts # spacer
      end
    end

    def output_data(yang_target, data)
      if @options[:manifest]
        if @options[:client_class] == Cisco::Client::GRPC
          puppet_type = 'cisco_yang'
          ensure_prop = "    ensure => present,\n"
        else
          puppet_type = 'cisco_yang_netconf'
          ensure_prop = ''
        end

        puts "  #{puppet_type} { '#{yang_target}':\n#{ensure_prop}"\
            "    source => '#{data.chomp.gsub(/\n/, "\n    ")}'\n"\
            '  }'
      else
        puts data
      end
      puts # spacer
    end

    def client
      unless @client
        @client = Cisco::Client.create(@options[:client_class])

        puts "[ Connected to client: #{@client} ]"\
            if @options[:verbose]
      end
      @client
    rescue Cisco::AuthenticationFailed
      abort 'Unauthorized to connect'
    rescue Cisco::ClientError, TypeError, ArgumentError => e
      abort "Error in establishing connection: #{e}"
    end
  end # YangViewer
end # Cisco

options = { path: '/pkg/yang', environment: 'default' }
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

ycv = Cisco::YangViewer.new
ycv.process(options)

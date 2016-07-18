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
source ENV['GEM_SOURCE'] || 'https://rubygems.org'

puppet_version = ENV['PUPPET_VERSION'] || '>= 4.0'
gem 'puppet', puppet_version

beaker_version = ENV['BEAKER_VERSION'] || '>= 2.38.1'
gem 'beaker', beaker_version

facter_version = ENV['FACTER_VERSION'] || '>= 1.7.0'
gem 'facter', facter_version

gem 'puppetlabs_spec_helper', '>= 0.8.2'
gem 'puppet-lint', '>= 1.0.0'
gem 'rubocop', '= 0.35.1', require: false
gem 'rake', '~> 10.1.0', require: false
gem 'metadata-json-lint'

# vim:ft=ruby

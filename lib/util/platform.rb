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

require_relative 'node_util'

module Cisco
  # Platform - class for gathering platform hardware and software information
  class Platform < NodeUtil
    
    # XR: 6.1.1.04I
    def self.image_version
      config_get('show_version', 'version')
    end

    # ex: 'n3500-uk9.6.0.2.A3.0.40.bin'
    def self.system_image
      config_get('show_version', 'boot_image')
    end

    def self.system_time
      client.system_time
    end

    def self.host_name
      client.host_name
    end

    def self.product_id
      client.product_id
    end

    def self.system
      client.system
    end
  end
end

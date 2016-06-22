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

ROOT_VRF = \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]
    }'

BLUE_VRF_WO_PROPERTY = \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:vrfs":
      {
        "vrf":
        [
          {
            "vrf-name":"BLUE",
            "create":[null]
          }
        ]
      }
    }'

BLUE_VRF_W_PROPERTY1 = \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:vrfs":
      {
        "vrf":
        [
          {
            "vrf-name":"BLUE",
            "create":[null],
            "vpn-id":{
              "vpn-oui":9,
              "vpn-index":9
            }
          }
        ]
      }
    }'

BLUE_VRF_W_PROPERTY2 = \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:vrfs":
      {
        "vrf":
        [
          {
            "vrf-name":"BLUE",
            "create":[null],
            "description":"Sample description"
          }
        ]
      }
    }'

BLUE_VRF_W_PROPERTY12 = \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:vrfs":
      {
        "vrf":
        [
          {
            "vrf-name":"BLUE",
            "create":[null],
            "description":"Sample description",
            "vpn-id":{
              "vpn-oui":9,
              "vpn-index":9
            }
          }
        ]
      }
    }'

GREEN_VRF_WO_PROPERTY = \
    '{
      "Cisco-IOS-XR-infra-rsi-cfg:vrfs":
      {
        "vrf":
        [
          {
            "vrf-name":"GREEN",
            "create":[null]
          }
        ]
      }
    }'

BLUE_GREEN_VRF_WO_PROPERTY = \
  '{
    "Cisco-IOS-XR-infra-rsi-cfg:vrfs":
    {
      "vrf":
      [
        {
          "vrf-name":"BLUE",
          "create":[null]
        },
        {
          "vrf-name":"GREEN",
          "create":[null]
        }
      ]
    }
  }'
INTERNET_VOIP_VRF = \
'{
   "Cisco-IOS-XR-infra-rsi-cfg:vrfs":{
      "vrf":[
         {
            "vrf-name":"VOIP",
            "create":[
               null
            ],
            "description":"Voice over IP",
            "vpn-id":{
               "vpn-oui":875,
               "vpn-index":3
            }
         },
         {
            "vrf-name":"INTERNET",
            "create":[
               null
            ],
            "description":"Generic external traffic",
            "vpn-id":{
               "vpn-oui":875,
               "vpn-index":22
            }
         }
      ]
   }
}'

ROOT_SRLG= \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:srlg": [null]
    }'

SRLG_GE_01= \
'{
 "Cisco-IOS-XR-infra-rsi-cfg:srlg": {
  "interfaces": {
   "interface": [
    {
     "interface-name": "GigabitEthernet0/0/0/0",
     "enable": [
      null
     ],
     "values": {
      "value": [
       {
        "srlg-index": 10,
        "srlg-value": 100,
        "srlg-priority": "default"
       },
       {
        "srlg-index": 20,
        "srlg-value": 200,
        "srlg-priority": "default"
       }
      ]
     },
     "interface-group": {
      "enable": [
       null
      ],
      "group-names": {
       "group-name": [
        {
         "group-name-index": 1,
         "group-name": "2",
         "srlg-priority": "default"
        }
       ]
      }
     }
    },
    {
     "interface-name": "GigabitEthernet0/0/0/1",
     "enable": [
      null
     ]
    }
   ]
  },
  "enable": [
   null
  ]
 }
}'

SRLG_GE_01_UPDATE= \
'{
 "Cisco-IOS-XR-infra-rsi-cfg:srlg": {
  "interfaces": {
   "interface": [
    {
     "interface-name": "GigabitEthernet0/0/0/0",
     "enable": [
      null
     ],
     "values": {
      "value": [
       {
        "srlg-index": 80,
        "srlg-value": 800,
        "srlg-priority": "default"
       },
       {
        "srlg-index": 90,
        "srlg-value": 900,
        "srlg-priority": "default"
       }
      ]
     },
     "interface-group": {
      "enable": [
       null
      ],
      "group-names": {
       "group-name": [
        {
         "group-name-index": 1,
         "group-name": "2",
         "srlg-priority": "default"
        }
       ]
      }
     }
    },
    {
     "interface-name": "GigabitEthernet0/0/0/1",
     "enable": [
      null
     ]
    }
   ]
  },
  "enable": [
   null
  ]
 }
}'

def massage_path(str)
  ret = str.clone
  ret.delete!("\n").gsub!(/\s*{\s*/,'{').gsub!(/\s*}\s*/,'}').gsub!(/\s*:\s*/,':')
  ret.gsub!(/\s*\[\s*/,'[').gsub!(/\s*\]\s*/,']').gsub!(/\s*,\s*/,',')
end

def create_pattern(str)
  ret = str.clone
  ret.delete!("\n").gsub!(/\s*{\s*/,'{').gsub!(/\s*}\s*/,'}').gsub!(/\s*:\s*/,':')
  ret.gsub!(/\s*\[\s*/,'\[').gsub!(/\s*\]\s*/,'\]').gsub!(/\s*,\s*/,',')
end

DELETE = {
    desc:           'Delete VRF BLUE',
    title_pattern:  BLUE_VRF_WO_PROPERTY,
    manifest_props: {
    },
    resource:       {
      'source' => create_pattern(BLUE_VRF_WO_PROPERTY),
      'ensure' => 'absent'
    },
  }

DELETE_PROPERTY = {
  desc:           'Delete VRF BLUE description',
  title_pattern:  BLUE_VRF_W_PROPERTY2,
  manifest_props: {
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_W_PROPERTY1),
    'ensure' => 'present'
  },
}

CREATE = {
  desc:           'Create VRF BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_WO_PROPERTY),
    'ensure' => 'present'
  },
}

CREATE_SRLG = {
  desc:           'CREATE SRLG GE0 and GE1',
  title_pattern:  ROOT_SRLG,
  manifest_props: {
    source: SRLG_GE_01,
  },
  resource:       {
    'source' => create_pattern(SRLG_GE_01),
    'ensure' => 'present'
  },
}

REPLACE = {
  desc:           'Replace VRF GREEN with BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
		mode: 'replace',
  },
  resource:       {
  'source' => create_pattern(BLUE_VRF_WO_PROPERTY),
	'ensure' => 'present',
  },
}

REPLACE12 = {
  desc:           'Replace VRF BLUE with BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    # Replace BLUE_VRF_W_PROPERTY1 by BLUE_VRF_W_PROPERTY2.
    source: BLUE_VRF_W_PROPERTY2,
    mode: 'replace',
  },
  resource:       {
  'source' => create_pattern(BLUE_VRF_W_PROPERTY2),
  'ensure' => 'present',
  },
}

MERGE = {
  desc:           'Merge VRF BLUE with GREEN',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
    mode: 'merge'
  },
  resource:       {
    'source' => create_pattern(BLUE_GREEN_VRF_WO_PROPERTY),
    'ensure' => 'present'
  },
}

MERGE12 = {
  desc:           'Merge VRF BLUE with BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    # merge BLUE_VRF_W_PROPERTY2 with existing configuration.
    # Expecting existing configuration to be BLUE_VRF_W_PROPERTY1
    # resulting BLUE_VRF_W_PROPERTY12
    source: BLUE_VRF_W_PROPERTY2,
    mode: 'merge'
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_W_PROPERTY12),
    'ensure' => 'present'
  },
}

REPLACE_SRLG = {
  desc:           'Update SRLG GE0 properties',
  title_pattern:  ROOT_SRLG,
  manifest_props: {
    source: SRLG_GE_01_UPDATE,
    mode: 'replace'
  },
  resource:       {
    'source' => create_pattern(SRLG_GE_01_UPDATE),
    'ensure' => 'present'
  },
}

FILE_MERGE = {
  desc:           'Merge VOIP and INTERNET VRFs with current config',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.json',
    mode: 'merge'
  },
  resource:       {
    'source' => create_pattern(INTERNET_VOIP_VRF),
    'ensure' => 'present'
  },
}

FILE_REPLACE = {
  desc:           'Replace current config by VOIP and INTERNET VRFs',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.json',
    mode: 'replace'
  },
  resource:       {
    'source' => create_pattern(INTERNET_VOIP_VRF),
    'ensure' => 'present'
  },
}

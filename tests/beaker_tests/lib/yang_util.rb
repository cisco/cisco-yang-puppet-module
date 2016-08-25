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
            "remote-route-filter-disable": [null]
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
            "remote-route-filter-disable": [null]
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
               "vpn-oui":87,
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
               "vpn-oui":85,
               "vpn-index":22
            }
         }
      ]
   }
}'

ROOT_SRLG = \
   '{
      "Cisco-IOS-XR-infra-rsi-cfg:srlg": [null]
    }'

SRLG_GE_01 = \
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

SRLG_GE_01_UPDATE = \
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
  ret.delete!("\n").gsub!(/\s*{\s*/, '{').gsub!(/\s*}\s*/, '}').gsub!(/\s*:\s*/, ':')
  ret.gsub!(/\s*\[\s*/, '[').gsub!(/\s*\]\s*/, ']').gsub!(/\s*,\s*/, ',')
end

DELETE = {
  desc:           'Delete VRF BLUE',
  title:          BLUE_VRF_WO_PROPERTY,
  manifest_props: {
  },
}

DELETE_PROPERTY = {
  desc:           'Delete VRF BLUE description',
  title:          BLUE_VRF_W_PROPERTY2,
  manifest_props: {
  },
}

CREATE = {
  desc:           'Create VRF BLUE',
  title:          ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY
  },
}

CREATE_SRLG = {
  desc:           'CREATE SRLG GE0 and GE1',
  title:          ROOT_SRLG,
  manifest_props: {
    source: SRLG_GE_01
  },
}

REPLACE = {
  desc:           'Replace VRF GREEN with BLUE',
  title:          ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
    mode:   'replace',
  },
}

REPLACE12 = {
  desc:           'Replace VRF BLUE with BLUE',
  title:          ROOT_VRF,
  manifest_props: {
    # Replace BLUE_VRF_W_PROPERTY1 by BLUE_VRF_W_PROPERTY2.
    source: BLUE_VRF_W_PROPERTY2,
    mode:   'replace',
  },
}

MERGE = {
  desc:           'Merge VRF BLUE with GREEN',
  title:          ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
    mode:   'merge',
  },
  resource:       {
    source: BLUE_GREEN_VRF_WO_PROPERTY
  },
}

MERGE12 = {
  desc:           'Merge VRF BLUE with BLUE',
  title:          ROOT_VRF,
  manifest_props: {
    # merge BLUE_VRF_W_PROPERTY2 with existing configuration (BLUE_VRF_W_PROPERTY1)
    # resulting BLUE_VRF_W_PROPERTY12
    source: BLUE_VRF_W_PROPERTY2,
    mode:   'merge',
  },
  resource:       {
    source: BLUE_VRF_W_PROPERTY12
  },
}

REPLACE_SRLG = {
  desc:           'Update SRLG GE0 properties',
  title:          ROOT_SRLG,
  manifest_props: {
    source: SRLG_GE_01_UPDATE,
    mode:   'replace',
  },
}

FILE_MERGE = {
  desc:           'Merge VOIP and INTERNET VRFs with current config',
  title:          ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.json',
    mode:   'merge',
  },
  resource:       {
    source: INTERNET_VOIP_VRF
  },
}

FILE_REPLACE = {
  desc:           'Replace current config by VOIP and INTERNET VRFs',
  title:          ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.json',
    mode:   'replace',
  },
  resource:       {
    source: INTERNET_VOIP_VRF
  },
}

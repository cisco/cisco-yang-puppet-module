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
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'

BLUE_VRF_WO_PROPERTY = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <create/>
    </vrf>
  </vrfs>'

BLUE_VRF_W_PROPERTY1 = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <create/>
      <vpn-id>
        <vpn-oui>9</vpn-oui>
        <vpn-index>9</vpn-index>
      </vpn-id>
    </vrf>
  </vrfs>'

BLUE_VRF_W_PROPERTY2 = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <description>Generic external traffic</description>
      <create/>
    </vrf>
  </vrfs>'

BLUE_VRF_W_PROPERTY12 = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <description>Generic external traffic</description>
      <create/>
      <vpn-id>
        <vpn-oui>0</vpn-oui>
        <vpn-index>0</vpn-index>
      </vpn-id>
    </vrf>
  </vrfs>'

GREEN_VRF_WO_PROPERTY = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>GREEN</vrf-name>
      <create/>
    </vrf>
  </vrfs>'

BLUE_GREEN_VRF_WO_PROPERTY = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <create/>
    </vrf>
    <vrf>
      <vrf-name>GREEN</vrf-name>
      <create/>
    </vrf>
  </vrfs>'

INTERNET_VOIP_VRF = \
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>VOIP</vrf-name>
    <create/>
    <description>Voice over IP</description>
    <vpn-id>
      <vpn-oui>875</vpn-oui>
      <vpn-index>3</vpn-index>
    </vpn-id>
  </vrf>
  <vrf>
    <vrf-name>INTERNET</vrf-name>
    <create/>
    <description>Generic external traffic</description>
    <vpn-id>
      <vpn-oui>875</vpn-oui>
      <vpn-index>22</vpn-index>
    </vpn-id>
  </vrf>
</vrfs>'

ROOT_SRLG = \
  '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'

SRLG_GE_01 = \
  '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <interfaces>
      <interface>
        <interface-name>
          GigabitEthernet0/0/0/0
        </interface-name>
        <enable/>
        <values>
          <value>
            <srlg-index>
              10
            </srlg-index>
            <srlg-value>
              100
            </srlg-value>
            <srlg-priority>
              default
            </srlg-priority>
          </value>
          <value>
            <srlg-index>
              20
            </srlg-index>
            <srlg-value>
              200
            </srlg-value>
            <srlg-priority>
              default
            </srlg-priority>
          </value>
        </values>
        <interface-group>
          <enable/>
          <group-names>
            <group-name>
              <group-name-index>
                1
              </group-name-index>
              <group-name>
                2
              </group-name>
              <srlg-priority>
                default
              </srlg-priority>
            </group-name>
          </group-names>
        </interface-group>
      </interface>
    </interfaces>
    <enable/>
  </srlg>'

SRLG_GE_01_UPDATE = \
  '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <interfaces>
      <interface>
        <interface-name>
          GigabitEthernet0/0/0/0
        </interface-name>
        <enable/>
        <values>
          <value>
            <srlg-index>
              20
            </srlg-index>
            <srlg-value>
              200
            </srlg-value>
            <srlg-priority>
              default
            </srlg-priority>
          </value>
          <value>
            <srlg-index>
              90
            </srlg-index>
            <srlg-value>
              900
            </srlg-value>
            <srlg-priority>
              default
            </srlg-priority>
          </value>
        </values>
        <interface-group>
          <enable/>
          <group-names>
            <group-name>
              <group-name-index>
                1
              </group-name-index>
              <group-name>
                9
              </group-name>
              <srlg-priority>
                default
              </srlg-priority>
            </group-name>
          </group-names>
        </interface-group>
      </interface>
    </interfaces>
    <enable/>
  </srlg>'

DELETE_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg" xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete"/>'


def clear_vrf
  on(agent, puppet_resource('cisco_yang_netconf', '\'' + ROOT_VRF + '\'', 'source=' + '\'' + ROOT_VRF + '\'', 'mode=replace'))
end

def clear_srlg
  on(agent, puppet_resource('cisco_yang_netconf', '\'' + ROOT_SRLG + '\'', 'source=' + '\'' + ROOT_SRLG + '\'', 'mode=replace'))
end

def massage_path(str)
  ret = str.clone
  ret.delete!("\n").gsub!(/\s*{\s*/, '{').gsub!(/\s*}\s*/, '}').gsub!(/\s*:\s*/, ':')
  ret.gsub!(/\s*\[\s*/, '[').gsub!(/\s*\]\s*/, ']').gsub!(/\s*,\s*/, ',')
end

def create_pattern(str)
  ret = str.clone
  ret.delete!("\n").gsub!(/\s*<\s*/, '<').gsub!(/\s*>\s*/, '>').gsub!(/\s*:\s*/, ':')
  ret.gsub!(/\s*,\s*/, ',')
end

CREATE = {
  desc:           'Create VRF BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_WO_PROPERTY)
  },
}

CREATE_SRLG = {
  desc:           'CREATE SRLG GE0 and GE1',
  title_pattern:  ROOT_SRLG,
  manifest_props: {
    source: SRLG_GE_01
  },
  resource:       {
    'source' => create_pattern(SRLG_GE_01)
  },
}

REPLACE = {
  desc:           'Replace VRF GREEN with BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
    mode:   'replace',
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_WO_PROPERTY)
  },
}

REPLACE12 = {
  desc:           'Replace VRF BLUE with BLUE',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    # Replace BLUE_VRF_W_PROPERTY1 by BLUE_VRF_W_PROPERTY2.
    source: BLUE_VRF_W_PROPERTY2,
    mode:   'replace',
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_W_PROPERTY2)
  },
}

MERGE = {
  desc:           'Merge VRF BLUE with GREEN',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: BLUE_VRF_WO_PROPERTY,
    mode:   'merge',
  },
  resource:       {
    'source' => create_pattern(BLUE_GREEN_VRF_WO_PROPERTY)
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
    mode:   'merge',
  },
  resource:       {
    'source' => create_pattern(BLUE_VRF_W_PROPERTY12)
  },
}

REPLACE_SRLG = {
  desc:           'Update SRLG GE0 properties',
  title_pattern:  ROOT_SRLG,
  manifest_props: {
    source: SRLG_GE_01_UPDATE,
    mode:   'replace',
  },
  resource:       {
    'source' => create_pattern(SRLG_GE_01_UPDATE)
  },
}

FILE_MERGE = {
  desc:           'Merge VOIP and INTERNET VRFs with current config',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.xml',
    mode:   'merge',
  },
  resource:       {
    'source' => create_pattern(INTERNET_VOIP_VRF)
  },
}

FILE_REPLACE = {
  desc:           'Replace current config by VOIP and INTERNET VRFs',
  title_pattern:  ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.xml',
    mode:   'replace',
  },
  resource:       {
    'source' => create_pattern(INTERNET_VOIP_VRF)
  },
}

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

NETCONF_ROOT_VRF = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'

NETCONF_BLUE_VRF_WO_PROPERTY = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <create/>
    </vrf>
  </vrfs>'

NETCONF_BLUE_VRF_W_PROPERTY1 = \
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

NETCONF_BLUE_VRF_W_PROPERTY2 = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <create/>
      <description>Generic external traffic</description>
    </vrf>
  </vrfs>'

NETCONF_BLUE_VRF_W_PROPERTY12 = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>BLUE</vrf-name>
      <create/>
      <description>Generic external traffic</description>
      <vpn-id>
        <vpn-oui>9</vpn-oui>
        <vpn-index>9</vpn-index>
      </vpn-id>
    </vrf>
  </vrfs>'

NETCONF_GREEN_VRF_WO_PROPERTY = \
  '<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
    <vrf>
      <vrf-name>GREEN</vrf-name>
      <create/>
    </vrf>
  </vrfs>'

NETCONF_BLUE_GREEN_VRF_WO_PROPERTY = \
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

NETCONF_INTERNET_VOIP_VRF = \
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

NETCONF_ROOT_SRLG = \
  '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg"/>'

NETCONF_SRLG_GE_01 = \
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

NETCONF_SRLG_GE_01_UPDATE = \
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

NETCONF_DELETE_SRLG = '<srlg xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg" xmlns:xc="urn:ietf:params:xml:ns:netconf:base:1.0" xc:operation="delete"/>'

def clear_vrf
  title_string = NETCONF_ROOT_VRF
  cmd = PUPPET_BINPATH + "resource cisco_yang_netconf '#{title_string}' source='#{title_string}' mode=replace"
  on(agent, cmd)
end

def clear_srlg
  title_string = NETCONF_ROOT_SRLG
  cmd = PUPPET_BINPATH + "resource cisco_yang_netconf '#{title_string}' source='#{title_string}' mode=replace"
  on(agent, cmd)
end

def massage_path(str)
  ret = str.clone
  ret.delete!("\n").gsub!(/\s*{\s*/, '{').gsub!(/\s*}\s*/, '}').gsub!(/\s*:\s*/, ':')
  ret.gsub!(/\s*\[\s*/, '[').gsub!(/\s*\]\s*/, ']').gsub!(/\s*,\s*/, ',')
end

NETCONF_CREATE = {
  desc:           'Create VRF BLUE',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    source: NETCONF_BLUE_VRF_WO_PROPERTY
  },
}

NETCONF_CREATE_SRLG = {
  desc:           'CREATE SRLG GE0 and GE1',
  title:          NETCONF_ROOT_SRLG,
  manifest_props: {
    source: NETCONF_SRLG_GE_01
  },
}

NETCONF_REPLACE = {
  desc:           'Replace VRF GREEN with BLUE',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    source: NETCONF_BLUE_VRF_WO_PROPERTY,
    mode:   'replace',
  },
}

NETCONF_REPLACE12 = {
  desc:           'Replace VRF BLUE with BLUE',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    # Replace NETCONF_BLUE_VRF_W_PROPERTY1 by NETCONF_BLUE_VRF_W_PROPERTY2.
    source: NETCONF_BLUE_VRF_W_PROPERTY2,
    mode:   'replace',
  },
}

NETCONF_MERGE = {
  desc:           'Merge VRF BLUE with GREEN',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    source: NETCONF_BLUE_VRF_WO_PROPERTY,
    mode:   'merge',
  },
  resource:       {
    source: NETCONF_BLUE_GREEN_VRF_WO_PROPERTY
  },
}

NETCONF_MERGE12 = {
  desc:           'Merge VRF BLUE with BLUE',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    # merge NETCONF_BLUE_VRF_W_PROPERTY2 with existing configuration.
    # Expecting existing configuration to be NETCONF_BLUE_VRF_W_PROPERTY1
    # resulting NETCONF_BLUE_VRF_W_PROPERTY12
    source: NETCONF_BLUE_VRF_W_PROPERTY2,
    mode:   'merge',
  },
  resource:       {
    source: NETCONF_BLUE_VRF_W_PROPERTY12
  },
}

NETCONF_REPLACE_SRLG = {
  desc:           'Update SRLG GE0 properties',
  title:          NETCONF_ROOT_SRLG,
  manifest_props: {
    source: NETCONF_SRLG_GE_01_UPDATE,
    mode:   'replace',
  },
}

NETCONF_FILE_MERGE = {
  desc:           'Merge VOIP and INTERNET VRFs with current config',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.xml',
    mode:   'merge',
  },
  resource:       {
    source: NETCONF_INTERNET_VOIP_VRF
  },
}

NETCONF_FILE_REPLACE = {
  desc:           'Replace current config by VOIP and INTERNET VRFs',
  title:          NETCONF_ROOT_VRF,
  manifest_props: {
    source: '/root/temp/vrfs.xml',
    mode:   'replace',
  },
  resource:       {
    source: NETCONF_INTERNET_VOIP_VRF
  },
}

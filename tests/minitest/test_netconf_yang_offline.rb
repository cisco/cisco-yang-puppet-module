gem 'minitest', '~> 5.0'
require 'minitest/autorun'
require_relative '../../lib/util/client/netconf/netconf'

# Two elts in Current, one will be deleted by operation=delete clause
CURRENT_BLUE_RED_VRF =
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>blue</vrf-name>
   </vrf>
  <vrf>
    <vrf-name>red</vrf-name>
   </vrf>
</vrfs>'

TARGET_BLUE_RED_VRF =
'<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <infra-rsi-cfg:vrf>
    <infra-rsi-cfg:vrf-name>blue</infra-rsi-cfg:vrf-name>
   </infra-rsi-cfg:vrf>
  <infra-rsi-cfg:vrf xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" nc:operation="delete">
    <infra-rsi-cfg:vrf-name>red</infra-rsi-cfg:vrf-name>
   </infra-rsi-cfg:vrf>
</infra-rsi-cfg:vrfs>'

# Two elts in Current, delete in target is a no-op.  Merge should be a no-op, but replace should not
CURRENT_BLUE_GREEN_VRF =
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>blue</vrf-name>
   </vrf>
  <vrf>
    <vrf-name>green</vrf-name>
   </vrf>
</vrfs>'

TARGET_BLUE_GREEN_VRF =
'<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <infra-rsi-cfg:vrf>
    <infra-rsi-cfg:vrf-name>blue</infra-rsi-cfg:vrf-name>
   </infra-rsi-cfg:vrf>
  <infra-rsi-cfg:vrf xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" nc:operation="delete">
    <infra-rsi-cfg:vrf-name>red</infra-rsi-cfg:vrf-name>
   </infra-rsi-cfg:vrf>
</infra-rsi-cfg:vrfs>'


# Single elt in Current, operation=delete in target results in no-op
CURRENT_DELETE_DELETED_VRF =
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>blue</vrf-name>
    <description>Blue description</description>
    <create/>
  </vrf>
</vrfs>'

TARGET_DELETE_DELETED_VRF =
'<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <infra-rsi-cfg:vrf>
    <infra-rsi-cfg:vrf-name>blue</infra-rsi-cfg:vrf-name>
    <infra-rsi-cfg:description>Blue description</infra-rsi-cfg:description>
    <infra-rsi-cfg:create/>
  </infra-rsi-cfg:vrf>
  <infra-rsi-cfg:vrf xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" nc:operation="delete">
    <infra-rsi-cfg:vrf-name>red</infra-rsi-cfg:vrf-name>
    <infra-rsi-cfg:description>Red description</infra-rsi-cfg:description>
    <infra-rsi-cfg:create/>
  </infra-rsi-cfg:vrf>
</infra-rsi-cfg:vrfs>'

# No elts in current, operation=delete in target results in no-op
CURRENT_DELETE_DELETED_VRF_2 =
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
</vrfs>'

TARGET_DELETE_DELETED_VRF_2 =
'<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <infra-rsi-cfg:vrf xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" nc:operation="delete">
    <infra-rsi-cfg:vrf-name>red</infra-rsi-cfg:vrf-name>
  </infra-rsi-cfg:vrf>
</infra-rsi-cfg:vrfs>'

# Simple case to validate namespace normalization
CURRENT_BLUE_VRF =
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>blue</vrf-name>
    <description>Blue description</description>
    <create/>
  </vrf>
</vrfs>'

TARGET_BLUE_VRF =
'<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <infra-rsi-cfg:vrf>
    <infra-rsi-cfg:vrf-name>blue</infra-rsi-cfg:vrf-name>
    <infra-rsi-cfg:description>Blue description</infra-rsi-cfg:description>
    <infra-rsi-cfg:create/>
  </infra-rsi-cfg:vrf>
</infra-rsi-cfg:vrfs>'

# Delete a non-container element
CURRENT_BLUE_VRF_DELETE_DESCRIPTION =
'<vrfs xmlns="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <vrf>
    <vrf-name>blue</vrf-name>
    <description>Blue description</description>
    <create/>
  </vrf>
</vrfs>'

TARGET_BLUE_VRF_DELETE_DESCRIPTION =
'<infra-rsi-cfg:vrfs xmlns:infra-rsi-cfg="http://cisco.com/ns/yang/Cisco-IOS-XR-infra-rsi-cfg">
  <infra-rsi-cfg:vrf>
    <infra-rsi-cfg:vrf-name>blue</infra-rsi-cfg:vrf-name>
      <infra-rsi-cfg:description xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" nc:operation="delete">
        Blue description
      </infra-rsi-cfg:description>
    <infra-rsi-cfg:create/>
  </infra-rsi-cfg:vrf>
</infra-rsi-cfg:vrfs>'

class TestNetconfOffline < Minitest::Test
  def test_netconf_prefix_merge
    assert(Cisco::Netconf::insync_for_merge(TARGET_BLUE_VRF,
                                            CURRENT_BLUE_VRF),
           "expected in-sync")
  end
  def test_netconf_prefix_replace
    assert(Cisco::Netconf::insync_for_replace(TARGET_BLUE_VRF,
                                              CURRENT_BLUE_VRF),
           "expected in-sync")
  end
  def test_netconf_delete_vrf_description_merge
    refute(Cisco::Netconf::insync_for_merge(TARGET_BLUE_VRF_DELETE_DESCRIPTION,
                                            CURRENT_BLUE_VRF_DELETE_DESCRIPTION),
           "expected not in-sync")
  end
  def test_netconf_delete_vrf_description_replace
    refute(Cisco::Netconf::insync_for_replace(TARGET_BLUE_VRF_DELETE_DESCRIPTION,
                                              CURRENT_BLUE_VRF_DELETE_DESCRIPTION),
           "expected not in-sync")
  end
  def test_netconf_delete_red_vrf_merge
    refute(Cisco::Netconf::insync_for_merge(TARGET_BLUE_RED_VRF,
                                            CURRENT_BLUE_RED_VRF),
           "expected not in-sync")
  end
  def test_netconf_delete_red_vrf_replace
    refute(Cisco::Netconf::insync_for_replace(TARGET_BLUE_RED_VRF,
                                              CURRENT_BLUE_RED_VRF),
           "expected not in-sync")
  end
  def test_netconf_delete_missing_vrf_merge
    assert(Cisco::Netconf::insync_for_merge(TARGET_DELETE_DELETED_VRF,
                                            CURRENT_DELETE_DELETED_VRF),
           "expected in-sync")
  end
  def test_netconf_delete_missing_vrf_replace
    assert(Cisco::Netconf::insync_for_replace(TARGET_DELETE_DELETED_VRF,
                                              CURRENT_DELETE_DELETED_VRF),
           "expected in-sync")
  end
  def test_netconf_delete_missing_vrf_2_merge
    assert(Cisco::Netconf::insync_for_merge(TARGET_DELETE_DELETED_VRF_2,
                                            CURRENT_DELETE_DELETED_VRF_2),
           "expected in-sync")
  end
  def test_netconf_delete_missing_vrf_2_replace
    assert(Cisco::Netconf::insync_for_replace(TARGET_DELETE_DELETED_VRF_2,
                                              CURRENT_DELETE_DELETED_VRF_2),
           "expected in-sync")
  end
  def test_netconf_delete_combo_merge
    assert(Cisco::Netconf::insync_for_merge(TARGET_BLUE_GREEN_VRF,
                                            CURRENT_BLUE_GREEN_VRF),
           "expected in-sync")
  end
  def test_netconf_delete_combo_replace
    refute(Cisco::Netconf::insync_for_replace(TARGET_BLUE_GREEN_VRF,
                                              CURRENT_BLUE_GREEN_VRF),
           "expected not in-sync")
  end
end

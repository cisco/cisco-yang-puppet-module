node 'default' {
  file { '/root/temp/vrfs.json': source => 'puppet:///modules/ciscoyang/models/defaults/vrfs.json'}

  # Configure two vrfs (VOIP & INTERNET)
  cisco_yang { '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}':
    ensure => present,
    source => '/root/temp/vrfs.json',
  }

  # other examples

  file { '/root/temp/vrf-voip.json': source => 'puppet:///modules/ciscoyang/models/defaults/vrf-voip.json'}

  # Add a single vrf (VOIP)
  cisco_yang { '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}':
    ensure => present,
    source => '/root/temp/vrf-voip.json'
  }

  # Remove a single vrf (VOIP)
  cisco_yang { '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}':
    ensure => absent,
    source => '/root/temp/vrf-voip.json',
  }

  # Remove all vrfs
  cisco_yang { '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}':
      ensure => absent
  }
}

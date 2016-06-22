# ciscoyang

#### Table of Contents

1. [Overview](#overview)
1. [Module Description](#module-description)
1. [Setup](#setup)
1. [Usage](#usage)
1. [The `cisco_yang` Puppet Type](#cisco-yang-type)
1. [Limitations](#limitations)
1. [Learning Resources](#learning-resources)



## Overview

The `ciscoyang` module allows configuration of IOS-XR through Cisco supported [YANG data models](https://github.com/YangModels/yang/tree/master/vendor/cisco) in JSON format . This module bundles a Puppet type, provider, Beaker tests, and sample manifests to enable users to configure and manage IOS-XR.

Please refer to the [Limitations](#limitations) section for details on currently supported hardware and software.
The Limitations section also provides details on compatible Puppet Agent and Puppet Master versions.

This GitHub repository contains the latest version of the `ciscoyang` module source code. Supported versions of the `ciscoyang` module are available at Puppet Forge. Please refer to [SUPPORT.md](SUPPORT.md) for additional details.

Contributions to this Puppet Module are welcome. Guidelines on contributions to the module are captured in [CONTRIBUTING.md](CONTRIBUTING.md)

## Module Description

This module enables management of supported Cisco Network Elements through the ``cisco_yang`` Puppet Type and IOS XR provider.

A typical role-based architecture scenario might involve a network administrator who uses a version control system to manage various YANG-based configuration files.  An IT administrator who is responsible for the puppet infrastructure can simply reference the YANG files from a puppet manifest in order to deploy the configuration.

## Setup

### Puppet Master

The `ciscoyang` module must be installed on the Puppet Master server. Please see [Puppet Labs: Installing Modules](https://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html) for general information on Puppet module installation.

### Puppet Agent
The Puppet Agent requires installation and setup on each device. Agent setup can be performed as a manual process or it may be automated. For more information please see the [README-agent-install.md](docs/README-agent-install.md) document for detailed instructions on agent installation and configuration on Cisco IOS-XR devices.

### `cisco_node_utils` Ruby gem

This module has dependencies on the [`cisco_node_utils`](https://rubygems.org/gems/cisco_node_utils) ruby gem. After installing the Puppet Agent software, use Puppet's built-in [`Package`](examples/install.pp) provider to install the gem.

## Usage

The following example shows how to use `ciscoyang` to configure two VRF instances on a Cisco IOS-XR device.

~~~puppet
node 'default' {
  cisco_yang { 'my-config':
    ensure => present,
    target => '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}',
    source => '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": {
          "vrf":[
            {
                "vrf-name":"VOIP",
                "description":"Voice over IP",
                "vpn-id":{
                  "vpn-oui":875,
                  "vpn-index":3
                },
                "create":[
                  null
                ]
            },
            {
                "vrf-name":"INTERNET",
                "description":"Generic external traffic",
                "vpn-id":{
                  "vpn-oui":875,
                  "vpn-index":22
                },
                "create":[
                  null
                ]
            }
          ]
      }
    }',
  }
}
~~~

The following example shows how to copy a file from the Puppet master to
the agent and then reference it from the manifest.

~~~puppet
  file { '/root/bgp.json': source => 'puppet:///modules/ciscoyang/models/bgp.json' }

  cisco_yang { '{"Cisco-IOS-XR-ipv4-bgp-cfg:bgp": [null]}':
    ensure => present,
    mode   => replace,
    source => '/root/bgp.json',
  }
}
~~~

--
## <a name="cisco-yang-type">The ``cisco_yang`` Puppet Type<a>

Allows IOS-XR to be configured using YANG models in JSON format.

#### Parameters

##### `ensure`
Determines whether the config should be present or not on the device. Valid values are 'present' and 'absent'.

##### `target`
The model path of the target node in YANG JSON format, or a reference to a local file containing the model path.  For example, to configure the list of vrfs in IOS-XR, you could specify a target of '{"Cisco-IOS-XR-infra-rsi-cfg:vrfs": [null]}' or reference a file which contained the same JSON string.

##### `mode`
Determines which mode is used when setting configuration via ensure=>present. Valid values are `replace` and `merge` (which is the default). If `replace` is specified, the current configuration will be replaced by the configuration in the source property (corresponding to the ReplaceConfig gRPC operation). If `merge` is specified, the configuration in the source property will be merged into the current configuration (corresponding to the MergeConfig gRPC operation).

##### `force`
Valid values are `true` and `false` (which is the default). If `true` is specified, then the config in the source property is set on the device regardless of the current value. If `false` is specified (or no value is specified), the default behavior is to set the configuration only if it is different from the running configuration.

#### Properties

##### `source`
The model data in YANG JSON format, or a reference to a local file containing the model data.  This property is only used when ensure=>present is used. In addition, if source is not specified when ensure=>present is used, source will default to the value of the target parameter. This removes some amount of redundancy when the source and target values are the same (or very similar).

## Limitations

Minimum Requirements:
* Open source Puppet version 4.3.2+ or Puppet Enterprise 2015.3.2+
* Cisco IOS XRv 9000, OS Version TODO, Environments: native (Bash-shell)
* Cisco Network Convergence System (NCS) 55xx, OS Version TODO, Environments: native (Bash-shell)

## Learning Resources

* Puppet
  * [https://learn.puppetlabs.com/](https://learn.puppetlabs.com/)
  * [https://en.wikipedia.org/wiki/Puppet_(software)](https://en.wikipedia.org/wiki/Puppet_(software))
* Markdown (for editing documentation)
  * [https://help.github.com/articles/markdown-basics/](https://help.github.com/articles/markdown-basics/)
* Ruby
  * [https://en.wikipedia.org/wiki/Ruby_(programming_language)](https://en.wikipedia.org/wiki/Ruby_(programming_language))
  * [https://www.codecademy.com/tracks/ruby](https://www.codecademy.com/tracks/ruby)
  * [https://rubymonk.com/](https://rubymonk.com/)
  * [https://www.codeschool.com/paths/ruby](https://www.codeschool.com/paths/ruby)
* Ruby Gems
  * [http://guides.rubygems.org/](http://guides.rubygems.org/)
  * [https://en.wikipedia.org/wiki/RubyGems](https://en.wikipedia.org/wiki/RubyGems)
* YAML
  * [https://en.wikipedia.org/wiki/YAML](https://en.wikipedia.org/wiki/YAML)
  * [http://www.yaml.org/start.html](http://www.yaml.org/start.html)
* Yum
  * [https://en.wikipedia.org/wiki/Yellowdog_Updater,_Modified](https://en.wikipedia.org/wiki/Yellowdog_Updater,_Modified)
  * [https://www.centos.org/docs/5/html/yum/](https://www.centos.org/docs/5/html/yum/)
  * [http://www.linuxcommand.org/man_pages](http://www.linuxcommand.org/man_pages/yum8.html)

## License

~~~text
Copyright (c) 2014-2016 Cisco and/or its affiliates.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
~~~

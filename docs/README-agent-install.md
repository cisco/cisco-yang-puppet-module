# Puppet Agent Installation & Setup

#### Table of Contents

1. [Overview](#overview)
1. [Pre-Install Tasks](#pre-install)
1. [Puppet Agent Environment: bash-shell](#env-bs)
1. [Puppet Agent Installation, Configuration and Usage](#agent-config)
1. [Optional: Automated Installation Options](#auto-install)
1. [References](#references)

## <a name="overview">Overview</a>

This document describes Puppet agent installation and setup on Cisco IOS XR devices. These instructions focus on manual setup. See the [Automated Installation](#auto-install) section for documentation regarding alternative installation methods.

## <a name="pre-install">Pre-Install Tasks</a>

#### Platform and Software Minimum Requirements

The Cisco IOS XR Puppet implementation requires open source Puppet version 4.3.2 or Puppet Enterprise 2015.3.2. Currently, Cisco IOS XRv9k version 6.0.1 and later are supported.

#### Set Up the Network

Ensure that you have network connectivity prior to Puppet installation. Some basic CLI configuration may be necessary.

**Example:** Connectivity via GigabitEthernet interface - IOS XR

See also the [Cisco IOS XR Application Hosting Configuration Guide](http://www.cisco.com/c/en/us/td/docs/iosxr/AppHosting/App-Hosting-Config-Guide.html)

~~~
config
!
hostname xrv9k
domain name mycompany.com
!
interface GigabitEthernet0/0/0/0
 ipv4 address 10.0.0.98 255.255.255.0
 no shutdown
!
router static
 address-family ipv4 unicast
  0.0.0.0/0 GigabitEthernet0/0/0/0 10.0.0.1
!
grpc
 port 57799 # optional - default is 57400
!
tpa
 address-family ipv4
  update-source GigabitEthernet0/0/0/0
!
commit
end
~~~

#### Enable gRPC server

~~~
config
!
grpc
 port 57799 # optional - default is 57400
!
commit
end
~~~

Refer to the [gRPC configuration guide](http://www.cisco.com/c/en/us/td/docs/iosxr/ncs5500/DataModels/b-Datamodels-cg-ncs5500/b-Datamodels-cg-ncs5500_chapter_010.html#concept_700172ED7CF44313B0D7E521B2983F32) for more options.

#### Enable Netconf SSH server
~~~
config
!
ssh server v2
ssh server netconf vrf default
netconf-yang agent
 ssh
!
commit
end
~~~

Refer to the [Netconf configuration guide](http://www.cisco.com/c/en/us/td/docs/iosxr/ncs5500/DataModels/b-Datamodels-cg-ncs5500/b-Datamodels-cg-ncs5500_chapter_010.html#concept_36F5E732AF894862AC57FDC5FEBFA170) for more options.
 
After applying the correct config, you need to validate that there is an RSA key generated
~~~
show crypto key mypubkey rsa
~~~
If the above show command indicates that there is no RSA key, generate one.  Use 2048 bits when prompted.
~~~
crypto key generate rsa
~~~

You should now be able to connect to the Netconf service via an external device, using a management interface address.

#### Enable access to Netconf inside the third-party namespace
To enable access to Netconf from the puppet module, you will need to enable a few loopback interfaces.
Create loopback 0 and loopback 1.  Give them both addresses, and use the address for loopback 1 when using netconf from inside the third-party namespace.
~~~
config
!
interface loopback 0
 ipv4 address 1.1.1.1 255.255.255.255
 no shutdown
!
interface loopback 1
 ipv4 address 10.10.10.10 255.255.255.255
 no shutdown
!
end
~~~



## <a name="env-bs">Puppet Agent Environment: bash-shell</a>

**Example:**

~~~bash
xrv9k# run bash
bash-4.3# ip netns exec tpnns bash
~~~

Set up DNS configuration:

~~~
cat >> /etc/resolv.conf << EOF
nameserver 10.0.0.202
domain mycompany.com
search mycompany.com
EOF
~~~

## <a name="agent-config">Puppet Agent Installation, Configuration, and Usage</a>

#### Install Puppet Agent

If needed, configure a proxy server to gain network access to `yum.puppetlabs.com`:

~~~bash
export http_proxy=http://proxy.yourdomain.com:<port>
export https_proxy=https://proxy.yourdomain.com:<port>
~~~

Import the Puppet GPG keys.

~~~
rpm --import http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
rpm --import http://yum.puppetlabs.com/RPM-GPG-KEY-reductive
~~~

The recommended Puppet RPM for IOS XR is [http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm](http://yum.puppetlabs.com/puppetlabs-release-pc1-el-6.noarch.rpm).

Using the appropriate RPM, do:

~~~bash
yum install $PUPPET_RPM
yum install puppet
~~~

Update PATH var:

~~~bash
export PATH=/opt/puppetlabs/puppet/bin:/opt/puppetlabs/puppet/lib:$PATH
~~~

#### Edit the Puppet config file:

**/etc/puppetlabs/puppet/puppet.conf**

This file can be used to override the default Puppet settings. At a minimum, the following settings should be used:

~~~bash
[main]
  server = mypuppetmaster.mycompany.com

[agent]
  pluginsync  = true
  ignorecache = true
~~~

See the following references for more puppet.conf settings:

* https://docs.puppetlabs.com/puppet/latest/reference/config_important_settings.html
* https://docs.puppetlabs.com/puppet/latest/reference/config_about_settings.html
* https://docs.puppetlabs.com/puppet/latest/reference/config_file_main.html
* https://docs.puppetlabs.com/references/latest/configuration.html

#### Run the Puppet Agent

~~~bash
puppet agent -t
~~~

#### Service Management

It may be desirable to set up automatic restart of the Puppet agent in the event of a system reset.

#### <a name="svc-mgmt-bs">Optional: bash-shell / init.d</a>

The `bash-shell` environment uses **init.d** for service management.
The Puppet agent provides a generic init.d script when installed, but a slight
modification is needed to ensure that Puppet runs in the correct namespace:

~~~diff
--- /etc/init.d/puppet.old
+++ /etc/init.d/puppet
@@ -38,7 +38,7 @@

 start() {
     echo -n $"Starting puppet agent: "
-    daemon $daemonopts $puppetd ${PUPPET_OPTS} ${PUPPET_EXTRA_OPTS}
+    daemon $daemonopts ip netns exec tpnns $puppetd ${PUPPET_OPTS} ${PUPPET_EXTRA_OPTS}
     RETVAL=$?
     echo
         [ $RETVAL = 0 ] && touch ${lockfile}
~~~

Next, enable the puppet service to be automatically started at boot time, and optionally start it now:

~~~bash
chkconfig --add puppet
chkconfig --level 345 puppet on

service puppet start
~~~

## <a name="auto-install">Automated Installation Options</a>

[Beaker](README-beaker-agent-install.md) - Installing and Configuring Puppet Agent Using the Beaker Tool

## <a name="references">References</a>

[Cisco IOS XR Application Hosting Configuration Guide](http://www.cisco.com/c/en/us/td/docs/iosxr/AppHosting/App-Hosting-Config-Guide.html)

[Cisco IOS XR Data Models Configuration Guide](http://www.cisco.com/c/en/us/td/docs/iosxr/ncs5500/DataModels/b-Datamodels-cg-ncs5500/b-Datamodels-cg-ncs5500_chapter_010.html#concept_700172ED7CF44313B0D7E521B2983F32) - gRPC Server Documentation


----
~~~
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

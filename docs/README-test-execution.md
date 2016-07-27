# Executing the Tests Provided for This Module

### Table of Contents

* [Overview](#overview)
* [Minitest Tests](#minitest)
  * [Edit or create a minitest config file](#minitest-config)
  * [Running a single minitest test](#minitest-single-test)
  * [Running a single testcase](#minitest-single-testcase)
  * [Running all minitest tests](#minitest-all)
* [Beaker Tests](#beaker)
  * [Prerequisites](#beaker-prereqs)
  * [Beaker Configuration](#beaker-config)
  * [Running a single test](#beaker-single-test)
  * [Running all Beaker tests](#beaker-all)

## <a name="overview">Overview</a>

This document describes the process for executing tests provided for the code in this Puppet module. The instructions below assume you have cloned this repository to a "test driver" workstation and will reference subdirectories under the root `cisco-yang-puppet-module` directory:

~~~
$ git clone https://github.com/cisco/cisco-yang-puppet-module.git
$ cd cisco-network-yang-module/tests
~~~

## <a name="minitest">Minitest Tests</a>

The test files located in the `tests/minitest` directory use [minitest](https://github.com/seattlerb/minitest/) as their test framework. In addition to the test driver workstation, these tests generally require a Cisco router, switch, or virtual machine to test against.  The executable minitest files are all named `test_*.rb`.

### <a name="minitest-config">Edit or create a minitest config file</a>

You must create a `cisco_yang.yaml` file on the driver workstation to specify the XR node under test. Two configuration file locations are supported:

* `/etc/cisco_yang.yaml` (system and/or root user configuration)
* `~/cisco_yang.yaml` (per-user configuration)

If both files exist and are readable, configuration in the user-specific file will take precedence over the system configuration.

This file specifies the host, port, username, and/or password to be used to connect to gRPC and/or NETCONF on the XR node. Here is an example configuration file:

~~~bash
grpc:
  host: 192.168.1.65
  port: 57400
  username: admin
  password: admin

netconf:
  host: 192.168.1.65
  username: admin
  password: admin
~~~

Each minitest file/class uses either the `grpc` client options or the `netconf` options (or neither, if the file contains only offline tests).

### <a name="minitest-single-test">Running a single minitest test</a>

You can execute a single test file by name:

```bash
$ ruby tests/test_yang.rb
$ ruby tests/test_netconf_yang.rb -v
```

### <a name="minitest-single-testcase">Running a single testcase</a>

You can execute a single testcase in a file using the '-n' or '--name' option:

```bash
$ ruby tests/test_yang.rb -n test_merge
```

### <a name="minitest-all">Running all minitest tests</a>


Using rake, you can execute all tests:

```bash
$ rake test
```


## <a name="beaker">Beaker Tests</a>

The test files located in the `tests/beaker` directory use [Beaker](https://github.com/puppetlabs/beaker) as their test framework. In addition to the test driver workstation, these tests require a Puppet Master workstation and an XR Puppet Agent device.  The executable Beaker Ruby files are in subdirectories and are named `test_*.rb`.

### <a name="beaker-prereqs">Prerequisites</a>

* [Install Beaker](https://github.com/puppetlabs/beaker/wiki/Beaker-Installation) (release 2.38.1 or later) on the driver workstation.
* [Prepare the Puppet Master](../README.md#puppet-master-setup)
* [Prepare the XR Puppet Agent](README-agent-install.md)

### <a name="beaker-config">Beaker Configuration</a>

Under the `tests/beaker_tests` directory, create file named `hosts.cfg` and add the following content:

*Replace the `< >` markers with specific information.*

```bash
HOSTS:
    <IOS XR agent>:
        roles:
            - agent
        platform: cisco_ios_xr-6-x86_64
        ip: <ip address or fully qualified domain name>
        ssh:
          auth_methods: ["password"]
          # SSHd for third-party network namespace (TPNNS) uses port 57722
          port: 57722
          user: <configured admin username>
          password: <configured admin password>


    #<agent2>:
    #  <...>

    #<agent3>:
    #  <...>

    <master>:
        # Note: Only one master configuration block allowed
        roles:
            - master
        platform: <server os-version-architecture>
        ip: <ip address or fully qualifed domain name>
        ssh:
          # Root user/password must be configured for master.
          auth_methods: ["password"]
          user: root
          password: <configured root password>
```

Here is a sample `hosts.cfg` file where the `< >` markers have been replaced with actual data.

```bash
HOSTS:
    xr-agent:
        roles:
            - agent
        platform: cisco_ios_xr-6-x86_64
        ip: xr-agent.domain.com
        ssh:
          auth_methods: ["password"]
          port: 57722
          user: admin
          password: adminpassword

    puppetmaster1:
        roles:
            - master
        platform: ubuntu-1404-x86_64
        ip: puppetmaster1.domain.com
        ssh:
          auth_methods: ["password"]
          user: root
          password: rootpassword
```

### <a name="beaker-single-test">Running a single test</a>

To run a single beaker test from the `tests/beaker_tests` directory, use the following command:

```bash
beaker --hosts hosts.cfg --test cisco_yang/test_create_vrf.rb
```

**NOTE:** This runs a `cisco_yang` test to create a vrf, but any other tests under the `tests/beaker_tests` directory can be run in the same manner.

### <a name="beaker-all">Running all Beaker tests</a>

To run all the Beaker tests from the `tests/beaker_tests` directory, use the `--test` parameter
and specify the current directory (`.`):

```bash
beaker --hosts hosts.cfg --test .
```

You can also specify a subdirectory of Beaker tests:

```bash
beaker --hosts hosts.cfg --test cisco_yang
beaker --hosts hosts.cfg --test cisco_yang_netconf
```

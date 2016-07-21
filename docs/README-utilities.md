# Utilities included in this module

## show_running_yang.rb

This is a Ruby utility to output the current state of an XR configuration. In order
to run, this utility needs access to one or more *.yang files (found in the
`/pkg/yang` directory on the XR device, as well as from other sources). Usually, this
would be run from the bash-shell on the XR device, but can be run remotely if
applicable .yang files are available. Client connection information (host, username, etc.)
is read from the standard [configuration file](README-agent-install.md#module-config).

Running `puppet agent -t` on XR caches the module source on the client, usually under the
`/opt/puppetlabs/puppet/cache` directory.  The `show_running_yang.rb` Ruby file will be
in the `/opt/puppetlabs/puppet/cache/lib/util` directory, so can be executed using the
following command:

```bash
[xrv9k:~]$ ruby /opt/puppetlabs/puppet/cache/lib/util/show_running_yang.rb --help

Usage: ruby [path]show_running_yang.rb [options] [file_or_directory_path]
    -m, --manifest                   Output config in a form suitable for inclusion in a Puppet manifest
    -o, --oper                       Retrieve operational data instead of configuration (experimental; use at own risk)
    -c, --client CLIENT              The client to use to connect.
                                     grpc|netconf (defaults to grpc
    -d, --debug                      Enable debug-level logging
    -v, --verbose                    Enable verbose messages
    -h, --help                       Print this help
```

If you find yourself running the utility often, consider creating an alias shortcut:


```bash
[xrv9k:~]$ alias show_running_yang='ruby /opt/puppetlabs/puppet/cache/lib/util/show_running_yang.rb'
[xrv9k:~]$ show_running_yang
[xrv9k:~]$ show_running_yang -c netconf /pkg/yang/Cisco-IOS-XR-ipv4-bgp-cfg.yang
```

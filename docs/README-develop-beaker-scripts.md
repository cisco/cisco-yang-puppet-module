# How To Create and Run Beaker Test Cases

#### Table of Contents

* [Overview](#overview)
* [Prerequisites](#prereqs)
* [Basic Example: new YANG model test](#new-yang-model)
  * [Completed Example](#completed-example)
    * [Reading YANG source from file](#yang-from-file)
    * [Run the test script](#run-test)

## <a name="overview">Overview</a>

This document describes the process for writing [Beaker](https://github.com/puppetlabs/beaker/blob/master/README.md) Test Cases for the `ciscoyang` Puppet module.

## <a name="prereqs">Prerequisites</a>

Refer to [README-test-execution.md](README-test-execution.md) for required setup steps for Beaker and the node(s) to be tested.

## <a name="new-yang-model">Basic Example: new YANG model test</a>

This example will demonstrate how to add a new Beaker test for a specific YANG model and container. We've chosen the Cisco-IOS-XR-ipv4-bgp-cfg:bgp model:container for this example.

* The `./examples/beaker_test_template.rb` file provides a template for simple Beaker tests; copy it into the proper test directory. It is recommended that you create a separate test file for each YANG model/container combination that you wish to test.  Name your Beaker test file as `test_`, plus the YANG model filename, plus the container (all lower-case with underscores in place of other symbols). Here, the YANG model being tested is named `Cisco-IOS-XR-ipv4-bgp-cfg.yang` and the container we are testing is the `bgp` container, so the test file will be named `test_cisco_ios_xr_ipv4_bgp_cfg_bgp.rb`.

```bash
cp examples/beaker_test_template.rb tests/beaker_tests/all/cisco_yang/model_tests/test_cisco_ios_xr_ipv4_bgp_cfg_bgp.rb
```

* Our new `test_cisco_ios_xr_ipv4_bgp_cfg_bgp.rb` requires changes from the original template. Edit `test_cisco_ios_xr_ipv4_bgp_cfg_bgp.rb` and make any necessary changes.  In particular, you will want to:

1. Update the test at line 33:
    * Change the test ID
    * Change the test description
    * Change the title to the target container in the YANG document
    * Change the source to the desired YANG configuration to test

2. Update the test ID at line 49

## <a name="completed-example">Completed Example</a>

This is the completed `test_cisco_ios_xr_ipv4_bgp_cfg_bgp.rb` test file based on `template-beaker_test_template.rb`:

~~~ruby
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
require File.expand_path('../../../lib/utilitylib.rb', __FILE__)
require File.expand_path('../../util.rb', __FILE__)

# Test hash top-level keys
tests = {
  master:        master,
  agent:         agent,
  resource_name: 'cisco_yang',
  os:            'ios_xr',
  os_version:    '6.1.1',
}

# skip entire file if os, version, etc. don't match
skip_unless_supported(tests)

# Define a test for the bgp YANG container.
tests[:bgp] = {
  desc:           'Configure BGP',
  title:          '{"Cisco-IOS-XR-ipv4-bgp-cfg:bgp": [null]}',
  manifest_props: {
    source: '{
      "Cisco-IOS-XR-ipv4-bgp-cfg:bgp":{
        "instance":[
          {
            "instance-name":"default",
            "instance-as":[
              {
                "as":0,
                "four-byte-as":[
                  {
                    "as":55,
                    "bgp-running":[null],
                    "default-vrf":{
                      "global":{
                        "nsr":false,
                        "global-timers":{
                          "keepalive":60,
                          "hold-time":120
                        },
                        "enforce-ibgp-out-policy":[null],
                        "global-afs":{
                          "global-af":[
                            {
                              "af-name":"ipv4-multicast",
                              "enable":[null],
                              "update-limit-address-family":256,
                              "ebgp":{
                                "paths-value":32,
                                "unequal-cost":false,
                                "selective":false,
                                "order-by-igp-metric":false
                              }
                            }
                          ]
                        }
                      },
                      "bgp-entity":{
                        "neighbors":{
                          "neighbor":[
                            {
                              "neighbor-address":"5.5.5.5",
                              "remote-as":{
                                "as-xx":0,
                                "as-yy":12
                              },
                              "bfd-enable-modes":"default",
                              "ebgp-multihop":{
                                "max-hop-count":10,
                                "mpls-deactivation":false
                              },
                              "description":"Neighbor A",
                              "msg-log-out":{
                                "msg-buf-count":10
                              }
                            },
                            {
                              "neighbor-address":"6.6.6.6",
                              "remote-as":{
                                "as-xx":0,
                                "as-yy":13
                              },
                              "description":"Neighbor B"
                            }
                          ]
                        }
                      }
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    }',
    mode:   'replace',
  },
}

#################################################################
# Execute the test
#################################################################

test_name 'Model Test' do
  # a simple run with pre/post clean
  # (reference our test above using the key)
  test_harness_run_clean(tests, :bgp)
end

# report on skipped tests
skipped_tests_summary(tests)
~~~

### <a name="yang-from-file">Reading YANG source from file</a>

As an alternative to putting the YANG source directly in the test file, you can read it from an external file like this:

~~~ruby
  :

# Define a test for the bgp YANG container.
tests[:bgp] = {
  desc:           'Configure BGP',
  title:          '{"Cisco-IOS-XR-ipv4-bgp-cfg:bgp": [null]}',
  manifest_props: {
    source: File.read(File.expand_path('../yang/bgp.yang', __FILE__)),
    mode:   'replace',
  },
}

  :
~~~

**Note: You can find some example model test scripts in the `tests/beaker_tests/all/cisco_yang/model_tests` directory.**

### <a name="run-test">Run the test script</a>

Refer to [README-test-execution.md](README-test-execution.md#beaker) for information on running Beaker tests.  From the `tests/beaker_tests/all` directory:

```bash
beaker --hosts hosts.cfg --test cisco_yang/model_tests/test_cisco_ios_xr_ipv4_bgp_cfg_bgp.rb
```

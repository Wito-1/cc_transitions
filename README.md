# cc_transitions

This repository provides some capabilities to wrap around `with_cfg.bzl` and provides a single `cc_*()` macro that has some additional attributes you can specify to generate additional targets for additional configurations. The additional macro targets are suffixed with `-<platform>.<config>`.

** NOTE ** Currently this only generates `cc_test()` targets.

First step is to write a `transitions_cfg.yaml` that can be used to specify what are the additional transition configurations you want to generate. See the one in this directory or the e2e directory for examples of how to write.


See the `e2e` directory for a full end to end example

## Usage

In your `MODULE.bazel` file:

```
# Specify the cc_transitions version to use
http_archive(
    name = "cc_transitions",
    sha256 = "...",
    url = "...",
    strip_prefix = "...",
)

# Provide the `transitions_cfg.yaml` to define the various transitions to use
cc_transitions = use_extension("@cc_transitions//extensions:cc_transitions.bzl", "cc_transitions", dev_dependency=True)

cc_transitions.install(
    name = "rules_cc_transitions",
    configuration = "//:transitions_cfg.yaml",
)
use_repo(cc_transitions, "rules_cc_transitions")
```

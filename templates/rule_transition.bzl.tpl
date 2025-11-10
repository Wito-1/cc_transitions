# Load from generated repository the rule builder

load("//:rule_builder.bzl", "rule_builder")
#load("@{{GENENRATED_REPO}}//:rule_builder.bzl", "rule_builder")

# Load the rule to wrap around
# TODO: make this configurable?
# load("{{BZL}}", "{{RULE}}")
load("@rules_cc//cc:defs.bzl", "{{RULE}}")

{{RULE_NAME}}, _{{RULE_NAME}}_internal = rule_builder(
    function = {{RULE}},
    compilation_mode = "{{COMPILATION_MODE}}",
    platform = "{{PLATFORM}}",
    copts = {{COPTS}},
    linkopts = {{LINKOPTS}},
    extra_flags = {{EXTRA_FLAGS}},
)

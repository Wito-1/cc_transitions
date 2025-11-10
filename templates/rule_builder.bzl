# This function is used to build out the transition rules
load("@with_cfg.bzl", "with_cfg")

def rule_builder(function, platform = None, compilation_mode = None, copts = [], linkopts = [], extra_flags = {}):
    builder = with_cfg(function)
    
    if compilation_mode:
        builder.set("compilation_mode", compilation_mode)

    if platform:
        builder.set("platforms", platform)

    builder.extend("copt", copts)
    builder.extend("linkopt", linkopts)

    for flag, value in extra_flags.items():
      if type(value) == list:
          builder.extend(flag, value)
      else:
          builder.set(flag, value)

    transitioned_rule, _internal_rule = builder.build()
    return transitioned_rule, _internal_rule

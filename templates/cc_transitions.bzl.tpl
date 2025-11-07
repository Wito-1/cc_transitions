##
# Load all the various rules
##

load("@rules_cc//cc:defs.bzl", _cc_test = "cc_test")
{{LOAD_RULES}}

#
# Create a nested mapping of {platform: {cfg: rule}}
#
_PLATFORM_CC_RULES = {{MAPPING}}


def _get_name(name, platform, cfg):
    if platform:
      name = "{}-{}".format(name, platform)
    if cfg:
      name = "{}.{}".format(name, cfg)
    return name


def _get_platform_cc_rule(rule_type, platform, config):
    if platform not in _PLATFORM_CC_RULES[rule_type]:
        fail("Unrecognized or unsupported target platform: {}".format(platform))
    elif config not in _PLATFORM_CC_RULES[rule_type][platform]:
        fail("Unrecognized or unsupported target config: {}, supported configs for {}:\n{}".format(config, platform, "\n".join(_PLATFORM_CC_RULES[rule_type][platform])))
    else:
        return _PLATFORM_CC_RULES[rule_type][platform][config]


def cc_test(name, platforms = [], cfgs = [], **kwargs):
    _platform_cc_test = _get_platform_cc_rule(rule_type = "test", platform = "", config = "")
    for platform in [""] + [Label(platform).name for platform in platforms]:
        for cfg in [""] + cfgs:
            _platform_cc_test = _get_platform_cc_rule(rule_type = "test", platform = platform, config = cfg)
            new_name = _get_name(name, platform, cfg)
            _kwargs = kwargs | {"name": new_name}
            _platform_cc_test(**_kwargs)

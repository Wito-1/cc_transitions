load("//repo_rules:transition_rules.bzl", "transition_rules")

def _cc_transitions_impl(mctx):
    for mod in mctx.modules:
        for arg in mod.tags.install:
            transition_rules(
                name = arg.name,
                configuration = arg.configuration,
            )
            
_install = tag_class(
    attrs = {
        "name": attr.string(
            mandatory = True,
            doc = "Name of the external repository to create",
        ),
        "configuration": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Configuration yaml file for which transitions to create",
        ),
    },
)

_tag_classes = {
    "install": _install,
}

cc_transitions = module_extension(
    implementation = _cc_transitions_impl,
    tag_classes = _tag_classes,
)

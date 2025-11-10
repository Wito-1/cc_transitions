def _transition_rules_impl(rctx):
    yaml_path = rctx.attr.configuration
    yaml_contents = rctx.read(yaml_path)

    yq_path = rctx.which("yq")
    if not yq_path:
        fail("Could not find `yq` on PATH. Install yq or add it to PATH.")

    # Run `yq` to convert YAML -> JSON
    result = rctx.execute(
        [yq_path, "-o=json", yaml_path],
        quiet = True,
    )

    if result.return_code != 0:
        fail("yq failed: %s" % result.stderr)

    # Parse JSON for Starlark consumers
    parsed = json.decode(result.stdout)

    build_configs = parsed["build_configurations"]

    generated_files = []
    cc_rule = "cc_test"
    generated_rules_mapping = {
        "test": {
            "": {
                "": "_{}".format(cc_rule)
            }
        }
    }
    for config in build_configs:
        substitutions = {
            "{{RULE}}": cc_rule,
        }
        platform = config.get("platform", "")
        copts = config.get("copts", [])
        linkopts = config.get("linkopts", [])
        compilation_mode = config.get("compilation_mode", "")
        extra_bazel_flags = config.get("extra_bazel_flags", {})
        
        prefix = config["name"]
        if platform:
           platform = Label(platform)
           platform_name = Label(platform).name
           if prefix:
               prefix += "_"
           prefix += "{}".format(platform_name)
        else:
           platform_name = ""
           platform = ""
        rule_name = "{}_{}".format(prefix, cc_rule).replace("-", "_")

        if platform_name in generated_rules_mapping["test"]:
            generated_rules_mapping["test"][platform_name].update({str(config["name"]): rule_name})
        else:
            generated_rules_mapping["test"].update({platform_name: {str(config["name"]): rule_name}})

        substitutions.update({
            "{{RULE_NAME}}": rule_name,
            "{{COMPILATION_MODE}}": compilation_mode,
            "{{PLATFORM}}": str(platform),
            "{{COPTS}}": str(copts),
            "{{LINKOPTS}}": str(linkopts),
            "{{EXTRA_FLAGS}}": str(extra_bazel_flags),
        })

        rule_file = "{}.bzl".format(prefix)
        rctx.template(
            rule_file,
            rctx.attr._transition_rule_template,
            substitutions = substitutions,
        )

        generated_files.append({rule_file: rule_name})

    content = ""
    for rule_file_name in generated_files:
        for file, rname in rule_file_name.items():
            content += "load(\"//:{}\", _{} = \"{}\")\n".format(file, rname, rname)
    cc_rule_file = "cc_transitions.bzl"
    content += "load(\"//:{}\", _{} = \"{}\")\n".format(cc_rule_file, cc_rule, cc_rule)

    content += "\n"

    for rule_file_name in generated_files:
        for file, rname in rule_file_name.items():
            content += "{} = _{}\n".format(rname, rname)
    content += "{} = _{}\n".format(cc_rule, cc_rule)

    cc_transition_content = ""
    cc_transition_mapping = {"test": {}}
    for rule_file_name in generated_files:
        for file, rname in rule_file_name.items():
            cc_transition_content += "load(\"//:{}\", \"{}\")\n".format(file, rname)

    dict_string = json.encode_indent(generated_rules_mapping)
    raw_string = ""
    for line in dict_string.split("\n"):
        if ":" in line:
            parts = line.split(":")
            raw_string += "{}:{}\n".format(parts[0], parts[1].replace('"', ""))
        else:
            raw_string += "{}\n".format(line)

    substitutions = {
        "{{LOAD_RULES}}": cc_transition_content,
        "{{MAPPING}}": raw_string,
    }
    rctx.template(
        cc_rule_file,
        rctx.attr._cc_transition_template,
        substitutions = substitutions,
    )

    rctx.file("defs.bzl", content = content)
    rctx.file("BUILD.bazel", content = "")
    rctx.file("MODULE.bazel", content = 'bazel_dep(name = "rules_cc", version = "0.2.14")')
    rctx.symlink(rctx.attr._rule_builder, rctx.attr._rule_builder.name)
    rctx.repo_metadata(reproducible=True)



transition_rules = repository_rule(
    implementation = _transition_rules_impl,
    attrs = {
        "configuration": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_transition_rule_template": attr.label(
            allow_single_file = True,
            default = Label("@//templates:rule_transition.bzl.tpl")
        ),
        "_rule_builder": attr.label(
            allow_single_file = True,
            default = Label("@//templates:rule_builder.bzl")
        ),
        "_cc_transition_template": attr.label(
            allow_single_file = True,
            default = Label("@//templates:cc_transitions.bzl.tpl")
        ),
    },
)

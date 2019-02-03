load( "@bazel_skylib//lib:shell.bzl", "shell")


load("@bazel_skylib//lib:paths.bzl", "paths")


def _bash_file_rule_impl(ctx):
    print(ctx.bin_dir.path)
    source_file = ctx.attr.dep.files.to_list()[0]
    out_file = ctx.actions.declare_file(ctx.label.name) 
    
    substitutions = {
        "@@SOURCE@@": shell.quote(str(source_file.path)),
        "@@DESTINATION@@": shell.quote(ctx.attr.dest),
        "@@GENERATED_MESSAGE@@": """
# Generated by {label}
# DO NOT EDIT
""".format(label = str(ctx.label)),
    }
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out_file,
        substitutions = substitutions,
        is_executable = True,
    )
    return [DefaultInfo(
        files = depset([out_file]),
        executable = out_file,
    )]

_bash_file_rule = rule(
    implementation = _bash_file_rule_impl,
    attrs = {
        "dep": attr.label(mandatory = True),
        "dest": attr.string(mandatory = True),
        "_template": attr.label(
            default = "@rules_copy//:template.bash.in",
            allow_single_file = True,
        ),
    },
    executable = True,
)

def copy_to_source(name, dep, dest):
    bash_file_gen = name + "-bash-file-gen-rule"
    _bash_file_rule(
        name = bash_file_gen,
        dep = dep,
        dest = dest,
    )
    native.sh_binary(
        name = name,
        srcs = [
            bash_file_gen,
        ],
        data = ["BUILD"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
    )
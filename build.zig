const builtin = @import("builtin");
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const glfw_dep = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
    });

    const c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.c"),
        .target = target,
        .optimize = optimize,
    });
    c.addIncludePath(glfw_dep.artifact("glfw").getEmittedIncludeTree());
    const c_mod = c.createModule();

    var module = b.addModule("mach_glfw", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
        .imports = &.{
            .{ .name = "c", .module = c_mod },
        },
    });
    module.linkLibrary(glfw_dep.artifact("glfw"));

    const test_step = b.step("test", "Run library tests");
    const main_tests = b.addTest(.{
        .name = "glfw_tests",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("src/main.zig"),
            .imports = &.{
                .{ .name = "c", .module = c_mod },
            },
        }),
    });
    main_tests.root_module.linkLibrary(glfw_dep.artifact("glfw"));
    b.installArtifact(main_tests);
    test_step.dependOn(&b.addRunArtifact(main_tests).step);

    if (target.result.isDarwinLibC()) {
        if (glfw_dep.builder.lazyDependency("xcode_frameworks", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            module.addSystemFrameworkPath(dep.path("Frameworks"));
            module.addSystemIncludePath(dep.path("include"));
            module.addLibraryPath(dep.path("lib"));

            main_tests.root_module.addSystemFrameworkPath(dep.path("Frameworks"));
            main_tests.root_module.addSystemIncludePath(dep.path("include"));
            main_tests.root_module.addLibraryPath(dep.path("lib"));
        }
    }
}

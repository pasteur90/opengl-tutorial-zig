const Builder = @import("std").build.Builder;

const cflags = [_][]const u8{};

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("tut01", "src/main.zig");
    exe.addCSourceFile("../src/gl3w.c", &cflags);
    exe.addLibPath("/usr/lib64");
    exe.addIncludeDir("../include");
    exe.linkSystemLibrary("glfw3");
    exe.linkSystemLibrary("c");
    exe.addPackagePath("shader", "../common/shader.zig");
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

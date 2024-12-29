const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const projects: []const Project = &.{
        // RaspberryPi Boards:
        .{ .target = mb.ports.rp2xxx.boards.raspberrypi.pico, .name = "lightshow", .file = "src/lightshow.zig" },
    };

    var available_projects = std.ArrayList(Project).init(b.allocator);
    available_projects.appendSlice(projects) catch @panic("out of memory");

    for (available_projects.items) |project| {
        // `add_firmware` basically works like addExecutable, but takes a
        // `microzig.Target` for target instead of a `std.zig.CrossTarget`.
        //
        // The target will convey all necessary information on the chip,
        // cpu and potentially the board as well.
        const firmware = mb.add_firmware(.{
            .name = project.name,
            .target = project.target,
            .optimize = optimize,
            .root_source_file = b.path(project.file),
        });

        // `install_firmware()` is the MicroZig pendant to `Build.installArtifact()`
        // and allows installing the firmware as a typical firmware file.
        //
        // This will also install into `$prefix/firmware` instead of `$prefix/bin`.
        mb.install_firmware(firmware, .{});

        // For debugging, we also always install the firmware as an ELF file
        mb.install_firmware(firmware, .{ .format = .elf });
    }
}

const Project = struct {
    target: *const microzig.Target,
    name: []const u8,
    file: []const u8,
};

const std = @import("std");
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("GL/gl3w.h");
});

fn readFile(allocator: *Allocator, filename: []const u8) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{});
    var stat = try file.stat();
    // TODO: return error when file size 0
    const in_stream = std.io.bufferedInStream(file.inStream()).inStream();
    var str = try in_stream.readAllAlloc(allocator, stat.size);

    return str;
}

pub fn loadShaders(vertex_file_path: []const u8, fragment_file_path: []const u8) !c.GLuint {
    const allocator = std.heap.page_allocator;

    const vertex_file = try readFile(allocator, vertex_file_path);
    defer allocator.free(vertex_file);

    const fragment_file = try readFile(allocator, fragment_file_path);
    defer allocator.free(fragment_file);

    var result: c.GLint = undefined;
    var infoLogLength: c_int = undefined;

    var vertexShaderId = c.glCreateShader(c.GL_VERTEX_SHADER);
    var fragmentShaderId = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    warn("compiling vertex shader: {}\n", .{vertex_file_path});
    var vertex_array = [_][*]const u8{vertex_file.ptr};
    c.glShaderSource(vertexShaderId, 1, &vertex_array, null);
    c.glCompileShader(vertexShaderId);

    c.glGetShaderiv(vertexShaderId, c.GL_COMPILE_STATUS, &result);
    c.glGetShaderiv(vertexShaderId, c.GL_INFO_LOG_LENGTH, &infoLogLength);
    if (infoLogLength > 0) {
        var logStr = try allocator.allocSentinel(u8, @intCast(usize, infoLogLength), 0);
        defer allocator.free(logStr);
        c.glGetShaderInfoLog(vertexShaderId, infoLogLength, null, logStr.ptr);
        warn("error compiling shader: {}\n", .{logStr});
    }

    warn("compiling fragment shader: {}\n", .{fragment_file_path});
    var fragment_array = [_][*]const u8{fragment_file.ptr};
    c.glShaderSource(fragmentShaderId, 1, &fragment_array, null);
    c.glCompileShader(fragmentShaderId);

    c.glGetShaderiv(fragmentShaderId, c.GL_COMPILE_STATUS, &result);
    c.glGetShaderiv(fragmentShaderId, c.GL_INFO_LOG_LENGTH, &infoLogLength);
    if (infoLogLength > 0) {
        var logStr = try allocator.allocSentinel(u8, @intCast(usize, infoLogLength), 0);
        defer allocator.free(logStr);
        c.glGetShaderInfoLog(fragmentShaderId, infoLogLength, null, logStr.ptr);
        warn("error compiling shader: {}\n", .{logStr});
    }

    warn("linking program\n", .{});
    var programId = c.glCreateProgram();
    c.glAttachShader(programId, vertexShaderId);
    c.glAttachShader(programId, fragmentShaderId);
    c.glLinkProgram(programId);

    c.glGetProgramiv(programId, c.GL_LINK_STATUS, &result);
    c.glGetProgramiv(programId, c.GL_INFO_LOG_LENGTH, &infoLogLength);
    if (infoLogLength > 0) {
        var logStr = try allocator.allocSentinel(u8, @intCast(usize, infoLogLength), 0);
        defer allocator.free(logStr);
        c.glGetShaderInfoLog(programId, infoLogLength, null, logStr.ptr);
        warn("error linking program: {}\n", .{logStr});
    }

    c.glDetachShader(programId, vertexShaderId);
    c.glDetachShader(programId, fragmentShaderId);

    c.glDeleteShader(vertexShaderId);
    c.glDeleteShader(fragmentShaderId);

    return programId;
}

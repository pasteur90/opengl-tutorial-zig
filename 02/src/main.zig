const std = @import("std");
const warn = std.debug.warn;

const c = @cImport({
    @cInclude("GL/gl3w.h");
    @cInclude("GLFW/glfw3.h");
});

usingnamespace @import("shader");

pub fn main() !u8 {
    if (c.glfwInit() == 0) {
        warn("failed to initialize c.glfw\n", .{});
        return 255;
    }

    c.glfwWindowHint(c.GLFW_SAMPLES, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    var _window: ?*c.GLFWwindow = undefined;
    _window = c.glfwCreateWindow(1024, 768, "Tutorial 01", null, null).?;
    if (_window == null) {
        warn("failed to open a window", .{});
        c.glfwTerminate();
        return 255;
    }

    var window = _window.?;
    c.glfwMakeContextCurrent(window);
    // c.glewExperimental = 1;
    // if (c.glewInit() != c.GLEW_OK) {
    if (c.gl3wInit() != 0) {
        warn("failed to initialize gl3w\n", .{});
        return 255;
    }

    if (c.gl3wIsSupported(3, 3) == 0) {
        warn("OpenGL 3.3 not supported\n", .{});
        return 255;
    }

    c.glfwSetInputMode(window, c.GLFW_STICKY_KEYS, c.GL_TRUE);
    c.glClearColor(0.0, 0.0, 0.4, 0.0);

    var vertexArrayId: c.GLuint = undefined;
    c.glGenVertexArrays(1, &vertexArrayId);
    c.glBindVertexArray(vertexArrayId);

    var programId = try loadShaders("src/SimpleVertexShader.vertexshader", "src/SimpleFragmentShader.fragmentshader");

    const vertexBufferData = [_]c.GLfloat{
        -1.0, -1.0, 0.0,
        1.0,  -1.0, 0.0,
        0.0,  1.0,  0.0,
    };

    var vertexBuffer: c.GLuint = undefined;
    c.glGenBuffers(1, &vertexBuffer);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vertexBuffer);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertexBufferData)), &vertexBufferData, c.GL_STATIC_DRAW);

    var do_quit = false;
    while (!do_quit) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glUseProgram(programId);

        c.glEnableVertexAttribArray(0);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vertexBuffer);
        c.glVertexAttribPointer(0, // attribute 0. No particular reason for 0, but must match the layout in the shader
            3, // size
            c.GL_FLOAT, // type
            c.GL_FALSE, // normalized?
            0, // stride
            null // array buffer offset
        );

        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glDisableVertexAttribArray(0);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
        do_quit = c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS and
            c.glfwWindowShouldClose(window) == 0;
    }

    return 0;
}

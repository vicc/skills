// MIT License — see the repository LICENSE.
// Native macOS reference capture, using deprecated OpenGL solely to execute
// original GLSL for comparison. This is not the Apple app implementation.
// Build: xcrun clang++ -std=c++17 -fobjc-arc render-glsl.mm -framework OpenGL \
//        -framework Foundation -framework CoreGraphics -framework ImageIO -o render-glsl
#define GL_SILENCE_DEPRECATION
#import <Foundation/Foundation.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

struct Options {
    std::string source, output, textures[2];
    int width = 640, height = 400;
    float time = 1.25f;
};

static void usage() {
    std::cout << "Usage: render-glsl effect.glsl output.png [--width 640] [--height 400] "
                 "[--time 1.25] [--texture0 source.png] [--texture1 source.png]\n";
}

static Options options(int argc, char **argv) {
    if (argc < 3) throw std::runtime_error("Expected a GLSL source path and PNG output path.");
    Options o;
    o.source = argv[1]; o.output = argv[2];
    for (int i = 3; i < argc; i += 2) {
        if (i + 1 >= argc) throw std::runtime_error("Missing value for " + std::string(argv[i]));
        const std::string key = argv[i], value = argv[i + 1];
        size_t consumed = 0;
        if (key == "--width" || key == "--height") {
            int number = std::stoi(value, &consumed);
            if (consumed != value.size() || number < 1 || number > 8192)
                throw std::runtime_error("Dimensions must be integers between 1 and 8192.");
            (key == "--width" ? o.width : o.height) = number;
        } else if (key == "--time") {
            o.time = std::stof(value, &consumed);
            if (consumed != value.size() || !std::isfinite(o.time))
                throw std::runtime_error("Time must be a finite number.");
        } else if (key == "--texture0") o.textures[0] = value;
        else if (key == "--texture1") o.textures[1] = value;
        else throw std::runtime_error("Unknown option: " + key);
    }
    return o;
}

static std::string readText(const std::string &path) {
    std::ifstream input(path);
    if (!input) throw std::runtime_error("Cannot read GLSL source: " + path);
    return { std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>() };
}

struct Context {
    CGLContextObj value = nullptr;
    Context() {
        CGLPixelFormatAttribute attributes[] = {
            kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
            kCGLPFAAccelerated, (CGLPixelFormatAttribute)0
        };
        CGLPixelFormatObj format = nullptr;
        GLint count = 0;
        CGLError error = CGLChoosePixelFormat(attributes, &format, &count);
        if (error != kCGLNoError || !format)
            throw std::runtime_error("No accelerated CGL core context: " + std::string(CGLErrorString(error)));
        error = CGLCreateContext(format, nullptr, &value);
        CGLDestroyPixelFormat(format);
        if (error != kCGLNoError || !value)
            throw std::runtime_error("CGLCreateContext: " + std::string(CGLErrorString(error)));
        error = CGLSetCurrentContext(value);
        if (error != kCGLNoError) {
            CGLDestroyContext(value); value = nullptr;
            throw std::runtime_error("CGLSetCurrentContext: " + std::string(CGLErrorString(error)));
        }
    }
    ~Context() { if (value) { CGLSetCurrentContext(nullptr); CGLDestroyContext(value); } }
};

static void checkGL(const char *stage) {
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        std::ostringstream message;
        message << stage << " failed with OpenGL error 0x" << std::hex << error;
        throw std::runtime_error(message.str());
    }
}

static GLuint compile(GLenum type, const std::string &source) {
    GLuint shader = glCreateShader(type);
    const GLchar *text = source.c_str();
    glShaderSource(shader, 1, &text, nullptr);
    glCompileShader(shader);
    GLint compiled = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint size = 0; glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &size);
        std::vector<char> log(static_cast<size_t>(std::max(1, size)));
        glGetShaderInfoLog(shader, size, nullptr, log.data());
        glDeleteShader(shader);
        throw std::runtime_error("GLSL compile error:\n" + std::string(log.data()));
    }
    return shader;
}

static GLuint makeProgram(const std::string &effect) {
    const std::string vertex = R"GLSL(#version 330 core
void main() {
    vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}
)GLSL";
    const std::string fragment = R"GLSL(#version 330 core
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
out vec4 comparisonColor;
#line 1
)GLSL" + effect + "\nvoid main() { mainImage(comparisonColor, gl_FragCoord.xy); }\n";
    GLuint vs = compile(GL_VERTEX_SHADER, vertex);
    GLuint fs = compile(GL_FRAGMENT_SHADER, fragment);
    GLuint program = glCreateProgram();
    glAttachShader(program, vs); glAttachShader(program, fs); glLinkProgram(program);
    glDeleteShader(vs); glDeleteShader(fs);
    GLint linked = GL_FALSE; glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint size = 0; glGetProgramiv(program, GL_INFO_LOG_LENGTH, &size);
        std::vector<char> log(static_cast<size_t>(std::max(1, size)));
        glGetProgramInfoLog(program, size, nullptr, log.data());
        glDeleteProgram(program);
        throw std::runtime_error("GLSL link error:\n" + std::string(log.data()));
    }
    return program;
}

struct Pixels {
    size_t width, height;
    std::vector<uint8_t> bytes;
};

static Pixels loadPNG(const std::string &path) {
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path.c_str()]];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nullptr);
    if (!source) throw std::runtime_error("Cannot read texture: " + path);
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, nullptr);
    CFRelease(source);
    if (!image) throw std::runtime_error("Cannot decode texture: " + path);
    Pixels result{CGImageGetWidth(image), CGImageGetHeight(image), {}};
    if (!result.width || !result.height || result.width > 8192 || result.height > 8192) {
        CGImageRelease(image);
        throw std::runtime_error("Texture dimensions must be between 1 and 8192.");
    }
    result.bytes.resize(result.width * result.height * 4);
    // Preserve source-space channel values. Supplied fixtures are opaque RGB
    // PNGs, so premultiplication is identity. No texture sRGB decode is enabled.
    CGColorSpaceRef space = CGImageGetColorSpace(image);
    CGColorSpaceRef fallback = nullptr;
    if (!space || CGColorSpaceGetModel(space) != kCGColorSpaceModelRGB) {
        fallback = CGColorSpaceCreateWithName(kCGColorSpaceSRGB); space = fallback;
    }
    CGContextRef bitmap = CGBitmapContextCreate(result.bytes.data(), result.width, result.height,
        8, result.width * 4, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    if (fallback) CGColorSpaceRelease(fallback);
    if (!bitmap) { CGImageRelease(image); throw std::runtime_error("Cannot allocate texture bitmap."); }
    CGContextSetBlendMode(bitmap, kCGBlendModeCopy);
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationNone);
    // With no transform, byte row zero is the PNG's top row. Both backends use
    // this same ImageIO/CGContext path, then upload bytes without a vertical flip.
    CGContextDrawImage(bitmap, CGRectMake(0, 0, result.width, result.height), image);
    CGContextRelease(bitmap); CGImageRelease(image);
    for (size_t a = 3; a < result.bytes.size(); a += 4)
        if (result.bytes[a] != 255)
            throw std::runtime_error("Comparison input textures must be opaque: " + path);
    return result;
}

static void savePNG(const std::string &path, const Pixels &pixels) {
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path.c_str()]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:[url URLByDeletingLastPathComponent]
            withIntermediateDirectories:YES attributes:nil error:&error])
        throw std::runtime_error("Cannot create output directory: " + std::string(error.localizedDescription.UTF8String));
    CFDataRef data = CFDataCreate(nullptr, pixels.bytes.data(), pixels.bytes.size());
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    // Raw RGBA framebuffer values are encoded as straight alpha, without an
    // implicit unpremultiply. Current comparison effects all return alpha one.
    CGImageRef image = CGImageCreate(pixels.width, pixels.height, 8, 32, pixels.width * 4,
        space, kCGImageAlphaLast | kCGBitmapByteOrder32Big, provider, nullptr, false, kCGRenderingIntentDefault);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)url,
        CFSTR("public.png"), 1, nullptr);
    if (!image || !destination) {
        if (image) CGImageRelease(image);
        if (destination) CFRelease(destination);
        CGColorSpaceRelease(space); CGDataProviderRelease(provider); CFRelease(data);
        throw std::runtime_error("Cannot create PNG output: " + path);
    }
    CGImageDestinationAddImage(destination, image, nullptr);
    bool ok = CGImageDestinationFinalize(destination);
    CFRelease(destination); CGImageRelease(image); CGColorSpaceRelease(space);
    CGDataProviderRelease(provider); CFRelease(data);
    if (!ok) throw std::runtime_error("Cannot write PNG output: " + path);
}

static void render(const Options &o) {
    Context context;
    std::cout << "Renderer: " << glGetString(GL_RENDERER) << "\nOpenGL: " << glGetString(GL_VERSION)
              << "\nGLSL: " << glGetString(GL_SHADING_LANGUAGE_VERSION) << '\n';
    GLuint program = makeProgram(readText(o.source));
    glUseProgram(program);
    glUniform2f(glGetUniformLocation(program, "iResolution"), float(o.width), float(o.height));
    glUniform1f(glGetUniformLocation(program, "iTime"), o.time);
    GLuint output = 0, framebuffer = 0, vao = 0, textures[2] = {};
    glGenTextures(1, &output); glBindTexture(GL_TEXTURE_2D, output);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, o.width, o.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glGenFramebuffers(1, &framebuffer); glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, output, 0);
    glDrawBuffer(GL_COLOR_ATTACHMENT0); glReadBuffer(GL_COLOR_ATTACHMENT0);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        throw std::runtime_error("RGBA8 framebuffer is incomplete.");
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1); glPixelStorei(GL_PACK_ALIGNMENT, 1);
    for (int unit = 0; unit < 2; ++unit) {
        const std::string name = "iChannel" + std::to_string(unit);
        const GLint location = glGetUniformLocation(program, name.c_str());
        if (o.textures[unit].empty()) {
            if (location >= 0) throw std::runtime_error(name + " requires --texture" + std::to_string(unit));
            continue;
        }
        Pixels texture = loadPNG(o.textures[unit]);
        glActiveTexture(GL_TEXTURE0 + unit); glGenTextures(1, &textures[unit]);
        glBindTexture(GL_TEXTURE_2D, textures[unit]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, GLsizei(texture.width), GLsizei(texture.height),
                     0, GL_RGBA, GL_UNSIGNED_BYTE, texture.bytes.data());
        glUniform1i(location, unit);
    }
    glDisable(GL_BLEND); glDisable(GL_DITHER); glDisable(GL_FRAMEBUFFER_SRGB);
    glDisable(GL_DEPTH_TEST); glDisable(GL_STENCIL_TEST); glDisable(GL_SCISSOR_TEST);
    glDisable(GL_MULTISAMPLE); glDisable(GL_CULL_FACE);
    glViewport(0, 0, o.width, o.height);
    glGenVertexArrays(1, &vao); glBindVertexArray(vao);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    checkGL("Drawing GLSL");
    Pixels bottomUp{size_t(o.width), size_t(o.height), std::vector<uint8_t>(size_t(o.width) * o.height * 4)};
    glReadPixels(0, 0, o.width, o.height, GL_RGBA, GL_UNSIGNED_BYTE, bottomUp.bytes.data());
    checkGL("Reading GLSL framebuffer");
    Pixels topDown{bottomUp.width, bottomUp.height, std::vector<uint8_t>(bottomUp.bytes.size())};
    const size_t rowBytes = topDown.width * 4;
    for (size_t y = 0; y < topDown.height; ++y)
        std::memcpy(topDown.bytes.data() + y * rowBytes,
                    bottomUp.bytes.data() + (topDown.height - 1 - y) * rowBytes, rowBytes);
    savePNG(o.output, topDown);
    glDeleteVertexArrays(1, &vao); glDeleteFramebuffers(1, &framebuffer);
    glDeleteTextures(1, &output); glDeleteTextures(2, textures); glDeleteProgram(program);
    std::cout << "Captured " << o.width << 'x' << o.height << " at t=" << o.time << " to " << o.output << '\n';
}

int main(int argc, char **argv) {
    @autoreleasepool {
        if (argc == 2 && std::string(argv[1]) == "--help") { usage(); return 0; }
        try { render(options(argc, argv)); return 0; }
        catch (const std::exception &error) {
            std::cerr << "render-glsl: " << error.what() << '\n'; usage(); return 1;
        }
    }
}

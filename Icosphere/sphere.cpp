#include <vector>
#include <map>
#include <cstdlib>

#define GL_GLEXT_PROTOTYPES 1
#define GLM_ENABLE_EXPERIMENTAL

#ifdef __linux__
#include <GL/gl.h>
#include <GL/glext.h>
#include <GL/glu.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#elif _WIN32
#pragma comment(lib, "glew32.lib")
#include <GL/glew.h>
#include <SDL.h>
#include <SDL_opengl.h>
#endif

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/euler_angles.hpp>
#include <glm/gtc/type_ptr.hpp>

using namespace glm;
using namespace std;

static const GLchar* vertex_source =
    "#version 130\n"
    "in vec3 vertex;\n"
    "in vec3 norm;\n"
	"out vec3 FragPos;\n"
	"out vec3 Normal;\n"
    "uniform float time;\n"
    "uniform mat4 model;\n"
    "uniform mat4 view;\n"
    "uniform mat4 projection;\n"
    "void main()\n"
    "{\n"
    "   FragPos = vec3(model * vec4(vertex, 1.0));\n"
    "   Normal = norm;\n"
    "   vec3 v = vertex;\n"
    //"   v.z *= sin(time);\n"
    "   gl_Position = projection * view * model * vec4(v.xyz, 1.0);\n"
    "}";

static const GLchar* fragment_source =
    "#version 130\n"
    "out vec4 FragColor;\n"
    "in vec3 Normal;\n"
    "in vec3 FragPos;\n"
    "uniform vec3 lightPos;\n"
    "uniform vec3 lightColor;\n"
    "uniform vec3 objectColor;\n"
    "void main()\n"
    "{\n"
    //"   FragColor = vec4(1.0);\n"
    "   /* ambient */\n"
    "   float ambientStrength = 0.75;\n"
    "   vec3 ambient = ambientStrength * lightColor;\n"
    "\n"
    "   /* diffuse */\n"
    "   vec3 norm = normalize(Normal);\n"
    "   vec3 lightDir = normalize(lightPos - FragPos);\n"
    "   float diff = max(dot(norm, lightDir), 0.0);\n"
    "   vec3 diffuse = diff * lightColor;\n"
    "\n"
    "   vec3 result = (ambient + diffuse) * objectColor;\n"
    "   FragColor = vec4(result, 1.0);\n"
    "}";

class Shader {
    public:
        Shader();
        Shader(const char* vert_source, const char* frag_source);
        void use();
        void destroy();
        GLuint get_attrib_loc(const char* name);
        void set_uniform_1f(const char* name, float v);
        void set_uniform_3f(const char* name, float x, float y, float z);
        void set_uniform_3fv(const char* name, glm::vec3 vec);
        void set_uniform_mat4fv(const char* name, glm::mat4 matrix);

    protected:
        GLuint compile_shader(const char* src, int type);

        GLuint vert_shader;
        GLuint frag_shader;
        GLuint shader_prog;
};

enum CameraDir {
    FORWARD, BACKWARD, RIGHT, LEFT
};

enum CameraMode {
    FPS, ARCBALL
};

class Camera {
    public:
        Camera();
        Camera(int screen_x, int screen_y);
        Camera(int screen_x, int screen_y, CameraMode mode);

        /* using x, y position to orient where one looks in 3D-space */
        void look(int x, int y);

        /* zooming in and out of where one looks in 3D-space */
        void zoom(int increment);

        /* move camera across the 3D space along a 2D plane */
        void move(CameraDir dir, float delta);

        /* projection matrix (where field of view is setup) */
        glm::mat4 projection();

        /* the view the camera has in 3D space */
        glm::mat4 view();

        /* set the current mode of the camera */
        void set_mode(CameraMode mode);

        /* set initial view of camera for FPS or orbiting position for ARCBALL */
        void lookat(glm::vec3 pos, float zoom);

        /* get the current position of the camera */
        glm::vec3 pos();

        int screen_x;
        int screen_y;

    protected:
        void fps_look(int x, int y);
        void arc_look(int x, int y);

        void fps_move(CameraDir dir, float delta);
        void arc_move(CameraDir dir, float delta);

        glm::mat4 fps_view();
        glm::mat4 arc_view();

        CameraMode mode;

        float fps_yaw;
        float fps_pitch;
        float arc_yaw;
        float arc_pitch;
        float fov;
        float zoomf;

        glm::vec4 target;
        /* position in 3d space for the camera for each mode */
        glm::vec4 fps_position;
        glm::vec4 arc_position;
        glm::vec3 front; /* where the camera is looking in 3d space */
        glm::vec3 up; /* a normal pointing up to normalize movement on 2d plane */
        glm::vec4 lefthand; /* vector for left-handed coordinate system */
};

Shader::Shader()
    : vert_shader(0)
    , frag_shader(0)
      , shader_prog(0)
{ }

Shader::Shader(const char* vert_source, const char* frag_source)
{
    int status, maxlength;

    this->vert_shader = compile_shader(vert_source, GL_VERTEX_SHADER);
    this->frag_shader = compile_shader(frag_source, GL_FRAGMENT_SHADER);
    this->shader_prog = glCreateProgram();

    glAttachShader(shader_prog, vert_shader);
    glAttachShader(shader_prog, frag_shader);
    glLinkProgram(shader_prog);

    /* check for linking errors */
    glGetProgramiv(shader_prog, GL_LINK_STATUS, &status);
    if (status != GL_TRUE) {
        glGetProgramiv(shader_prog, GL_INFO_LOG_LENGTH, &maxlength);
        if (maxlength > 0) {
            char *buffer = new char[maxlength];
            glGetProgramInfoLog(shader_prog, maxlength, NULL, buffer);
            fprintf(stderr, "OpenGL shader failed to link: %s\n", buffer);
            exit(1);
        }
    }
}

    void
Shader::use()
{
    if (this->shader_prog == 0) {
        fprintf(stderr, "Shader not initialized or may have been destroyed.\n");
        exit(1);
    }
    glUseProgram(this->shader_prog);
}

    void
Shader::destroy()
{
    glDeleteShader(this->vert_shader);
    glDeleteShader(this->frag_shader);
    glDeleteProgram(this->shader_prog);
    this->vert_shader = 0;
    this->frag_shader = 0;
    this->shader_prog = 0;
}

    GLuint
Shader::get_attrib_loc(const char* name)
{
    return glGetAttribLocation(shader_prog, name);
}

    void
Shader::set_uniform_1f(const char* name, float v)
{
    glUniform1f(glGetUniformLocation(this->shader_prog, name), v);
}

    void
Shader::set_uniform_3f(const char* name, float x, float y, float z)
{
    glUniform3f(glGetUniformLocation(this->shader_prog, name), x, y, z);
}

    void
Shader::set_uniform_3fv(const char* name, glm::vec3 vec)
{
    glUniform3fv(glGetUniformLocation(this->shader_prog, name), 1, &vec[0]);
}

    void
Shader::set_uniform_mat4fv(const char* name, glm::mat4 matrix)
{
    glUniformMatrix4fv(glGetUniformLocation(this->shader_prog, name),
            1, GL_FALSE, &matrix[0][0]);
}

    GLuint
Shader::compile_shader(const char* src, int type)
{
    char buffer[512];
    int status, shader_id;
    shader_id = glCreateShader(type);
    glShaderSource(shader_id, 1, &src, NULL);
    glCompileShader(shader_id);
    glGetShaderiv(shader_id, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        glGetShaderInfoLog(shader_id, 512, NULL, buffer);
        fprintf(stderr, "Shader failed to compile: %s\n", buffer);
        exit(1);
    }
    return shader_id;
}

Camera::Camera()
    : screen_x(0)
    , screen_y(0)
    , mode(FPS)
    , fps_yaw(0)
    , fps_pitch(0)
    , arc_yaw(0)
    , arc_pitch(0)
    , fov(0)
    , zoomf(0)
    , target(glm::vec4(0.0f, 0.0f, 0.0f, 1.0f))
    , fps_position(glm::vec4(0.0f, 0.0f, 3.0f, 1.0f))
    , arc_position(glm::vec4(0.0f, 0.0f, 3.0f, 1.0f))
    , front(glm::vec3(0.0f, 0.0f, -1.0f))
    , up(glm::vec3(0.0f, 1.0f, 0.0f))
      , lefthand(glm::vec4(0.f, 0.f, 1.f, 1.f))
{ }

Camera::Camera(int screen_x, int screen_y)
    : screen_x(screen_x)
    , screen_y(screen_y)
    , mode(FPS)
    , fps_yaw(180.f)
    , fps_pitch(0)
    , arc_yaw(0)
    , arc_pitch(0)
    , fov(45.0f)
    , zoomf(0)
    , target(glm::vec4(0.0f, 0.0f, 0.0f, 1.0f))
    , fps_position(glm::vec4(0.0f, 0.0f, 3.0f, 1.0f))
    , arc_position(glm::vec4(0.0f, 0.0f, 3.0f, 1.0f))
    , front(glm::vec3(0.0f, 0.0f, -1.0f))
    , up(glm::vec3(0.0f, 1.0f, 0.0f))
      , lefthand(glm::vec4(0.f, 0.f, 1.f, 1.f))
{ }

Camera::Camera(int screen_x, int screen_y, CameraMode mode)
    : screen_x(screen_x)
    , screen_y(screen_y)
    , mode(mode)
    , fps_yaw(180.f)
    , fps_pitch(0)
    , arc_yaw(0)
    , arc_pitch(0)
    , fov(45.0f)
    , zoomf(0)
    , target(glm::vec4(0.0f, 0.0f, 0.0f, 1.0f))
    , fps_position(glm::vec4(0.0f, 0.0f, 3.0f, 1.0f))
    , arc_position(glm::vec4(0.0f, 0.0f, 3.0f, 1.0f))
    , front(glm::vec3(0.0f, 0.0f, -1.0f))
    , up(glm::vec3(0.0f, 1.0f, 0.0f))
      , lefthand(glm::vec4(0.f, 0.f, 1.f, 1.f))
{ }

/* zooming in and out of where one looks in 3D-space */
    void
Camera::zoom(int increment)
{
    static const float speed = 5.f;
    this->zoomf = glm::clamp(this->zoomf - speed * increment, -1000.f, 1000.f);
}

/* using x, y position to orient where one looks in 3D-space */
    void
Camera::look(int x, int y)
{
    switch (mode) {
        case FPS: fps_look(x, y); break;
        case ARCBALL: arc_look(x, y); break;
    }
}

/* move camera across the 3D space along a 2D plane */
    void
Camera::move(CameraDir dir, float delta)
{
    switch (mode) {
        case FPS: fps_move(dir, delta); break;
        case ARCBALL: arc_move(dir, delta); break;
    }
}

    glm::mat4
Camera::view()
{
    switch (mode) {
        case FPS: return fps_view();
        default:
        case ARCBALL: return arc_view();
    }
}

    void
Camera::fps_look(int x, int y)
{
    static const float sensitivity = 0.1f;
    glm::vec3 f;

    fps_yaw = fmodf(fps_yaw + (x * sensitivity), 360.f);
    fps_pitch = glm::clamp(fps_pitch + -(y * sensitivity), -89.f, 89.f);

    f.x = cos(glm::radians(fps_yaw)) * cos(glm::radians(fps_pitch));
    f.y = sin(glm::radians(fps_pitch));
    f.z = sin(glm::radians(fps_yaw)) * cos(glm::radians(fps_pitch));
    this->front = glm::normalize(f);
}

    void
Camera::arc_look(int x, int y)
{
    static const float sensitivity = 0.1f;
    arc_yaw = fmodf(arc_yaw + (x * sensitivity), 360.f);
    arc_pitch = glm::clamp(arc_pitch + -(y * sensitivity), -89.f, 89.f);
}

/*
 * Pans camera left and right, keeping height, by moving the target around
 * the camera arcs.
 */
    void
Camera::arc_move(CameraDir dir, float delta)
{
    float speed = 25.0 * delta;

    glm::vec4 right, forward;

    right = glm::normalize(target - arc_position);
    right = glm::vec4(glm::cross(glm::vec3(right), up), 1.f);
    right.y = 0;
    right = glm::normalize(right);

    forward = glm::normalize(target - arc_position);
    forward.y = 0;
    forward = glm::normalize(forward);

    switch (dir) {
        case FORWARD:
            target += forward * speed;
            break;
        case BACKWARD:
            target -= forward * speed;
            break;
        case RIGHT:
            target += right * speed;
            break;
        case LEFT:
            target -= right * speed;
            break;
    }
}

/*
 * Moves the cameara itself and uses the front to translate its motion into
 * 3D spaces. It's not restricted to a plane like the above.
 */
    void
Camera::fps_move(CameraDir dir, float delta)
{
    float speed = 25.0 * delta;
    switch (dir) {
        case FORWARD:
            fps_position += speed * glm::vec4(front, 1.f);
            break;
        case BACKWARD:
            fps_position -= speed * glm::vec4(front, 1.f);
            break;
        case LEFT:
            fps_position -= glm::vec4(glm::normalize(glm::cross(front, up)) * speed, 1.f);
            break;
        case RIGHT:
            fps_position += glm::vec4(glm::normalize(glm::cross(front, up)) * speed, 1.f);
            break;
    }
}

    glm::mat4
Camera::fps_view()
{
    glm::vec3 pos(fps_position);
    return glm::lookAt(pos, pos + front, up);
}

/*
 * The arcball view of the world space.
 */
    glm::mat4
Camera::arc_view()
{
    glm::vec4 pos;
    /* the order of this matters and yes, `lefthand' is required */
    pos = glm::yawPitchRoll(
            -glm::radians(arc_yaw - 90.f),
            glm::radians(arc_pitch), 0.f) * lefthand;
    pos *= zoomf;
    pos += target;
    arc_position = pos;
    return glm::lookAt(glm::vec3(arc_position), glm::vec3(target), up);
}

    glm::mat4
Camera::projection()
{
    return glm::perspective(glm::radians(fov),
            (float)screen_x / (float)screen_y, 0.1f, 1000.0f);
}

    void
Camera::set_mode(CameraMode mode)
{
    this->mode = mode;
}

    glm::vec3
Camera::pos()
{
    switch (mode) {
        case FPS: return fps_position;
        default:
        case ARCBALL: return arc_position;
    }
}

    void
Camera::lookat(glm::vec3 pos, float zoom)
{
    this->zoomf = zoom;
    this->fps_position = glm::vec4(pos.x + zoomf, pos.y, pos.z, 1.0f);
    this->target = glm::vec4(pos.x, pos.y, pos.z, 1.0f);
    fps_look(0, 0);
}

#define NUM_VERTS 180

    void
ico_triangle(int a, int b, int c, const float* ico, vector<float>& v)
{
    v.push_back(ico[a * 3 + 0]);
    v.push_back(ico[a * 3 + 1]);
    v.push_back(ico[a * 3 + 2]);
    v.push_back(ico[b * 3 + 0]);
    v.push_back(ico[b * 3 + 1]);
    v.push_back(ico[b * 3 + 2]);
    v.push_back(ico[c * 3 + 0]);
    v.push_back(ico[c * 3 + 1]);
    v.push_back(ico[c * 3 + 2]);
}

    vector<float>
buildIco()
{
    static const float X = 0.525731112119133606f;
    static const float Z = 0.850650808352039932f;
    static const float ico[] = {
        -X,  Z,  0,
        X,  Z,  0,
        -X, -Z,  0,
        X, -Z,  0,

        0, -X,  Z,
        0,  X,  Z,
        0, -X, -Z,
        0,  X, -Z,

        Z,  0, -X,
        Z,  0,  X,
        -Z,  0, -X,
        -Z,  0,  X
    };

    vector<float> v;

    // 5 faces around point 0
    ico_triangle(0, 11, 5, ico, v);
    ico_triangle(0, 5, 1, ico, v);
    ico_triangle(0, 1, 7, ico, v);
    ico_triangle(0, 7, 10, ico, v);
    ico_triangle(0, 10, 11, ico, v);

    // 5 adjacent faces
    ico_triangle(1, 5, 9, ico, v);
    ico_triangle(5, 11, 4, ico, v);
    ico_triangle(11, 10, 2, ico, v);
    ico_triangle(10, 7, 6, ico, v);
    ico_triangle(7, 1, 8, ico, v);

    // 5 faces around point 3
    ico_triangle(3, 9, 4, ico, v);
    ico_triangle(3, 4, 2, ico, v);
    ico_triangle(3, 2, 6, ico, v);
    ico_triangle(3, 6, 8, ico, v);
    ico_triangle(3, 8, 9, ico, v);

    // 5 adjacent faces
    ico_triangle(4, 9, 5, ico, v);
    ico_triangle(2, 4, 11, ico, v);
    ico_triangle(6, 2, 10, ico, v);
    ico_triangle(8, 6, 7, ico, v);
    ico_triangle(9, 8, 1, ico, v);

    return v;
}

void
normalize3f (float* v)
{
    float d = sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (d == 0.0f)
        d = 0.001;
    //assert(d != 0.f);
    v[0] /= d;
    v[1] /= d;
    v[2] /= d;
}

void
addVertices (float *v, float *n, vector<float> &out)
{
    for (int i = 0; i < 3; i++)
        out.push_back(v[i]);
    for (int i = 0; i < 3; i++)
        out.push_back(n[i]);
}

void
normCrossProd (float u[3], float v[3], float *out)
{
    out[0] = u[1] * v[2] - u[2] * v[1];
    out[1] = u[2] * v[0] - u[0] * v[2];
    out[2] = u[0] * v[1] - u[1] * v[0];
    normalize3f(out);
}

/* Compute normal for entire face which all vertices of face use */
void
faceNorm (float *vA, float *vB, float *vC, float *out)
{
    float d1[3], d2[3];
    for (int k = 0; k < 3; k++) {
        d1[k] = vA[k] - vB[k];
        d2[k] = vB[k] - vC[k];
    }
    normCrossProd(d1, d2, out);
}

    void
subdivide(float* vA, float* vB, float* vC, int depth, vector<float>& out, float percent)
{
    float vAB[3], vBC[3], vCA[3];
    float norm[3];

    if (depth == 0) {
        faceNorm(vA, vB, vC, norm);
        addVertices(vA, norm, out);
        addVertices(vB, norm, out);
        addVertices(vC, norm, out);
        return;
    }

    for (int i = 0; i < 3; i++) {
        vAB[i] = vA[i] + (vB[i] * percent);
        vBC[i] = vB[i] + (vC[i] * percent);
        vCA[i] = vC[i] + (vA[i] * percent);
    }

    normalize3f(vAB);
    normalize3f(vBC);
    normalize3f(vCA);

    subdivide(vA, vAB, vCA, depth - 1, out, percent);
    subdivide(vB, vBC, vAB, depth - 1, out, percent);
    subdivide(vC, vCA, vBC, depth - 1, out, percent);
    subdivide(vAB, vBC, vCA, depth - 1, out, percent);
}

    void
copyPoint(float* v, int index, vector<float>& vertices)
{
    v[0] = vertices[index + 0];
    v[1] = vertices[index + 1];
    v[2] = vertices[index + 2];
}

    vector<float>
subdivideIco(vector<float>& ico, int depth, float percent)
{
    float vA[3], vB[3], vC[3];

    if (percent == 0.0)
        percent = 0.0001;

    vector<float> output;

    // 180 / 9 = 20 faces of 3 triangles each having 3 points
    for (int i = 0; i < 180; i += 9) {
        copyPoint(vA, i, ico);
        copyPoint(vB, i + 3, ico);
        copyPoint(vC, i + 6, ico);
        subdivide(vA, vB, vC, depth, output, percent);
    }

    return output;
}

    int
main(int argc, char** argv)
{
    SDL_Window* window;
    SDL_GLContext glContext;
    SDL_Event e;
    GLuint VAO;
    GLuint VBO;

    SDL_DisplayMode display;
    GLuint vertex_id;
    GLuint norm_id;

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL Failed to init: %s\n", SDL_GetError());
        exit(1);
    }

    window = SDL_CreateWindow("Model",
            SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
            800, 600, /* these won't be used if FULLSCREEN is given below */
            SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN_DESKTOP);

    if (!window) {
        fprintf(stderr, "Window could not be created: %s\n", SDL_GetError());
        SDL_Quit();
        exit(1);
    }

    /* Get screen width and height since we're in fullscreen */
    SDL_GetCurrentDisplayMode(0, &display);

    glContext = SDL_GL_CreateContext(window);
    if (!glContext) {
        printf("Could not create OpenGL context: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        exit(1);
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
            SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

#ifdef _WIN32
    glewInit();
#endif

    glEnable(GL_DEPTH_TEST);

    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);

    SDL_GetCurrentDisplayMode(0, &display);
    Camera camera(display.w, display.h, FPS);

    Shader shader(vertex_source, fragment_source);
    shader.use();

    auto ico = buildIco();
    auto vertices = subdivideIco(ico, 3, 1.0);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    /* reserve size of vertices buffer */
    glBufferData(GL_ARRAY_BUFFER, vertices.size() * sizeof(float), &vertices[0], GL_STATIC_DRAW);

    /* setup vertices attribute, width of 3 in span of 6 elements */
    vertex_id = shader.get_attrib_loc("vertex");
    glVertexAttribPointer(vertex_id, 3,
                GL_FLOAT, GL_FALSE, 6 * sizeof(float), 0);
    glEnableVertexAttribArray(vertex_id);

    /* setup normal attribute, width of 3, 3 elements into span of 6 elements */
    norm_id = shader.get_attrib_loc("norm");
    glVertexAttribPointer(norm_id, 3, GL_FLOAT,
                GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(norm_id);

    if (SDL_GL_SetSwapInterval(1) < 0)
        fprintf(stderr, "Warning: SwapInterval could not be set: %s\n",
                SDL_GetError());

    //glEnable(GL_CULL_FACE);
    /* Clockwise winding order are 'face' vertices */
    //glFrontFace(GL_CW);

    bool playing = true;

    glm::vec3 pos(0, 0, 0);

    shader.set_uniform_3f("objectColor", 1.0f, 0.5f, 0.31f);
    shader.set_uniform_3f("lightColor", 1.0f, 0.5f, 0.31f);

    shader.set_uniform_mat4fv("projection", camera.projection());
    shader.set_uniform_3fv("lightPos", camera.pos());
    shader.set_uniform_mat4fv("view", camera.view());

    float time = 0;
    float percent = 0;

    while (playing) {
        while (SDL_PollEvent(&e)) {
            switch (e.type) {
                case SDL_QUIT:
                    playing = false;
                    break;
                case SDL_KEYDOWN:
                    switch (e.key.keysym.sym) {
                        case SDLK_ESCAPE:
                            playing = false;
                            break;
                    }
                    break;
            }
        }

        time = (float)(SDL_GetTicks() * 0.001);
        shader.set_uniform_1f("time", time);

        percent = (sin(0.25 * time) + 1.0) / 2.0;
        vertices = subdivideIco(ico, 3, percent);
        glBufferSubData(GL_ARRAY_BUFFER, 0, vertices.size() * sizeof(float), &vertices[0]);

        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        //glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glm::mat4 model = glm::mat4(1.0f);
        model = glm::translate(model, pos);
        //model = glm::rotate(model, 5.f * percent, glm::vec3(0.25, 0.75, 0.25));
        model = glm::rotate(model, time, glm::vec3(0.0, 1.0, 0.0));
        shader.set_uniform_mat4fv("model", model);
        glDrawArrays(GL_TRIANGLES, 0, vertices.size());

        SDL_GL_SwapWindow(window);
    }

    return 0;
}

cmake_minimum_required(VERSION 3.18.1)
project("live2d_native")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Cubism SDK 路径
set(CUBISM_SDK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/CubismSdkForNative")
set(CUBISM_CORE_PATH "${CUBISM_SDK_ROOT}/Core")
set(CUBISM_FRAMEWORK_PATH "${CUBISM_SDK_ROOT}/Framework")

# Cubism Core 静态库
add_library(Live2DCubismCore STATIC IMPORTED)
set_target_properties(Live2DCubismCore PROPERTIES
    IMPORTED_LOCATION "${CUBISM_CORE_PATH}/lib/android/${ANDROID_ABI}/libLive2DCubismCore.a"
)

# 只收集 OpenGL ES 渲染器相关的 Framework 源文件
file(GLOB CUBISM_FRAMEWORK_SOURCES
    "${CUBISM_FRAMEWORK_PATH}/src/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Effect/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Id/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Math/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Model/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Motion/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Physics/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Rendering/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Rendering/OpenGL/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Type/*.cpp"
    "${CUBISM_FRAMEWORK_PATH}/src/Utils/*.cpp"
)

# 项目源文件
set(PROJECT_SOURCES
    live2d_renderer.cpp
    live2d_jni.cpp
    live2d_model.cpp
    live2d_allocator.cpp
)

# 构建共享库
add_library(${PROJECT_NAME} SHARED
    ${PROJECT_SOURCES}
    ${CUBISM_FRAMEWORK_SOURCES}
)

# 头文件路径
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CUBISM_CORE_PATH}/include
    ${CUBISM_FRAMEWORK_PATH}/src
)

# 链接库
target_link_libraries(${PROJECT_NAME}
    Live2DCubismCore
    android
    log
    EGL
    GLESv2
    jnigraphics
)

# 预处理器定义
target_compile_definitions(${PROJECT_NAME} PRIVATE
    CSM_TARGET_ANDROID_ES2
)

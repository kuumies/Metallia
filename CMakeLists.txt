cmake_minimum_required(VERSION 3.0)

project(Metallia VERSION 1.0.0 LANGUAGES OBJCXX)

find_library(COCOA_LIBRARY Cocoa REQUIRED)
find_library(METAL_LIBRARY Metal REQUIRED)
find_library(METALKIT_LIBRARY MetalKit REQUIRED)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION})
set(MACOSX_BUNDLE_COPYRIGHT "© 2022 by kuuSoftware")
set(MACOSX_BUNDLE_INFO_STRING "kuu.Metallia")
set(MACOSX_BUNDLE_GUI_IDENTIFIER "org.kuuSoftware.Metallia")

set(_target ${PROJECT_NAME})

set(OBJC_SOURCES
    Source/Common.h
    Source/Main.m
    Source/Math.h
    Source/Math.mm
    Source/MetalRenderer.h
    Source/MetalRenderer.m
    Source/MetalView.h
    Source/MetalView.m
    Source/Scene.h
    Source/Scene.mm
)

set(METAL_SHADER_SOURCES
    Source/Shaders.metal
)

add_executable(${_target}
    MACOSX_BUNDLE
    ${OBJC_SOURCES}
    ${METAL_SHADER_SOURCES}
)

target_link_libraries(${_target}
    PUBLIC
        ${COCOA_LIBRARY}
        ${METAL_LIBRARY}
        ${METALKIT_LIBRARY}
)

# ------------------------------------------------------------------------------
# Compile metal shaders into air

# This required some manual magik to make it available that I have forgot :(
SET(XCRUN "xcrun")

foreach(METAL_SHADER ${METAL_SHADER_SOURCES})
    get_filename_component(FILE_NAME ${METAL_SHADER} NAME)
    set(METAL_SHADER_AIR "${PROJECT_BINARY_DIR}/Shaders/${FILE_NAME}.air")
    set(METAL_SHADER_METALLIB "${PROJECT_BINARY_DIR}/Shaders/${FILE_NAME}.metallib")

    add_custom_command(
        OUTPUT ${METAL_SHADER_AIR}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${PROJECT_BINARY_DIR}/Shaders/"
        COMMAND ${XCRUN} -sdk macosx metal -c ${CMAKE_CURRENT_SOURCE_DIR}/${METAL_SHADER} -o ${METAL_SHADER_AIR}
        DEPENDS ${METAL_SHADER})

    list(APPEND METAL_SHADER_AIR_FILES ${METAL_SHADER_AIR})

endforeach()

add_custom_target(
    MetalShadersAir
    DEPENDS ${METAL_SHADER_AIR_FILES}
)

add_dependencies(${_target} MetalShadersAir)

# ------------------------------------------------------------------------------
# Compile meta air files into shader library

set(METAL_SHADER_METALLIB "${PROJECT_BINARY_DIR}/Shaders/${FILE_NAME}.metallib")

add_custom_command(
    OUTPUT ${METAL_SHADER_METALLIB}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PROJECT_BINARY_DIR}/Shaders/"
    COMMAND ${XCRUN} -sdk macosx metallib ${METAL_SHADER_AIR_FILES} -o ${METAL_SHADER_METALLIB}
    DEPENDS ${METAL_SHADER_AIR_FILES}
)

add_custom_target(
    MetalShadersLibrary
    DEPENDS ${METAL_SHADER_METALLIB}
)

add_dependencies(MetalShadersAir MetalShadersLibrary)
add_dependencies(${_target} MetalShadersLibrary)

# ------------------------------------------------------------------------------
# Install shaders into app

install(DIRECTORY ${PROJECT_BINARY_DIR}/Shaders/
        DESTINATION $<TARGET_FILE_DIR:Metallia>)

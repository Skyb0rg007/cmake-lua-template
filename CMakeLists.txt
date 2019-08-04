cmake_minimum_required(VERSION 3.11 FATAL_ERROR)
project(Optic
    VERSION 0.1.0
    DESCRIPTION "A programming language with lenses"
    LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

include(FetchContent)
include(CMakeDependentOption)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

#############################################################################
##
## Options
##
#############################################################################

option(BUILD_MISSING_DEPS "Build missing dependencies" OFF)

if(BUILD_MISSING_DEPS)
    set(DEPS_REQUIRED)
else()
    set(DEPS_REQUIRED REQUIRED)
endif()

#############################################################################
##
## Dependencies
##
#############################################################################

# Lua 5.3
FetchContent_Declare(
    lua53
    GIT_REPOSITORY "https://github.com/Skyb0rg007/lua-cmake.git")

find_package(Lua 5.3 ${DEPS_REQUIRED})
if(BUILD_MISSING_DEPS AND NOT Lua_FOUND)
    FetchContent_Populate(lua53)
    add_subdirectory(${lua53_SOURCE_DIR} ${lua53_BINARY_DIR})
    get_target_property(LUA_INCLUDE_DIR lua::liblua INTERFACE_INCLUDE_DIRECTORIES)
    set(LUA_LIBRARIES lua::liblua)
endif()

find_program(LUA_EXE NAMES lua-5.3 lua5.3 lua)

add_subdirectory(src)

#############################################################################
##
## Installation
##
#############################################################################

# install(EXPORT optic-targets
    # DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake
    # NAMESPACE optic::
    # COMPONENT Development)

# configure_package_config_file(
    # ${CMAKE_CURRENT_SOURCE_DIR}/cmake/optic-config.cmake.in
    # ${PROJECT_BINARY_DIR}/optic-config.cmake
    # INSTALL_DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/cmake
    # NO_CHECK_REQUIRED_COMPONENTS_MACRO)

# write_basic_package_version_file(
    # ${PROJECT_BINARY_DIR}/optic-config-version.cmake
    # VERSION ${PROJECT_VERSION}
    # COMPATIBILITY ExactVersion)

# install(FILES
        # ${PROJECT_BINARY_DIR}/optic-config.cmake
        # ${PROJECT_BINARY_DIR}/optic-config-version.cmake
    # DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake
    # COMPONENT Development)


#############################################################################
##
## Packaging
##
#############################################################################

# # Common
# set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
# set(CPACK_PACKAGE_VENDOR "Skyb0rg007")
# set(CPACK_PACKAGE_DIRECTORY "${PROJECT_BINARY_DIR}/CPack")
# set(CPACK_PACKAGE_DESCRIPTION_FILE "${PROJECT_SOURCE_DIR}/README.md")
# set(CPACK_PACKAGE_HOMEPAGE_URL "TODO")
# set(CPACK_STRIP_FILES TRUE)
# set(CPACK_VERBATIM_VARIABLES TRUE)

# # Source
# set(CPACK_SOURCE_IGNORE_FILES "/\\.vimrc" "${PROJECT_BINARY_DIR}")
# # Archive
# set(CPACK_ARCHIVE_COMPONENT_INSTALL ON) # Differernt package for each component
# # Deb
# set(CPACK_DEB_COMPONENT_INSTALL ON)
# # Rpm
# set(CPACK_RPM_COMPONENT_INSTALL ON)

# include(CPack)

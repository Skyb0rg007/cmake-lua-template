file(GLOB_RECURSE OPTIC_LUA_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.lua")
set(OPTIC_LUA_PATH "${CMAKE_CURRENT_SOURCE_DIR}/?.lua")
set(OPTIC_LUA_SOURCES
    "main" "${CMAKE_CURRENT_SOURCE_DIR}/main.lua")

if(LUA_EXE)
    add_custom_target(run
        ${LUA_EXE} -E
            -e "package.path = ''"
            -e "package.cpath = ''"
            ${CMAKE_SOURCE_DIR}/src/main.lua
        VERBATIM)
    # add_dependencies(run lpeglabel-module lyaml-module)

    add_custom_target(repl
        ${LUA_EXE} -E -i
            -e "package.path = ''"
            -e "package.cpath = ''"
            ${CMAKE_SOURCE_DIR}/src/main.lua
        VERBATIM)
    # add_dependencies(repl lpeglabel-module lyaml-module)
endif()

set(deps "")
foreach(l OPTIC_LUA_SOURCES)
    set(i 0)
    list(LENGTH ${l} len)
    while(${i} LESS ${len})
        math(EXPR j "${i} + 1")
        list(GET ${l} ${j} source)
        list(APPEND deps "${source}")
        math(EXPR i "${i} + 2")
    endwhile()
endforeach()

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/optic.c
    COMMAND ${CMAKE_COMMAND}
        "-DOUTFILE=${CMAKE_CURRENT_BINARY_DIR}/optic.c"
        "-DENTRYPOINT=main"
        "-DLUA_SOURCES=${OPTIC_LUA_SOURCES}"
        "-DC_MODULES="
         -P "${PROJECT_SOURCE_DIR}/cmake/LuaStatic.cmake"
    DEPENDS ${deps}
    VERBATIM)

add_executable(optic
    ${CMAKE_CURRENT_BINARY_DIR}/optic.c)
target_include_directories(optic
    PRIVATE ${LUA_INCLUDE_DIR})
target_link_libraries(optic
    PRIVATE ${LUA_LIBRARIES})

# install(TARGETS optic EXPORT optic-targets
    # RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT Runtime)

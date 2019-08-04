
#[[

    LuaStatic.cmake - CMake script to bundle lua scripts into a binary

    Usage:
    - Set the following variables:
        OUTFILE - the .c file to produce
        ENTRYPOINT - the name of the lua module to begin execution with
        LUA_SOURCES - list of lua module names and files
            ex. set(LUA_SOURCES
                    "main" "/path/to/main.lua"
                    "example.path" "/another/file/path.lua")
        C_MODULES - list of c module names to load
            These are translated into luaload_% calls
            ex. set(C_MODULES "lpeg") #=> ... luaload_lpeg(L) ...
            Make sure to link the library with the produced .c file

    cmake
        -DOUTFILE=${OUTFILE}
        -DENTRYPOINT=${ENTRYPOINT}
        -DLUA_SOURCES=${LUA_SOURCES}
        -DC_MODULES=${C_MODULES}
        -P /path/to/LuaStatic.cmake
]]

cmake_minimum_required(VERSION 3.11 FATAL_ERROR)

function(embed_file outstr filepath identifier)
    file(READ "${filepath}" contents HEX)
    string(REGEX REPLACE 
        "(..)"
        "0x\\1, "
        contents "${contents}")
    string(REGEX REPLACE ", $" "" contents "${contents}")
    set("${outstr}" "static const uint8_t ${identifier}[] = {${contents}};" PARENT_SCOPE)
endfunction()

function(str_to_hex outstr instr)
    set(tmpfile "${CMAKE_CURRENT_BINARY_DIR}/tmp.lua")
    file(WRITE "${tmpfile}" "${instr}")
    file(READ "${tmpfile}" contents HEX)
    file(REMOVE "${tmpfile}")
    string(REGEX REPLACE 
        "(..)"
        "0x\\1, "
        contents "${contents}")
    string(REGEX REPLACE ", $" "" contents "${contents}")
    set("${outstr}" "${contents}" PARENT_SCOPE)
endfunction()

function(embed_c_modules outstr c_modules)
    list(LENGTH c_modules len)
    math(EXPR len "(${len} / 2) * 2")
    set(i 0)
    set(output "")
    while(${i} LESS ${len})
        list(GET c_modules ${i} modname)
        string(APPEND output "    int luaopen_${modname}(lua_State *L);\n")
        string(APPEND output "    lua_pushcfunction(L, luaopen_${modname});\n")
        string(APPEND output "    lua_setfield(L, 2, \"${modname}\");\n\n")
        math(EXPR i "${i} + 1")
    endwhile()
    set("${outstr}" "${output}" PARENT_SCOPE)
endfunction()

function(embed_lua_modules outstr lua_sources)
    list(LENGTH lua_sources len)
    math(EXPR len "(${len} / 2) * 2")
    set(i 0)
    set(output "")
    while(${i} LESS ${len})
        math(EXPR j "${i} + 1")
        list(GET lua_sources ${i} modname)
        list(GET lua_sources ${j} filename)
        embed_file(file_embed "${filename}" "lua_require_${i}")
        string(PREPEND file_embed "    ")
        string(APPEND file_embed  "    lua_pushlstring(L, (const char *)lua_require_${i}, sizeof(lua_require_${i}));\n")
        string(APPEND file_embed  "    lua_setfield(L, -2, \"${modname}\");\n\n")
        string(APPEND output "${file_embed}")
        math(EXPR i "${i} + 2")
    endwhile()
    set("${outstr}" "${output}" PARENT_SCOPE)
endfunction()

function(luastatic outfile lua_entrypoint lua_sources c_modules)
    set(LUA_LOADER_IN [=[
local args = {...}
local lua_bundle = args[1]

local load_string = _G.loadstring or _G.load

local function lua_loader(name)
    local mod = lua_bundle[name]
    if mod then
        if type(mod) == "string" then
            local chunk, errstr = load_string(mod, name)
            if chunk then
                return chunk
            else
                error(
                    string.format(
                        "error loading module '%s' from luastatic bundle:\n\t%s",
                        name, errstr),
                    0)
            end
        elseif type(mod) == "function" then
            return mod
        end
    else
        return ("\n\tno module '%s' in luastatic bundle"):format(name)
    end
end
table.insert(package.loaders or package.searchers, 2, lua_loader)

local unpack = unpack or table.unpack
local func = lua_loader("@LUA_ENTRYPOINT@")
if type(func) == "function" then
    func(unpack(arg))
else
    error(func, 0)
end
]=])
    set(LUA_ENTRYPOINT ${lua_entrypoint})
    # LUA_ENTRYPOINT
    string(CONFIGURE "${LUA_LOADER_IN}" LUA_LOADER @ONLY)
    str_to_hex(LUA_LOADER "${LUA_LOADER}")
    set(LUA_LOADER "        ${LUA_LOADER}")

    embed_lua_modules(LUA_MODULES "${lua_sources}")
    embed_c_modules(C_MODULES "${c_modules}")
    # LUA_LOADER, LUA_ENTRYPOINT, LUA_MODULES, C_MODULES
    configure_file("${CMAKE_CURRENT_LIST_DIR}/LuaStatic.c.in" "${outfile}" @ONLY)
endfunction()

function(assert varname)
    if(NOT ${varname})
        message(FATAL_ERROR "${varname} is not set!")
    endif()
endfunction()

assert(OUTFILE)
assert(ENTRYPOINT)
assert(LUA_SOURCES)
# assert(C_MODULES)

luastatic("${OUTFILE}" "${ENTRYPOINT}" "${LUA_SOURCES}" "${C_MODULES}")

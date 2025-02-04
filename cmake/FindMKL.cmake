# - Find Intel MKL
# Find the MKL libraries
#
# Options:
#
#   MKL_STATAIC       :   use static linking
#   MKL_MULTI_THREADED:   use multi-threading
#   MKL_SDL           :   Single Dynamic Library interface
#
# This module defines the following variables:
#
#   MKL_FOUND            : True if MKL_INCLUDE_DIR are found
#   MKL_INCLUDE_DIR      : where to find mkl.h, etc.
#   MKL_INCLUDE_DIRS     : set when MKL_INCLUDE_DIR found
#   MKL_LIBRARIES        : the library to link against.


include(FindPackageHandleStandardArgs)

if(NOT DEFINED INTEL_ROOT)
    if(WIN32)
        set(INTEL_ROOT "C:/Program Files (x86)/IntelSWTools/compilers_and_libraries/windows" CACHE PATH "Folder contains intel libs")
    else()
        set(INTEL_ROOT "/opt/intel" CACHE PATH "Folder contains intel libs")
    endif()
    message(STATUS "Set Intel Root to ${INTEL_ROOT}")
endif()

set(MKL_ROOT ${INTEL_ROOT}/mkl CACHE PATH "Folder contains MKL")

# Find include dir
find_path(MKL_INCLUDE_DIR mkl.h
    PATHS ${MKL_ROOT}/include)

# Find include directory
#  There is no include folder under linux
if(WIN32)
    find_path(INTEL_INCLUDE_DIR omp.h
        PATHS ${INTEL_ROOT}/compiler/include)
    set(MKL_INCLUDE_DIR ${MKL_INCLUDE_DIR} ${INTEL_INCLUDE_DIR})
endif()

# Find libraries

# Handle suffix
set(_MKL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})

if(WIN32)
    if(MKL_STATAIC)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .lib)
    else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES _dll.lib)
    endif()
else()
    if(MKL_STATAIC)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
    else()
        if(APPLE)
          set(CMAKE_FIND_LIBRARY_SUFFIXES .dylib)
        else()
          set(CMAKE_FIND_LIBRARY_SUFFIXES .so)
        endif()
    endif()
endif()

if(WIN32)
    if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "4")
        set(MKL_OS_SUFFIXES "ia32/")
    else()
        set(MKL_OS_SUFFIXES "intel64/")
    endif()
else()
    if(APPLE)
        set(MKL_OS_SUFFIXES "")
    else()
        if("${CMAKE_SIZEOF_VOID_P}" STREQUAL "4")
            set(MKL_OS_SUFFIXES "ia32/")
        else()
            set(MKL_OS_SUFFIXES "intel64/")
        endif()
    endif()
endif()


# MKL is composed by four layers: Interface, Threading, Computational and RTL

if(MKL_SDL)
    find_library(MKL_LIBRARY mkl_rt
        PATHS ${MKL_ROOT}/lib/${MKL_OS_SUFFIXES})

    set(MKL_MINIMAL_LIBRARY ${MKL_LIBRARY})
else()
    ######################### Interface layer #######################
    set(MKL_INTERFACE_LIBNAME mkl_intel_lp64)

    find_library(MKL_INTERFACE_LIBRARY ${MKL_INTERFACE_LIBNAME}
        PATHS ${MKL_ROOT}/lib/${MKL_OS_SUFFIXES})

    ######################## Threading layer ########################
    if(MKL_MULTI_THREADED)
        set(MKL_THREADING_LIBNAME mkl_intel_thread)
    else()
        set(MKL_THREADING_LIBNAME mkl_sequential)
    endif()

    find_library(MKL_THREADING_LIBRARY ${MKL_THREADING_LIBNAME}
        PATHS ${MKL_ROOT}/lib/${MKL_OS_SUFFIXES})

    ####################### Computational layer #####################
    find_library(MKL_CORE_LIBRARY mkl_core
        PATHS ${MKL_ROOT}/lib/${MKL_OS_SUFFIXES})

    ############################ RTL layer ##########################
    if(WIN32)
        set(CMAKE_FIND_LIBRARY_SUFFIXES .lib)
        set(MKL_RTL_LIBNAME libiomp5md)
        find_library(MKL_RTL_LIBRARY ${MKL_RTL_LIBNAME}
            PATHS ${INTEL_ROOT}/compiler/lib/${MKL_OS_SUFFIXES})
    else()
        set(MKL_RTL_LIBNAME iomp5)
        find_library(MKL_RTL_LIBRARY ${MKL_RTL_LIBNAME}
            PATHS ${INTEL_ROOT}/lib/${MKL_OS_SUFFIXES})
    endif()

    set(MKL_LIBRARY ${MKL_INTERFACE_LIBRARY} ${MKL_THREADING_LIBRARY} ${MKL_CORE_LIBRARY} ${MKL_RTL_LIBRARY})
    set(MKL_MINIMAL_LIBRARY ${MKL_INTERFACE_LIBRARY} ${MKL_THREADING_LIBRARY} ${MKL_CORE_LIBRARY} ${MKL_RTL_LIBRARY})
endif()

set(CMAKE_FIND_LIBRARY_SUFFIXES ${_MKL_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})

find_package_handle_standard_args(MKL DEFAULT_MSG
    MKL_INCLUDE_DIR MKL_LIBRARY MKL_MINIMAL_LIBRARY)

if(MKL_FOUND)
    set(MKL_INCLUDE_DIRS ${MKL_INCLUDE_DIR})
    set(MKL_LIBRARIES ${MKL_LIBRARY})
    set(MKL_MINIMAL_LIBRARIES ${MKL_LIBRARY})
endif()
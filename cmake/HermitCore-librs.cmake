# Add the Cargo project to build the Rust library.
set(HERMIT_RS "${CMAKE_BINARY_DIR}/hermit_rs/${HERMIT_ARCH}/${CARGO_BUILDTYPE_OUTPUT}/libhermit.a")
add_custom_target(hermit_rs
	COMMAND
		cargo run --package=xtask --target-dir ${CMAKE_BINARY_DIR}/hermit_rs --
		build --arch ${HERMIT_ARCH} --target-dir ${CMAKE_BINARY_DIR}/hermit_rs ${CARGO_BUILDTYPE_PARAMETER}  
		--no-default-features --features pci,smp,acpi,newlib
	WORKING_DIRECTORY
		${CMAKE_CURRENT_LIST_DIR}/../librs)

set(LWIP_SRC lwip/src)
add_kernel_module_sources("lwip"	"${LWIP_SRC}/api/*.c")
add_kernel_module_sources("lwip"	"${LWIP_SRC}/arch/*.c")
add_kernel_module_sources("lwip"	"${LWIP_SRC}/core/*.c")
add_kernel_module_sources("lwip"	"${LWIP_SRC}/core/ipv4/*.c")
add_kernel_module_sources("lwip"	"${LWIP_SRC}/core/ipv6/*.c")
add_kernel_module_sources("lwip"	"${LWIP_SRC}/netif/*.c")

get_kernel_modules(KERNEL_MODULES)
foreach(MODULE ${KERNEL_MODULES})
	get_kernel_module_sources(SOURCES ${MODULE})

	# maintain list of all objects that will end up in libhermit.a
	list(APPEND KERNEL_OBJECTS $<TARGET_OBJECTS:${MODULE}>)

	add_library(${MODULE} OBJECT ${SOURCES})

	# this is kernel code
	target_compile_definitions(${MODULE}
		PRIVATE -D__KERNEL__)

	target_compile_definitions(${MODULE}
		PRIVATE -DMAX_ARGC_ENVC=${MAX_ARGC_ENVC})

	target_compile_options(${MODULE}
		PRIVATE ${HERMIT_KERNEL_FLAGS})

	target_include_directories(${MODULE}
		PUBLIC ${HERMIT_KERNEL_INCLUDES})

	# suppress all LwIP compiler warnings. Not our code, so we cannot fix
	if("${MODULE}" STREQUAL "lwip")
		target_compile_options(${MODULE}
			PRIVATE -w)
	endif()
endforeach()

# Build all kernel modules into a single static library.
add_library(hermit-bootstrap STATIC ${KERNEL_OBJECTS})
set_target_properties(hermit-bootstrap PROPERTIES LINKER_LANGUAGE C)
add_dependencies(hermit-bootstrap hermit_rs)
set_target_properties(hermit-bootstrap PROPERTIES ARCHIVE_OUTPUT_NAME hermit)

# Post-process the static library.
add_custom_command(
	TARGET hermit-bootstrap POST_BUILD

	# Merge the Rust library into this static library.
	COMMAND
		${CMAKE_AR} x ${HERMIT_RS}
	COMMAND
		${CMAKE_AR} rcs $<TARGET_FILE:hermit-bootstrap> *.o
	COMMAND
		${CMAKE_COMMAND} -E remove *.o

	# Convert the combined library to osabi "Standalone"
	COMMAND
		${CMAKE_ELFEDIT} --output-osabi Standalone $<TARGET_FILE:hermit-bootstrap>

	# Copy libhermit.a into local prefix directory so that all subsequent
	# targets can link against the freshly built version (as opposed to
	# linking against the one supplied by the toolchain)
	COMMAND
		${CMAKE_COMMAND} -E make_directory ${LOCAL_PREFIX_ARCH_LIB_DIR}
	COMMAND
		${CMAKE_COMMAND} -E copy_if_different $<TARGET_FILE:hermit-bootstrap> ${LOCAL_PREFIX_ARCH_LIB_DIR}/

	# and also copy headers into local prefix
	COMMAND
		${CMAKE_COMMAND} -E make_directory ${LOCAL_PREFIX_ARCH_INCLUDE_DIR}/hermit
	COMMAND
		${CMAKE_COMMAND} -E copy_if_different ${CMAKE_SOURCE_DIR}/include/hermit/*.h ${LOCAL_PREFIX_ARCH_INCLUDE_DIR}/hermit/)

# Deploy libhermit.a and headers for package creation
install(TARGETS hermit-bootstrap
	DESTINATION ${HERMIT_ARCH}-hermit/lib
	COMPONENT bootstrap)

install(DIRECTORY include/hermit
	DESTINATION ${HERMIT_ARCH}-hermit/include/
	COMPONENT bootstrap
	FILES_MATCHING PATTERN *.h)

# Provide custom target to only install libhermit without its runtimes which is
# needed during the compilation of the cross toolchain
add_custom_target(hermit-bootstrap-install
	DEPENDS
		hermit-bootstrap
	COMMAND
		${CMAKE_COMMAND}
			-DCMAKE_INSTALL_COMPONENT=bootstrap
			-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
			-P cmake_install.cmake)

# The target 'hermit' includes the HermitCore kernel and several runtimes.
# Applications should depend on this target if they link against HermitCore.
add_custom_target(hermit
	DEPENDS hermit-bootstrap)

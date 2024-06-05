# Add the Cargo project to build the Rust library.
set(HERMIT_RS "${CMAKE_BINARY_DIR}/hermit_rs/${HERMIT_ARCH}/${CARGO_BUILDTYPE_OUTPUT}/libhermit.a")
add_custom_target(hermit_rs
	COMMAND
		cargo run --package=xtask --target-dir ${CMAKE_BINARY_DIR}/hermit_rs --
		build --arch ${HERMIT_ARCH} --target-dir ${CMAKE_BINARY_DIR}/hermit_rs ${CARGO_BUILDTYPE_PARAMETER}  
		--no-default-features --features pci,smp,acpi,newlib,tcp,dhcpv4
	WORKING_DIRECTORY
		${CMAKE_CURRENT_LIST_DIR}/../librs)

# Require hermit_rs to be built for hermit
add_custom_target(hermit
	DEPENDS hermit_rs

	# Copy libhermit.a into local prefix directory so that all subsequent
	# targets can link against the freshly built version (as opposed to
	# linking against the one supplied by the toolchain)
	
	COMMAND
		${CMAKE_COMMAND} -E make_directory ${LOCAL_PREFIX_ARCH_LIB_DIR}
	COMMAND
		${CMAKE_COMMAND} -E copy_if_different ${CMAKE_BINARY_DIR}/hermit_rs/${HERMIT_ARCH}/release/libhermit.a ${LOCAL_PREFIX_ARCH_LIB_DIR}/

	# and also copy headers into local prefix
	COMMAND
		${CMAKE_COMMAND} -E make_directory ${LOCAL_PREFIX_ARCH_INCLUDE_DIR}/hermit
	COMMAND
		${CMAKE_COMMAND} -E copy_if_different ${CMAKE_SOURCE_DIR}/include/hermit/*.h ${LOCAL_PREFIX_ARCH_INCLUDE_DIR}/hermit/)

# Provide custom target to only install libhermit without its runtimes which is
# needed during the compilation of the cross toolchain
add_custom_target(hermit_rs-install
	DEPENDS
		hermit_rs
	COMMAND
		${CMAKE_COMMAND}
			-DCMAKE_INSTALL_COMPONENT=bootstrap
			-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
			-P cmake_install.cmake
)

# Install libhermit.a and headers
install(FILES ${CMAKE_BINARY_DIR}/hermit_rs/${HERMIT_ARCH}/release/libhermit.a
		DESTINATION ${HERMIT_ARCH}-hermit/lib
		COMPONENT bootstrap)
	
install(DIRECTORY include/hermit
		DESTINATION ${HERMIT_ARCH}-hermit/include/
		COMPONENT bootstrap
		FILES_MATCHING PATTERN *.h)
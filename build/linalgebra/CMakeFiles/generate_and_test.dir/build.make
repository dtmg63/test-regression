# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.11

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Produce verbose output by default.
VERBOSE = 1

# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /Applications/CMake.app/Contents/bin/cmake

# The command to remove a file.
RM = /Applications/CMake.app/Contents/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/vk/software/test-regression

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/vk/software/test-regression/build

# Include any dependencies generated for this target.
include linalgebra/CMakeFiles/generate_and_test.dir/depend.make

# Include the progress variables for this target.
include linalgebra/CMakeFiles/generate_and_test.dir/progress.make

# Include the compile flags for this target's objects.
include linalgebra/CMakeFiles/generate_and_test.dir/flags.make

linalgebra/CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.o: linalgebra/CMakeFiles/generate_and_test.dir/flags.make
linalgebra/CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.o: ../linalgebra/tests/generate_and_test.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vk/software/test-regression/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object linalgebra/CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.o"
	cd /Users/vk/software/test-regression/build/linalgebra && /usr/local/opt/llvm/bin/clang++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.o -c /Users/vk/software/test-regression/linalgebra/tests/generate_and_test.cpp

linalgebra/CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.i"
	cd /Users/vk/software/test-regression/build/linalgebra && /usr/local/opt/llvm/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vk/software/test-regression/linalgebra/tests/generate_and_test.cpp > CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.i

linalgebra/CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.s"
	cd /Users/vk/software/test-regression/build/linalgebra && /usr/local/opt/llvm/bin/clang++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vk/software/test-regression/linalgebra/tests/generate_and_test.cpp -o CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.s

# Object files for target generate_and_test
generate_and_test_OBJECTS = \
"CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.o"

# External object files for target generate_and_test
generate_and_test_EXTERNAL_OBJECTS =

linalgebra/generate_and_test: linalgebra/CMakeFiles/generate_and_test.dir/tests/generate_and_test.cpp.o
linalgebra/generate_and_test: linalgebra/CMakeFiles/generate_and_test.dir/build.make
linalgebra/generate_and_test: linalgebra/liblinalgebra.a
linalgebra/generate_and_test: linalgebra/CMakeFiles/generate_and_test.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/vk/software/test-regression/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable generate_and_test"
	cd /Users/vk/software/test-regression/build/linalgebra && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/generate_and_test.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
linalgebra/CMakeFiles/generate_and_test.dir/build: linalgebra/generate_and_test

.PHONY : linalgebra/CMakeFiles/generate_and_test.dir/build

linalgebra/CMakeFiles/generate_and_test.dir/clean:
	cd /Users/vk/software/test-regression/build/linalgebra && $(CMAKE_COMMAND) -P CMakeFiles/generate_and_test.dir/cmake_clean.cmake
.PHONY : linalgebra/CMakeFiles/generate_and_test.dir/clean

linalgebra/CMakeFiles/generate_and_test.dir/depend:
	cd /Users/vk/software/test-regression/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/vk/software/test-regression /Users/vk/software/test-regression/linalgebra /Users/vk/software/test-regression/build /Users/vk/software/test-regression/build/linalgebra /Users/vk/software/test-regression/build/linalgebra/CMakeFiles/generate_and_test.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : linalgebra/CMakeFiles/generate_and_test.dir/depend


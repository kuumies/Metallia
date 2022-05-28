# Metallia
Metal API testing

CMake + Cocoa API + Metal API testing.

Project uses CMake to compile and link the metal shaders. It also installs the
shaders binary into bundle.

QtCreator must be able to execute 'xcrun' command. It is not available by
default (comes with XCode or maybe with XCode Command Line Tools).

## Building

Tested with Apple M1 chip laptop

1) Open  Qt Creator version 5.0.2 or later
2) Load the source by opening the CMakeLists.txt as project
3) Use building kit with 64 bit Apple Clang as compiler. For me QtCreator had 
   setup it automatically with the name 'Desktop (x86-darwin-generic-mach_o-64bit)'.
4) From Build Steps select 'all' and 'install'
5) Build the project and run the generated bundle
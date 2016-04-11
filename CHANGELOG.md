# Release Notes

## Bake 0.2.7
### Bug Fixes
* Check for gstat to be installed before allowing bake firmware
* Enforce firmware is stored in the firmware dir

## Bake 0.2.6
### Bug Fixes
* added sudo askpass support for using bake burn on linux

## Bake 0.2.5
### Bug Fixes
* clean the release on every call to `bake firmware` to prevent cache bloat

## Bake 0.2.4
### Bug Fixes
* force the install of rebar >= 2.6.0 for use with REBAR_TARGET_ARCH to ensure cross compiling works properly

## Bake 0.2.3
### Bug Fixes
* update lock file after initial system unpacks

## Bake 0.2.2
### Enhancements
* Added Bake burn with support from fwup 0.5.2
* All unmatched options passed to bake burn will be forwarded to fwup

### Bug Fixes
* Persist deps between bake firmware commands
* Enabled support for standard_io input into commands like bake firmware

## Bake 0.2.1
### Bug Fixes
* Stopped using erl_tar and depend on system tar instead

## Bake 0.2.0
### Enhancements
* Users can set default_target globally
* Added bake help. In addition to displaying option menus when the command is invalid, a user can ask for more information about a module, `bake help system` will show more informations like systems
* Added ability to clean all systems and toolchains by passing --all to `bake system clean --all` and `bake toolchain clean --all`
* Consolidated BakeUtils and BakeDaemon into Bake.

### Bug Fixes
* Nerves adapter checks return status of environment source and will exit on error.
* Support for 0.6.0 toolchains

## Bake 0.1.2
### Enhancements
* Bake now supports running on linux

## Bake 0.1.1
### Bug Fixes
* Changed tar command for toolchains to support linux
* Make escript_path location variable on platform

## Bake 0.1.0
### Enhancements
* Added System and toolchain versioning. This change will break you existing Bakefile. You will need to change your bake file to contain the semver requirement for the recipe used in your target
```elixir
# Old way
target :bbb,
  recipe: "nerves/bbb"
# New way
target :bbb,
  recipe: {"nerves/bbb", "~> 0.1"}
```
* Added `bake system update [--target [all | target_name]]`
* Fetching systems and toolchain will now check if the current version is already downloaded. You will need to call `bake system clean` and `bake system get` to force a re download of the system.

## Bake 0.0.4
### Enhancements
* Added `default_system` to `Bake.Config`. If defined, it will be used ad the target if the --target flag is omitted
* `--target --all` is now `--target all`
* Updated escript to elixir 1.2.0

### Bug Fixes
* [nerves-adapter] When switching targets mix deps need to be cleaned and compiled
* [nerves-adapter] Fixed bash issue when sourcing ENV for nerves system

## Bake 0.0.3
### Enhancements

* Added commands for system management
    * bake system clean [—target [—all | target_name] —bakefile path/to/bakefile]
* Added commands for toolchain management
    * bake toolchain clean [—target [—all | target_name] —bakefile path/to/bakefile]

### Bug Fixes

* bake firmware —toolchain —all is fixed and enumerates all recipes now


## Bake 0.0.2
### Enhancements

* Added commands for system management
    * bake system get [—target [—all | target_name] —bakefile path/to/bakefile]
* Added commands for toolchain management
    * bake toolchain get [—target [—all | target_name] —bakefile path/to/bakefile]


## Bake 0.0.1
### Enhancements

* Initial Release
* Added commands for user management
    * bake user register
    * bake user test
    * bake user auth
    * bake user deauth
    * bake user whoami
* Added commands for firmware
    * bake firmware [—target [—all | target_name] —bakefile path/to/bakefile]
* Automated release system as mix bake.release will create and make permanent a new version of bake cli to bakeware.

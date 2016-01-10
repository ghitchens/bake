# Release Notes

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

# Release Notes

### Bake 0.0.2-dev

## Enhancements

* Added commands for system management
    * bake system get [—target [—all | target_name] —bakefile path/to/bakefile]
* Added commands for toolchain management
    * bake toolchain get [—target [—all | target_name] —bakefile path/to/bakefile]


### Bake 0.0.1

## Enhancements

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

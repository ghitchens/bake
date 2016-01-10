# Bake

Bake is an elixir escript which produces a command line interface tool for working with bakeware.

## Installation

To install bake execute the following in your terminal
```
ruby -e "$(curl -fsSL https://bakeware.herokuapp.com/bake/install)"
```

This script performs the following actions
* Install the latest fwup
* Install squashfs tools
* Install the bake command to /usr/local/bin
* Create configuration directory for BAKE_HOME @ ~/.bake

## Usage

Bake is a multi-target toolkit for building embedded applications using nerves. Before we compile our first project lets discuss some of the terminology we use to describe the bakeware / nerves workflow.

### Terminology

* Target - A specific combination of recipe, application configuration, and assembly options that results in firmware
* Recipe - Configuration which specifies a specific toolchain and system
* Toolchain - A set of compilers, libraries, and tools that build code for a particular architecture. The output of nerves-toolchain. Built by the bake server, distribued in tarballs
* System - The output of building nerves-sdk using a particular toolchain specified by a recipe.   Produced by the bake server - a tarball.   Includes header files, libraries, and a starting squashfs image that will be combined with the built application during assembly to produce the firmware
* Assembly - The process of combining a built application, a rootfs, and other options (like fwup.conf) into firmware

### Bakefile

To use bake for compiling firmware for nerves apps you need to add a `Bakefile` to your project. This file should be located in the root of the project. It is used to describe to bake information about how to assemble firmware.

```elixir
use Bake.Config

platform :nerves
default_target :rpi2

target :rpi2,
  recipe: "nerves/rpi2"
```

In this example we are telling `bake` that we want to be able to produce firmware for a raspberry pi2. The bakefile needs at least 1 target defined, but you can specify as many targets as you want to build firmware for. The target atom can be anything you desire. It is used when executing commands as a label for your purposes. By declaring a `default_target` if we omit the `--target` flag in commands, the default target will be used.



### Recipes
The recipe needs to be an active bakeware shared recipe.
Currently, nerves shares the following recipes.
* nerves/bbb
* nerves/rpi
* nerves/rpi2

### Systems and Toolchains

To compile firmware you will need to have bake pull the system and toolchain images required to build the recipes. Systems and toolchains are shared globally and therefore, if you have already pulled the systems and toolchains for another nerves app that has targets who use the same recipes, you do not need to pull these assets again.

Systems and toolchains for nerves are downloaded to NERVES_HOME which is typically located at `~/.nerves`.
* Systems - `NERVES_HOME/systems`
* Toolchains `NERVES_HOME/toolchains`

```
bake system get
```

If your bakefile declares multiple targets and you want to get the systems for all targets you can run
```
bake system get --targetm all
```

Toolchains can get downloaded in a similar fashion.
```
bake toolchain get
```

### Application Configuration

The NERVES_TARGET environment variable gets set by bake, such that mix.exs could use NERVES_TARGET to determine custom configuration per target.  This can be used for configuring the build process.  

Examples

Users can import target specific configs by adding the following to the config.exs file

```elixir
# config/config.exs
target = System.get_env("NERVES_TARGET")
if target != nil, do: import_config "target/#{target}.exs"
```
This example would pull the target specific application configuration from `config/target/#{target}.exs`
The nerves example app blinky illustrates this need. blinky uses the dep `nerves_io_led` which reads from `/sys/class/leds`. Different targets have different labels for their led indicators.
For example,

Raspberry Pi 2
```elixir
# config/rpi2/config.exs
config :nerves_io_led, names: [ red: "led0", green: "led1" ]
```

BeagleBone Black
```elixir
# config/bbb/config.exs
config :blinky, led_list: [ :led0, :led1, :led2, :led3 ]

config :nerves_io_led, names: [
  led0: "beaglebone:green:usr0",
  led1: "beaglebone:green:usr1",
  led2: "beaglebone:green:usr2",
  led3: "beaglebone:green:usr3"
]
```

### Firmware

Once you have downloaded a system and a toolchain you can bake your nerves project into firmware. During this process bake will call the nerves firmware adapter. It will compile the elixir nerves application into the linux system using the toolchain to produce firmware.

```
bake firmware
```

### Burn SD
To run your firmware on a target device, you will need to burn it to an SD card. You can do this using the `fwup` tool.

On Mac os you will need to use sudo as the tool requires elevated permissions in order to find and format the sd card inserted in your computer.

This example assumes that you are running the nerves blinky app example and you want to burn the firmware image for the target rpi2. You will need to change this to burn your own projects
```
sudo fwup -a -i _images/blinky-rpi2.fw -t complete
```

This command is represented as these parts.
```
sudo fwup -a -i _images/{otp_app_name}-{target}.fw -t complete
```

use Bake.Config.Recipe

name :bbb
platform :nerves
arch :arm

description """
Minimal install image for BeagleBone Black
"""

version "0.0.1"
maintainers [
  "Justin Schneck"
]

toolchain {"nerves", "arm-unknown-linux-gnueabihf", "0.5.0"}

meta [
  gcc:    [version: "4.9"],
  erlang: [version: "18.1"],
  elixir: [version: "1.1.1"]
]

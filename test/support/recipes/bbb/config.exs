use Bake.Config.Recipe

name :bbb
platform :nerves
target :arm

description """
Minimal install image for BeagleBone Black
"""

version "0.0.1"
maintainers [
  "Justin Schneck",
  "Frank Hunleth",
  "Garth Hitchens",
  "Chris Dutton"
]

toolchain [
  {"glibc", "4.9"},
  {"erlang", "18.1"},
  {"elixir", "1.1.1"}
]

meta [
  kernel: [version: "3.8"],
  gcc:    [version: "4.9"],
  erlang: [version: "18.1"],
  elixir: [version: "1.1.1"]
]

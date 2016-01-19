use Bake.Config.Recipe

name :bbb
platform :nerves
arch :arm

description """
Minimal install image for BeagleBone Black
"""

version "0.0.1"
maintainers [
  "Justin Schneck",
]

toolchain [
  {"glibc", "4.9"},
  {"erlang", "18.2"},
  {"elixir", "1.1.1"}
]

meta [
  kernel: [version: "3.8"],
  gcc:    [version: "4.9"],
  erlang: [version: "18.2"],
  elixir: [version: "1.1.1"]
]

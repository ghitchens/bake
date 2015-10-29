use Bake.Toolchain.Config

platform :nerves
config :gcc,
  host_platform: "mac",
  host_arch: "x86_64",
  target_arch: "arm"

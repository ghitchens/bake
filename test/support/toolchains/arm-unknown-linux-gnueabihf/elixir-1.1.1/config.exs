use Bake.Config.Toolchain

platform :nerves

toolchain :elixir,
  version: "1.1.1",
  target: "arm-unknown-linux-gnueabihf",
  host: "Darwin-x86_64"

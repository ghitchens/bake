use Bake.Config

platform :nerves

target :bbb,
  recipe: "bbb_default"

target :rpi,
  recipe: "rpi_default"

target :rpi2,
  recipe: "rpi2_default"

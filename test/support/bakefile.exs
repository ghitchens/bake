use Bake.Config

platform :nerves

target :bbb,
  recipe: "nerves/bbb"

target :rpi,
  recipe: "nerves/rpi"

target :rpi2,
  recipe: "nerves/rpi2"

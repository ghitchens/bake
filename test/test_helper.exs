ExUnit.start exclude: [:skip]

alias BakeTest.Case

# Set up temp directory
File.rm_rf!(Case.tmp_path)
File.mkdir_p!(Case.tmp_path)

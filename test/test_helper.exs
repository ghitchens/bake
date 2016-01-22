ExUnit.start exclude: [:skip]

alias BakeTest.Case
alias BakeTest.Bakeware

# Set up temp directory
File.rm_rf!(Case.tmp_path)
File.mkdir_p!(Case.tmp_path)

unless :integration in ExUnit.configuration[:exclude] do
  Bakeware.init
  Bakeware.start

  
end

defmodule Bake.Shell do
  def info(output),
    do: Mix.shell.info(output)

  def warn(output),
    do: Mix.shell.info([IO.ANSI.yellow, output, IO.ANSI.reset])

  def system(output),
    do: Mix.shell.info([IO.ANSI.green, output, IO.ANSI.reset])
    
  def error(output),
    do: Mix.shell.error(output)

  def error_exit(output) do
    reraise(%Bake.Error{message: output}, [])
  end

  def yes?(output),
    do: Mix.shell.yes?(output)

  def prompt(output),
    do: Mix.shell.prompt(output)
end

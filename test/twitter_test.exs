defmodule TwitterMainTest do
  use ExUnit.Case
  doctest TwitterMain

  test "greets the world" do
    assert TwitterMain.hello() == :world
  end
end

defmodule IntroGenStageTest do
  use ExUnit.Case
  doctest IntroGenStage

  test "greets the world" do
    assert IntroGenStage.hello() == :world
  end
end

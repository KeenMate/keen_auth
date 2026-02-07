defmodule TestAppWeb.ErrorHTML do
  @moduledoc """
  Basic error pages for the test app.
  """

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

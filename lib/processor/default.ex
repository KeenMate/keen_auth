defmodule KeenAuth.Processor.Default do
  @behaviour KeenAuth.Processor

  def process(conn, _provider, oauth_response) do
    {:ok, conn, oauth_response}
  end
end

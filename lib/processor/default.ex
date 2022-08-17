defmodule KeenAuth.Processor.Default do
  @behaviour KeenAuth.Processor

  def process(conn, _provider, mapped_user, oauth_response) do
    {:ok, conn, mapped_user, oauth_response}
  end
end

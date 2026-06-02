defmodule ScapedWeb.LLMController do
  use ScapedWeb, :controller
  require Logger

  def generate_text(conn, %{"model" => model, "messages" => messages}) do
    Logger.info(inspect(messages))

    ms =
      Enum.map(messages, fn m ->
        case m do
          %{"role" => "system", "content" => c} -> ReqLLM.Context.system(c)
          %{"role" => "user", "content" => c} -> ReqLLM.Context.user(c)
          %{"role" => _, "content" => c} -> ReqLLM.Context.assistant(c)
        end
      end)

    text = ReqLLM.generate_text!(model, ms, max_tokens: 1000)

    json(conn, text)
  end
end

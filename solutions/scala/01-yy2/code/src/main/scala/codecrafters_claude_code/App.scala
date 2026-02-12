package codecrafters_claude_code

import java.net.URI
import java.net.http.{HttpClient, HttpRequest, HttpResponse}

object Main {
  def main(args: Array[String]): Unit = {
    val prompt = args.sliding(2).collectFirst { case Array("-p", p) => p }
      .getOrElse(throw new RuntimeException("-p flag is required"))

    val apiKey = sys.env.getOrElse("OPENROUTER_API_KEY",
      throw new RuntimeException("OPENROUTER_API_KEY is not set"))
    val baseUrl = sys.env.getOrElse("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

    val body = ujson.Obj(
      "model" -> "anthropic/claude-haiku-4.5",
      "messages" -> ujson.Arr(
        ujson.Obj("role" -> "user", "content" -> prompt)
      )
    )

    val client = HttpClient.newBuilder()
      .version(HttpClient.Version.HTTP_1_1)
      .build()

    val request = HttpRequest.newBuilder()
      .uri(URI.create(s"$baseUrl/chat/completions"))
      .header("Authorization", s"Bearer $apiKey")
      .header("Content-Type", "application/json")
      .POST(HttpRequest.BodyPublishers.ofString(ujson.write(body)))
      .build()

    val response = client.send(request, HttpResponse.BodyHandlers.ofString())

    val json = ujson.read(response.body())
    val choices = json("choices").arr
    if (choices.isEmpty) throw new RuntimeException("no choices in response")

    println(choices(0)("message")("content").str)
  }
}

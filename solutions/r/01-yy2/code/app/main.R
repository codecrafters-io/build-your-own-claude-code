library(httr2)
library(jsonlite)

args <- commandArgs(trailingOnly = TRUE)

# Parse -p flag
if (length(args) < 2 || args[1] != "-p") {
  stop("error: -p flag is required")
}

prompt <- args[2]

api_key <- Sys.getenv("OPENROUTER_API_KEY")
base_url <- Sys.getenv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")

if (api_key == "") {
  stop("OPENROUTER_API_KEY is not set")
}

body <- list(
  model = "anthropic/claude-haiku-4.5",
  messages = list(
    list(role = "user", content = prompt)
  )
)

response <- request(paste0(base_url, "/chat/completions")) |>
  req_headers(
    "Authorization" = paste("Bearer", api_key),
    "Content-Type" = "application/json"
  ) |>
  req_body_json(body) |>
  req_perform()

result <- resp_body_json(response)

if (length(result$choices) == 0) {
  stop("no choices in response")
}

cat(result$choices[[1]]$message$content)

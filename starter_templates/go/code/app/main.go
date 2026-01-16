package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/option"
)

func main() {
	// You can use print statements as follows for debugging, they'll be visible when running tests.
	fmt.Println("Logs from your program will appear here!")

	// Get the prompt from the -p flag
	var prompt string
	flag.StringVar(&prompt, "p", "", "Prompt to send to LLM")
	flag.Parse()

	if prompt == "" {
		fmt.Fprintf(os.Stderr, "error: -p flag is required\n")
		os.Exit(1)
	}

	// Get API key and base URL from environment variables
	apiKey := os.Getenv("OPENROUTER_API_KEY")
	if apiKey == "" {
		fmt.Fprintf(os.Stderr, "error: OPENROUTER_API_KEY environment variable is not set\n")
		os.Exit(1)
	}

	baseURL := os.Getenv("OPENROUTER_BASE_URL")
	if baseURL == "" {
		fmt.Fprintf(os.Stderr, "error: OPENROUTER_BASE_URL environment variable is not set\n")
		os.Exit(1)
	}

	// Create OpenAI client configured for OpenRouter
	client := openai.NewClient(
		option.WithAPIKey(apiKey),
		option.WithBaseURL(baseURL),
	)

	// Make the API request
	chatCompletion, err := client.Chat.Completions.New(
		context.Background(),
		openai.ChatCompletionNewParams{
			Model: "openai/gpt-4o-mini",
			Messages: []openai.ChatCompletionMessageParamUnion{
				{
					OfUser: &openai.ChatCompletionUserMessageParam{
						Content: openai.ChatCompletionUserMessageParamContentUnion{
							OfString: openai.String(prompt),
						},
					},
				},
			},
		},
	)

	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	// Check if we got a response
	if len(chatCompletion.Choices) == 0 {
		fmt.Fprintf(os.Stderr, "error: no choices in response\n")
		os.Exit(1)
	}

	// TODO: Uncomment the code below to pass the first stage
	// // Print the response content
	// content := chatCompletion.Choices[0].Message.Content
	// if content == "" {
	// 	fmt.Fprintf(os.Stderr, "error: empty content in response\n")
	// 	os.Exit(1)
	// }

	// fmt.Print(content)
}

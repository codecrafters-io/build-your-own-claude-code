package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/openai/openai-go/v3"
	"github.com/openai/openai-go/v3/option"
)

// Ensures gofmt does not remove the 'context', 'openai', and 'openai/option' import
// Feel free to remove this
var _ = context.Background
var _ = openai.NewClient
var _ = option.WithAPIKey

func main() {
	var prompt string
	flag.StringVar(&prompt, "p", "", "Prompt to send to LLM")
	flag.Parse()

	client := openai.NewClient(
		option.WithAPIKey(os.Getenv("OPENROUTER_API_KEY")),
		option.WithBaseURL(os.Getenv("OPENROUTER_BASE_URL")),
	)
	resp, err := client.Chat.Completions.New(context.Background(),
		openai.ChatCompletionNewParams{
			Model: "anthropic/claude-haiku-4.5",
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
	fmt.Print(resp.Choices[0].Message.Content)
}

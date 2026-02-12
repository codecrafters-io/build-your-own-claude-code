<?php

require_once __DIR__ . '/../vendor/autoload.php';

$options = getopt("p:");

if (!isset($options['p']) || $options['p'] === '') {
    fwrite(STDERR, "error: -p flag is required\n");
    exit(1);
}

$prompt = $options['p'];
$apiKey = getenv('OPENROUTER_API_KEY');
$baseUrl = getenv('OPENROUTER_BASE_URL') ?: 'https://openrouter.ai/api/v1';

if (!$apiKey) {
    fwrite(STDERR, "OPENROUTER_API_KEY is not set\n");
    exit(1);
}

$client = OpenAI::factory()
    ->withApiKey($apiKey)
    ->withBaseUri($baseUrl)
    ->make();

$response = $client->chat()->create([
    'model' => 'anthropic/claude-haiku-4.5',
    'messages' => [
        ['role' => 'user', 'content' => $prompt],
    ],
]);

if (empty($response->choices)) {
    fwrite(STDERR, "no choices in response\n");
    exit(1);
}

// You can use print statements as follows for debugging, they'll be visible when running tests.
fwrite(STDERR, "Logs from your program will appear here!\n");

// TODO: Uncomment the following line to pass the first stage
// echo $response->choices[0]->message->content;

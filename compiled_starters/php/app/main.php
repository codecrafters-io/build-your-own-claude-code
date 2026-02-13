<?php

error_reporting(E_ALL);
ini_set('display_errors', 'stderr');

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

$ch = curl_init("$baseUrl/chat/completions");
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Content-Type: application/json',
        "Authorization: Bearer $apiKey",
    ],
    CURLOPT_POSTFIELDS => json_encode([
        'model' => 'anthropic/claude-haiku-4.5',
        'messages' => [
            ['role' => 'user', 'content' => $prompt],
        ],
    ]),
]);

$response = curl_exec($ch);
if ($response === false) {
    fwrite(STDERR, "curl error: " . curl_error($ch) . "\n");
    exit(1);
}

$data = json_decode($response, true);
if (empty($data['choices'])) {
    fwrite(STDERR, "no choices in response\n");
    exit(1);
}

// You can use print statements as follows for debugging, they'll be visible when running tests.
fwrite(STDERR, "Logs from your program will appear here!\n");

// TODO: Uncomment the following line to pass the first stage
// echo $data['choices'][0]['message']['content'];

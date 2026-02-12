{-# OPTIONS_GHC -Wno-unused-imports -Wno-unused-local-binds -Wno-unused-matches #-}

module Main (main) where

import System.Environment (getArgs, lookupEnv)
import System.IO (hPutStrLn, stderr)
import System.Process (readProcess)
import Data.List (isPrefixOf)

main :: IO ()
main = do
    args <- getArgs
    let prompt = case args of
          "-p" : p : _ -> p
          _            -> error "-p flag is required"

    apiKey <- lookupEnv "OPENROUTER_API_KEY"
    baseUrl <- lookupEnv "OPENROUTER_BASE_URL"

    let key = maybe (error "OPENROUTER_API_KEY is not set") id apiKey
        url = maybe "https://openrouter.ai/api/v1" id baseUrl
        body = "{\"model\":\"anthropic/claude-haiku-4.5\",\"messages\":[{\"role\":\"user\",\"content\":" ++ encodeJsonString prompt ++ "}]}"

    response <- readProcess "curl"
        [ "-s", "-X", "POST"
        , url ++ "/chat/completions"
        , "-H", "Content-Type: application/json"
        , "-H", "Authorization: Bearer " ++ key
        , "-d", body
        ] ""

    let content = extractContent response

    case content of
      Nothing -> error "No choices in response"
      Just _  -> return ()

    putStr (maybe "" id content)

encodeJsonString :: String -> String
encodeJsonString s = "\"" ++ concatMap escape s ++ "\""
  where
    escape '"'  = "\\\""
    escape '\\' = "\\\\"
    escape '\n' = "\\n"
    escape '\r' = "\\r"
    escape '\t' = "\\t"
    escape c    = [c]

extractContent :: String -> Maybe String
extractContent s = do
    rest1 <- findAfter "\"choices\"" s
    rest2 <- findAfter "\"content\"" rest1
    rest3 <- findAfter ":" rest2
    extractJsonStringValue (dropWhile (`elem` " \n\r\t") rest3)

findAfter :: String -> String -> Maybe String
findAfter _ [] = Nothing
findAfter needle haystack@(_:cs)
    | needle `isPrefixOf` haystack = Just (drop (length needle) haystack)
    | otherwise = findAfter needle cs

extractJsonStringValue :: String -> Maybe String
extractJsonStringValue ('"':rest) = Just (go rest)
  where
    go ('\\':'"':xs)  = '"' : go xs
    go ('\\':'\\':xs) = '\\' : go xs
    go ('\\':'/':xs)  = '/' : go xs
    go ('\\':'n':xs)  = '\n' : go xs
    go ('\\':'r':xs)  = '\r' : go xs
    go ('\\':'t':xs)  = '\t' : go xs
    go ('\\':'b':xs)  = '\b' : go xs
    go ('\\':'f':xs)  = '\f' : go xs
    go ('"':_)        = []
    go (x:xs)         = x : go xs
    go []             = []
extractJsonStringValue _ = Nothing

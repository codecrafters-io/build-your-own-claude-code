{-# OPTIONS_GHC -Wno-unused-imports -Wno-unused-local-binds -Wno-unused-matches #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Data.Aeson (Value(..), object, (.=), encode, decode)
import qualified Data.Aeson.KeyMap as KM
import qualified Data.ByteString.Char8 as BS
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.Vector as V
import Network.HTTP.Simple
import System.Environment (getArgs, lookupEnv)
import System.IO (hPutStrLn, stderr)

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

    initReq <- parseRequest (url ++ "/chat/completions")
    let req = setRequestMethod "POST"
            $ setRequestHeader "Content-Type" ["application/json"]
            $ setRequestHeader "Authorization" [BS.pack ("Bearer " ++ key)]
            $ setRequestBodyLBS (encode $ object
                [ "model" .= ("anthropic/claude-haiku-4.5" :: T.Text)
                , "messages" .= [object ["role" .= ("user" :: T.Text), "content" .= T.pack prompt]]
                ])
            $ initReq

    response <- httpLBS req

    let Just (Object obj) = decode (getResponseBody response)
        Just (Array choices) = KM.lookup "choices" obj

    if V.null choices
      then error "No choices in response"
      else return ()

    let Object choice = V.head choices
        Just (Object msg) = KM.lookup "message" choice
        Just (String content) = KM.lookup "content" msg

    -- You can use print statements as follows for debugging, they'll be visible when running tests.
    hPutStrLn stderr "Logs from your program will appear here!"

    -- TODO: Uncomment the line below to pass the first stage
    -- TIO.putStr content

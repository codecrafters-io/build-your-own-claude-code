{-# OPTIONS_GHC -Wno-unused-imports -Wno-unused-local-binds -Wno-unused-matches #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Data.Aeson (Value(..), object, (.=), encode, decode)
import qualified Data.Aeson.KeyMap as KM
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BLC
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.IO as TIO
import qualified Data.Vector as V
import System.Environment (getArgs, lookupEnv)
import System.IO (hPutStrLn, stderr)
import System.Process (readProcess)

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
        body = BLC.unpack $ encode $ object
            [ "model" .= ("anthropic/claude-haiku-4.5" :: T.Text)
            , "messages" .= [object ["role" .= ("user" :: T.Text), "content" .= T.pack prompt]]
            ]

    response <- readProcess "curl"
        [ "-s", "-X", "POST"
        , url ++ "/chat/completions"
        , "-H", "Content-Type: application/json"
        , "-H", "Authorization: Bearer " ++ key
        , "-d", body
        ] ""

    let responseBS = BL.fromStrict $ TE.encodeUtf8 $ T.pack response
        Just (Object obj) = decode responseBS
        Just (Array choices) = KM.lookup "choices" obj

    if V.null choices
      then error "No choices in response"
      else return ()

    let Object choice = V.head choices
        Just (Object msg) = KM.lookup "message" choice
        Just (String content) = KM.lookup "content" msg

    TIO.putStr content

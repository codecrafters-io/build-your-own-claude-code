(ns claude-code.core
  (:require [clj-http.client :as http]
            [cheshire.core :as json]
            [clojure.tools.cli :refer [parse-opts]])
  (:gen-class))

(def cli-options
  [["-p" "--prompt PROMPT" "Prompt to send to LLM"]])

(defn -main [& args]
  (let [{:keys [options]} (parse-opts args cli-options)
        prompt (:prompt options)
        api-key (System/getenv "OPENROUTER_API_KEY")
        base-url (or (System/getenv "OPENROUTER_BASE_URL") "https://openrouter.ai/api/v1")]

    (when-not api-key
      (throw (RuntimeException. "OPENROUTER_API_KEY is not set")))

    (when-not prompt
      (throw (RuntimeException. "Prompt must not be empty")))

    (let [response (http/post (str base-url "/chat/completions")
                              {:headers {"Authorization" (str "Bearer " api-key)
                                         "Content-Type" "application/json"}
                               :body (json/generate-string
                                       {:model "anthropic/claude-haiku-4.5"
                                        :messages [{:role "user" :content prompt}]})
                               :as :json})
          choices (get-in response [:body :choices])]

      (when (empty? choices)
        (throw (RuntimeException. "no choices in response")))

      ;; You can use print statements as follows for debugging, they'll be visible when running tests.
      (binding [*out* *err*]
        (println "Logs from your program will appear here!"))

      ;; TODO: Uncomment the line below to pass the first stage
      ;; (print (get-in (first choices) [:message :content]))
      )))

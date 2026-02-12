let () =
  let prompt = ref "" in
  Arg.parse [ ("-p", Arg.Set_string prompt, "Prompt to send to LLM") ] (fun _ -> ()) "";

  if !prompt = "" then (
    prerr_endline "Prompt must not be empty";
    exit 1);

  let api_key =
    match Sys.getenv_opt "OPENROUTER_API_KEY" with
    | Some k -> k
    | None ->
      prerr_endline "OPENROUTER_API_KEY is not set";
      exit 1
  in
  let base_url =
    match Sys.getenv_opt "OPENROUTER_BASE_URL" with
    | Some u -> u
    | None -> "https://openrouter.ai/api/v1"
  in

  let uri = Uri.of_string (base_url ^ "/chat/completions") in
  let headers =
    Cohttp.Header.of_list
      [
        ("Content-Type", "application/json");
        ("Authorization", "Bearer " ^ api_key);
      ]
  in
  let request_body =
    `Assoc
      [
        ("model", `String "anthropic/claude-haiku-4.5");
        ( "messages",
          `List
            [
              `Assoc
                [ ("role", `String "user"); ("content", `String !prompt) ];
            ] );
      ]
    |> Yojson.Safe.to_string
  in

  let _response_body =
    Lwt_main.run
      (let body = Cohttp_lwt.Body.of_string request_body in
       Cohttp_lwt_unix.Client.post ~headers ~body uri
       |> Lwt.bind (fun (_resp, body) -> Cohttp_lwt.Body.to_string body))
  in

  (* You can use print statements as follows for debugging, they'll be visible when running tests. *)
  Printf.eprintf "Logs from your program will appear here!\n";

  (* TODO: Uncomment the lines below to pass the first stage *)
  (* let json = Yojson.Safe.from_string _response_body in *)
  (* let content = Yojson.Safe.Util.(json |> member "choices" |> index 0 |> member "message" |> member "content" |> to_string) in *)
  (* print_string content; *)
  ()

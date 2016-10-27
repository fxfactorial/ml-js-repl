type eval_lang = OCaml | JavaScript

let eval_mode = ref JavaScript

let eval_ocaml code =
  let as_buf = Lexing.from_string code in
  let parsed = !Toploop.parse_toplevel_phrase as_buf in
  let d =
    Format.asprintf "%a" (fun ppf x -> ignore (Toploop.execute_phrase true ppf x))
  in
  d parsed |> String.trim

let prompt_name () =
  match !eval_mode with
  | JavaScript -> "JavaScript-REPL> "
  | OCaml -> "OCaml-REPL> "

let rec user_input prompt cb =
  match LNoise.linenoise prompt with
  | None -> ()
  | Some v ->
    cb v;
    user_input (prompt_name ()) cb

let () =
  Toploop.initialize_toplevel_env ();
  let vm = new JavaScriptCore.virtual_machine () in
  LNoise.set_hints_callback (fun line ->
      if line <> "#repl " then None
      else Some (" <language_to_eval> (Can be `ocaml` or `javascript`)",
                 LNoise.Cyan,
                 true)
    );
  LNoise.history_load ~filename:"history.txt" |> ignore;
  LNoise.history_set ~max_length:100 |> ignore;
  [
    "\027[33mThis is an OCaml, JavaScript repl, starts in JavaScript mode.\027[m";
    "\027[31mType #repl and set what language you want to evaluate\n\027[m";
  ]
  |> List.iter print_endline;
  (fun from_user ->
     if from_user = "quit" then exit 0;
     LNoise.history_add from_user |> ignore;
     LNoise.history_save ~filename:"history.txt" |> ignore;

     if Astring.String.is_prefix "#repl" from_user
     then begin
     let chopped =
       Astring.String.cuts ~empty:true ~sep:" " from_user
     in
     let choice = List.nth chopped 1 in
     match choice with
     | "ocaml" -> eval_mode := OCaml
     | "javascript" -> eval_mode := JavaScript
     | _ ->
       "Only know about ocaml or javascript as valid repl evaluation choices"
       |> print_endline
     end
     else begin
       (match !eval_mode with
        | OCaml ->
          if Astring.String.is_suffix ";;" from_user
          then eval_ocaml from_user
          else eval_ocaml (from_user ^ ";;")
        | JavaScript -> vm#evaluate_script from_user)
       |> print_endline
     end
  )
  |> user_input (prompt_name ())

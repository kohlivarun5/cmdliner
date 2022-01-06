(*---------------------------------------------------------------------------
   Copyright (c) 2011 The cmdliner programmers. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

type term_escape =
  [ `Error of bool * string
  | `Help of Cmdliner_manpage.format * string option ]

type 'a parser =
  Cmdliner_info.eval -> Cmdliner_cline.t ->
  ('a, [ `Parse of string | term_escape ]) result

type 'a t = Cmdliner_info.args * 'a parser

let const v = Cmdliner_info.Args.empty, (fun _ _ -> Ok v)
let app (args_f, f) (args_v, v) =
  Cmdliner_info.Args.union args_f args_v,
  fun ei cl -> match (f ei cl) with
  | Error _ as e -> e
  | Ok f ->
      match v ei cl with
      | Error _ as e -> e
      | Ok v -> Ok (f v)



(* Terms *)

let ( $ ) = app

type 'a ret = [ `Ok of 'a | term_escape ]

let ret (al, v) =
  al, fun ei cl -> match v ei cl with
  | Ok (`Ok v) -> Ok v
  | Ok (`Error _ as err) -> Error err
  | Ok (`Help _ as help) -> Error help
  | Error _ as e -> e

let term_result ?(usage = false) (al, v) =
  al, fun ei cl -> match v ei cl with
  | Ok (Ok _ as ok) -> ok
  | Ok (Error (`Msg e)) -> Error (`Error (usage, e))
  | Error _ as e -> e

let cli_parse_result (al, v) =
  al, fun ei cl -> match v ei cl with
  | Ok (Ok _ as ok) -> ok
  | Ok (Error (`Msg e)) -> Error (`Parse e)
  | Error _ as e -> e

let main_name =
  Cmdliner_info.Args.empty,
  (fun ei _ -> Ok (Cmdliner_info.(term_name @@ eval_main ei)))

let choice_names =
  let choice_name t = Cmdliner_info.term_name t in
  Cmdliner_info.Args.empty,
  (fun ei _ -> Ok (List.rev_map choice_name (Cmdliner_info.eval_choices ei)))

let with_used_args (al, v) : (_ * string list) t =
  al, fun ei cl ->
    match v ei cl with
    | Ok x ->
        let actual_args arg_info acc =
          let args = Cmdliner_cline.actual_args cl arg_info in
          List.rev_append args acc
        in
        let used = List.rev (Cmdliner_info.Args.fold actual_args al []) in
        Ok (x, used)
    | Error _ as e -> e


(*---------------------------------------------------------------------------
   Copyright (c) 2011 The cmdliner programmers

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)

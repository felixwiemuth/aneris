(* This file is automatically generated from the OCaml source file
<repository_root>/ml_sources/examples/dscm/implementations/one_server/one_server_client_proxy_code.ml *)

From aneris.aneris_lang Require Import ast.
From aneris.examples.dscm.implementations.one_server Require Import one_server_serialization_code.

Definition wait_for_reply val_ser : val :=
  λ: "srv" "sh" "reqId" "reqMsg",
  let: "rid" := ! "reqId" in
  letrec: "aux" <> :=
    match: ReceiveFrom "sh" with
      NONE => SendTo "sh" "reqMsg" "srv";;
              #();;
              "aux" #()
    | SOME "rply" =>
        let: "repl" := (reply_serializer val_ser).(s_deser) (Fst "rply") in
        let: "res" := Fst "repl" in
        let: "resId" := Snd "repl" in
        assert: ("resId" ≤ "rid");;
        (if: "resId" = "rid"
         then  "reqId" <- ("rid" + #1);;
               "res"
         else  "aux" #())
    end in
    "aux" #().

Definition request val_ser : val :=
  λ: "srv" "sh" "lock" "reqId" "req",
  acquire "lock";;
  let: "reqMsg" := (request_serializer val_ser).(s_ser) ("req", ! "reqId") in
  SendTo "sh" "reqMsg" "srv";;
  #();;
  let: "r" := wait_for_reply val_ser "srv" "sh" "reqId" "reqMsg" in
  release "lock";;
  "r".

Definition install_proxy val_ser : val :=
  λ: "srv" "caddr",
  let: "sh" := NewSocket #PF_INET #SOCK_DGRAM #IPPROTO_UDP in
  let: "reqId" := ref #0 in
  SocketBind "sh" "caddr";;
  SetReceiveTimeout "sh" #3 #0;;
  let: "lock" := newlock #() in
  let: "wr" := λ: "k" "v",
  request val_ser "srv" "sh" "lock" "reqId" (InjL ("k", "v")) in
  let: "rd" := λ: "k",
  request val_ser "srv" "sh" "lock" "reqId" (InjR "k") in
  ("wr", "rd").

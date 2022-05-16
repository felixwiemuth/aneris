(* This file is automatically generated from the OCaml source file
<repository_root>/ml_sources/dscm/implementations/one_server/one_server_network_code.ml *)

From aneris.aneris_lang Require Import ast.
From aneris.aneris_lang.lib Require Import network_util_code.
From aneris.aneris_lang.lib Require Import queue_code.
From aneris.examples.dscm.implementations.one_server Require Import one_server_serialization_code.

Definition receive_thread val_ser : val :=
  λ: "lk" "sh" "inQ",
  letrec: "loop" <> :=
    let: "<>" := match: ReceiveFrom "sh" with
      NONE => #()
    | SOME "msg" =>
        let: "event" := ((request_serializer val_ser).(s_deser) (Fst "msg"), Snd "msg") in
        acquire "lk";;
        "inQ" <- (queue_add "event" ! "inQ");;
        release "lk"
    end in
    "loop" #() in
    "loop" #().

Definition send_reply val_ser : val :=
  λ: "sh" "reply_ev",
  let: "_reply" := Fst "reply_ev" in
  let: "caddr" := Snd "reply_ev" in
  let: "msg" := (reply_serializer val_ser).(s_ser) (Fst "reply_ev") in
  SendTo "sh" "msg" "caddr".

Definition send_thread val_ser : val :=
  λ: "lk" "sh" "outQ",
  letrec: "loop" <> :=
    (if: queue_is_empty ! "outQ"
     then  #() (* unsafe (fun () -> Unix.sleepf 0.5) *)
     else
       acquire "lk";;
       let: "tmp" := ! "outQ" in
       (if: ~ (queue_is_empty "tmp")
        then
          let: "q" := unSOME (queue_take_opt "tmp") in
          let: "event" := Fst "q" in
          let: "outq" := Snd "q" in
          "outQ" <- "outq";;
          release "lk";;
          send_reply val_ser "sh" "event"
        else  release "lk"));;
    "loop" #() in
    "loop" #().

Definition init_network val_ser : val :=
  λ: "srv",
  let: "sh" := NewSocket #PF_INET #SOCK_DGRAM #IPPROTO_UDP in
  let: "lk" := newlock #() in
  SocketBind "sh" "srv";;
  let: "inQ" := ref (queue_empty #()) in
  let: "outQ" := ref (queue_empty #()) in
  Fork (receive_thread val_ser "lk" "sh" "inQ");;
  Fork (send_thread val_ser "lk" "sh" "outQ");;
  ("lk", "inQ", "outQ").

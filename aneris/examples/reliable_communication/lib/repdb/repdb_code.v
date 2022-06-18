(* This file is automatically generated from the OCaml source file
<repository_root>/ml_sources/examples/reliable_communication/lib/repdb/repdb_code.ml *)

From aneris.aneris_lang Require Import ast.
From aneris.aneris_lang.lib Require Import map_code.
From aneris.aneris_lang.lib Require Import network_util_code.
From aneris.aneris_lang.lib.serialization Require Import serialization_code.
From aneris.examples.reliable_communication.lib.repdb Require Import log_code.
From aneris.examples.reliable_communication.lib.mt_server Require Import mt_server_code.

(**  Serializers  *)

Definition write_serializer val_ser :=
  prod_serializer string_serializer val_ser.

Definition read_serializer := string_serializer.

Definition req_c2l_ser val_ser :=
  sum_serializer (write_serializer val_ser) read_serializer.

Definition rep_l2c_ser val_ser :=
  sum_serializer unit_serializer (option_serializer val_ser).

Definition req_f2l_ser := int_serializer.

Definition rep_l2f_ser val_ser :=
  prod_serializer (prod_serializer string_serializer val_ser) int_serializer.

Definition req_c2f_ser := read_serializer.

Definition rep_f2c_ser val_ser := option_serializer val_ser.

(**  Leader  *)

Definition follower_request_handler : val :=
  λ: "log" "mon" "req",
  log_wait_until "log" "mon" "req";;
  unSOME (log_get "log" "req").

Definition update_log_copy_loop : val :=
  λ: "logC" "monC" "logF" "monF" <>,
  letrec: "loop" "i" :=
    monitor_acquire "monC";;
    log_wait_until "logC" "monC" "i";;
    let: "logC_copy" := ! "logC" in
    monitor_release "monC";;
    monitor_acquire "monF";;
    "logF" <- "logC_copy";;
    monitor_broadcast "monF";;
    monitor_release "monF";;
    #() (* unsafe (fun () -> Unix.sleepf 3.0); *);;
    "loop" (Snd "logC_copy") in
    "loop" #0.

Definition start_leader_processing_followers ser : val :=
  λ: "addr" "log" "mon" <>,
  run_server (rep_l2f_ser ser) req_f2l_ser "addr" "mon"
  (λ: "mon" "req", follower_request_handler "log" "mon" "req").

Definition client_request_handler_at_leader : val :=
  λ: "db" "log" "mon" "req",
  match: "req" with
    InjL "p" =>
    let: "k" := Fst "p" in
    let: "v" := Snd "p" in
    "db" <- (map_insert "k" "v" ! "db");;
    let: "n" := log_length "log" in
    log_add_entry "log" ("k", "v", "n");;
    monitor_signal "mon";;
    InjL #()
  | InjR "k" => InjR (map_lookup "k" ! "db")
  end.

Definition start_leader_processing_clients ser : val :=
  λ: "addr" "db" "log" "mon" <>,
  run_server (rep_l2c_ser ser) (req_c2l_ser ser) "addr" "mon"
  (λ: "mon" "req", client_request_handler_at_leader "db" "log" "mon" "req").

Definition init_leader ser : val :=
  λ: "addr0" "addr1",
  let: "logC" := log_create #() in
  let: "logF" := log_create #() in
  let: "db" := ref (map_empty #()) in
  let: "monC" := new_monitor #() in
  let: "monF" := new_monitor #() in
  Fork (start_leader_processing_clients ser "addr0" "db" "logC" "monC" #());;
  Fork (start_leader_processing_followers ser "addr1" "logF" "monF" #());;
  Fork (update_log_copy_loop "logC" "monC" "logF" "monF" #()).

Definition init_client_leader_proxy ser : val :=
  λ: "clt_addr" "srv_addr",
  let: "reqf" := init_client_proxy (req_c2l_ser ser) (rep_l2c_ser ser)
                 "clt_addr" "srv_addr" in
  let: "write" := λ: "k" "v",
  match: "reqf" (InjL ("k", "v")) with
    InjL "_u" => #()
  | InjR "_abs" => assert: #false
  end in
  let: "read" := λ: "k",
  match: "reqf" (InjR "k") with
    InjL "_abs" => assert: #false
  | InjR "r" => "r"
  end in
  ("write", "read").

(**  Follower.  *)

Definition client_request_handler_at_follower : val :=
  λ: "db" "_mon" "req_k", map_lookup "req_k" ! "db".

Definition start_follower_processing_clients ser : val :=
  λ: "addr" "db" "mon",
  run_server (rep_f2c_ser ser) req_c2f_ser "addr" "mon"
  (λ: "mon" "req", client_request_handler_at_follower "db" "mon" "req").

Definition sync_loop : val :=
  λ: "db" "log" "mon" "reqf" "n",
  letrec: "aux" "i" :=
    let: "rep" := "reqf" "i" in
    let: "k" := Fst (Fst "rep") in
    let: "v" := Snd (Fst "rep") in
    let: "j" := Snd "rep" in
    assert: ("i" = "j");;
    monitor_acquire "mon";;
    log_add_entry "log" ("k", "v", "j");;
    "db" <- (map_insert "k" "v" ! "db");;
    monitor_release "mon";;
    "aux" ("i" + #1) in
    "aux" "n".

Definition sync_with_server ser : val :=
  λ: "l_addr" "f2l_addr" "db" "log" "mon",
  let: "reqf" := init_client_proxy req_f2l_ser (rep_l2f_ser ser) "f2l_addr"
                 "l_addr" in
  Fork (sync_loop "db" "log" "mon" "reqf" #0).

Definition init_follower ser : val :=
  λ: "l_addr" "f2l_addr" "f_addr",
  let: "db" := ref (map_empty #()) in
  let: "log" := log_create #() in
  let: "mon" := new_monitor #() in
  sync_with_server ser "l_addr" "f2l_addr" "db" "log" "mon";;
  start_follower_processing_clients ser "f_addr" "db" "mon".

Definition init_client_follower_proxy ser : val :=
  λ: "clt_addr" "srv_addr",
  init_client_proxy req_c2f_ser (rep_f2c_ser ser) "clt_addr" "srv_addr".

(* This file is automatically generated from the OCaml source file
<repository_root>/ml_sources/crdt/oplib/examples/prod_comb/prod_comb_code.ml *)

From aneris.aneris_lang Require Import ast.
From aneris.aneris_lang.lib.serialization Require Import serialization_code.
From aneris.aneris_lang.lib Require Import list_code.
From aneris.examples.crdt.oplib Require Import oplib_code.

Definition effect : val :=
  λ: "eff1" "eff2" "msg" "state",
  let: "delta1" := Fst (Fst (Fst "msg")) in
  let: "delta2" := Snd (Fst (Fst "msg")) in
  let: "vc" := Snd (Fst "msg") in
  let: "origin" := Snd "msg" in
  let: "st1" := Fst "state" in
  let: "st2" := Snd "state" in
  ("eff1" ("delta1", "vc", "origin") "st1", "eff2" ("delta2", "vc", "origin")
                                            "st2").

Definition init_st : val := λ: "is1" "is2" <>, ("is1" #(), "is2" #()).

Definition prod_comb_crdt : val :=
  λ: "crdt1" "crdt2" <>,
  let: "res1" := "crdt1" #() in
  let: "res2" := "crdt2" #() in
  let: "is1" := Fst "res1" in
  let: "eff1" := Snd "res1" in
  let: "is2" := Fst "res2" in
  let: "eff2" := Snd "res2" in
  (init_st "is1" "is2", effect "eff1" "eff2").

Definition prod_comb_init (a_ser : val) (a_deser : val) (b_ser : val)
                          (b_deser : val) : val :=
  λ: "crdt1" "crdt2" "addrs" "rid",
  let: "initRes" := oplib_init (prod_ser a_ser b_ser)
                    (prod_deser a_deser b_deser) "addrs" "rid"
                    (prod_comb_crdt "crdt1" "crdt2") in
  let: "get_state" := Fst "initRes" in
  let: "update" := Snd "initRes" in
  ("get_state", "update").

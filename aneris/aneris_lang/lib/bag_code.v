(* This file is automatically generated from the OCaml source file
<repository_root>/ml_sources/aneris_lang/lib/bag_code.ml *)

From aneris.aneris_lang Require Import ast.

Definition newbag : val :=
  λ: <>, let: "l" := ref NONE in
          let: "v" := newlock #() in
          ("l", "v").

Definition insert : val :=
  λ: "x" "e",
  let: "l" := Fst "x" in
  let: "lock" := Snd "x" in
  acquire "lock";;
  "l" <- (SOME ("e", ! "l"));;
  release "lock".

Definition remove : val :=
  λ: "x",
  let: "l" := Fst "x" in
  let: "lock" := Snd "x" in
  acquire "lock";;
  let: "r" := ! "l" in
  let: "res" := match: "r" with
    NONE => NONE
  | SOME "p" => "l" <- (Snd "p");;
                SOME (Fst "p")
  end in
  release "lock";;
  "res".

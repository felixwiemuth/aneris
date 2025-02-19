From iris.algebra Require Import auth agree gmap gset list.
From iris.base_logic Require Export gen_heap.
From iris.base_logic.lib Require Export own.
From stdpp Require Export strings decidable coPset gmultiset gmap mapset pmap sets.
From aneris.prelude Require Import gmultiset.
From RecordUpdate Require Import RecordSet.
From aneris.aneris_lang Require Import ast.

Global Instance etaSocket : Settable _ :=
  settable! mkSocket <sfamily; stype; sprotocol; saddress; sblock>.

Definition socket_handle := positive.

Global Instance address_family_eq_dec : EqDecision address_family.
Proof. solve_decision. Defined.

Global Instance socket_type_eq_dec : EqDecision socket_type.
Proof. solve_decision. Defined.

Global Instance protocol_eq_dec : EqDecision protocol.
Proof. solve_decision. Defined.

Global Instance socket_address_eq_dec : EqDecision socket_address.
Proof. solve_decision. Defined.

Global Instance socket_eq_dec : EqDecision socket.
Proof. solve_decision. Qed.

Global Program Instance socket_address_countable : Countable socket_address :=
  inj_countable (λ '(SocketAddressInet s p), (s, p))
                (λ '(s,p), Some (SocketAddressInet s p)) _.
Next Obligation. by intros []. Qed.

Global Program Instance address_family_countable : Countable address_family :=
  inj_countable (λ 'PF_INET, ()) (λ _, Some PF_INET) _.
Next Obligation. by intros []. Qed.

Global Program Instance socket_type_countable : Countable socket_type :=
  inj_countable (λ 'SOCK_DGRAM, ()) (λ _, Some SOCK_DGRAM) _.
Next Obligation. by intros []. Qed.

Global Program Instance protocol_countable : Countable protocol :=
  inj_countable (λ 'IPPROTO_UDP, ()) (λ _, Some IPPROTO_UDP) _.
Next Obligation. by intros []. Qed.

Global Instance: Inhabited socket_address := populate (SocketAddressInet "" 1%positive).

(** Ports in use on the client **)
Definition node_ports := gmap ip_address coPset.

(** Messages *)
Definition message_body := string.

Record message := mkMessage {
                      m_sender : socket_address;
                      m_destination : socket_address;
                      m_protocol : protocol;
                      m_body : message_body;
                    }.

Global Instance etaMessage : Settable _ :=
  settable! mkMessage <m_sender; m_destination; m_protocol; m_body>.

Global Instance message_decidable : EqDecision message.
Proof. solve_decision. Defined.

Global Program Instance message_countable : Countable message :=
  inj_countable (λ '(mkMessage s d m b), (s,d,m,b))
                (λ '(s, d, p, b), Some (mkMessage s d p b)) _.
Next Obligation. by intros []. Qed.

Lemma message_inv m1 m2 :
  m_sender m1 = m_sender m2 →
  m_destination m1 = m_destination m2 →
  m_body m1 = m_body m2 →
  m1 = m2.
Proof.
  destruct m1 as [?? [] ?], m2 as [?? [] ?].
  move=> /= -> -> -> //.
Qed.

Definition message_soup := gset message.

Global Instance message_soup_decidable : EqDecision message_soup.
Proof. solve_decision. Defined.

Global Instance message_soup_countable : Countable message_soup.
Proof. apply _. Qed.

Definition messages_to_receive_at (sa : socket_address) (M : message_soup) :=
  filter (λ (m : message), m_destination m = sa) M.

Definition messages_sent_from (sa : socket_address) (M : message_soup) :=
  filter (λ (m : message), m_sender m = sa) M.

Definition message_multi_soup := gmultiset message.

Global Instance message_multi_soup_decidable : EqDecision message_multi_soup.
Proof. solve_decision. Defined.

Global Instance message_multi_soup_countable : Countable message_multi_soup.
Proof. apply _. Qed.

Definition messages_to_receive_at_multi_soup (sa : socket_address) (M : message_multi_soup) :=
  filter (λ (m : message), m_destination m = sa) (gset_of_gmultiset M).

Definition messages_sent_from_multi_soup (sa : socket_address) (M : message_multi_soup) :=
  filter (λ (m : message), m_sender m = sa) (gset_of_gmultiset M).

 Notation udp_msg s d b :=
  {| m_sender := s;
     m_destination := d;
     m_protocol := IPPROTO_UDP;
     m_body := b |}.

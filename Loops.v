Set Implicit Arguments.
From SLF Require Import LibSepReference LibSepTLCbuffer Struct.
From SLF Require Import Fun LabType Sum.
From mathcomp Require Import ssreflect ssrfun zify.
Hint Rewrite conseq_cons' : rew_listx.

Module NatDom : Domain with Definition type := nat.
Definition type := nat.
End NatDom.

Module IntDom : Domain with Definition type := int.
Definition type := int.
End IntDom.

Import List.

Open Scope Z_scope.

Module Export AD := WithArray(IntDom).

Global Instance Inhab_D : Inhab D. 
Proof Build_Inhab (ex_intro (fun=> True) (Lab (0, 0) 0) I).

Lemma wp_while_unary  fs' (Inv : bool -> int -> hhprop) Z N T C s b0 (P : hhprop) Q :
  (forall (b : bool) (x : int),
    Inv b x ==>
      wp 
        fs'
        (fun=> C) 
        (fun hc => \[hc s = b] \* Inv b x)) -> 
  (forall x, Inv false x ==> \[(x = N)] \* Inv false x) ->
  (forall x, Inv true x ==> \[(x < N)] \* Inv true x) ->
  (forall j, (Z <= j < N) ->
    (forall j' b', 
      htriple fs'
        (fun=> While C T) 
        (Inv b' j' \* \[j < j' <= N])
        (fun=> Inv false N)) ->
    Inv true j ==> 
        wp
          fs' 
          (fun=> trm_seq T (While C T))
          (fun=> Inv false N)) ->
  P ==> Inv b0 Z ->
  (fun=> Inv false N) ===> Q ->
  (Z <= N) ->
  fs' = single s tt  ->
  (forall t, subst "while" t T = T) ->
  (forall t, subst "cond" t T = T) ->
  (forall t, subst "tt" t T = T) ->
  (forall t, subst "while" t C = C) ->
  (forall t, subst "cond" t C = C) ->
  (forall t, subst "tt" t C = C) ->
  P ==> wp fs' (fun=> While C T) Q.
Proof.
  move=> HwpC HwpF HwpT HwpT' HP HQ *.
  apply: himpl_trans; first exact/HP.
  apply: himpl_trans; first last.
  { apply: wp_conseq; exact/HQ. }
  apply: himpl_trans.
  { apply/(wp_while_aux_unary (Z := Z) (i := Z) _ (T := T)); eauto. math. }
  by [].
Qed.

Ltac xwhile1 Z N b Inv := 
  let N := constr:(N) in
  let Z := constr:(Z) in 
  let Inv' := constr:(Inv) in
  xseq_xlet_if_needed; xstruct_if_needed;
  eapply (wp_while_unary Inv b (Z := Z) (N := N)); autos*.


Lemma xfor_big_op_lemma_aux Inv (R R' : IntDom.type -> hhprop) 
  (op : (D -> val) -> int -> int) p 
  s fsi1 vr
  Z N (C1 : IntDom.type -> trm) (i j : int) (C : trm)
  Pre Post: 
  (forall (l : int) (x : int), 
    Z <= l < N ->
    {{ Inv l \* 
       (\*_(d <- ⟨(j, 0%Z), fsi1 l⟩) R d) \* 
       p ~⟨(i, 0%Z), s⟩~> (val_int x) }}
      [{
        {i| _  in single s tt  => subst vr l C};
        {j| ld in fsi1 l       => C1 ld}
      }]
    {{ hv, 
        Inv (l + 1) \* 
        (\*_(d <- ⟨(j, 0%Z), fsi1 l⟩) R' d) \* 
        p ~⟨(i, 0%Z), s⟩~> (val_int (x + (op hv l))) }}) ->
  (forall i0 j0 : int, i0 <> j0 -> Z <= i0 < N -> Z <= j0 < N -> disjoint (fsi1 i0) (fsi1 j0)) ->
  (forall (hv hv' : D -> val) m,
    (forall i, indom (fsi1 m) i -> hv[`j](i) = hv'[`j](i)) ->
    op hv m = op hv' m) ->
  (i <> j) ->
  (Z <= N)%Z ->
  (forall t : val, subst "for" t C = C) -> 
  (forall t : val, subst "cnt" t C = C) ->
  (forall t : val, subst "cond" t C = C) ->
  var_eq vr "cnt" = false ->
  var_eq vr "for" = false ->
  var_eq vr "cond" = false ->
  (Pre ==> 
    Inv Z \* 
    (\*_(d <- Union (interval Z N) fsi1) R d) \*
    p ~⟨(i, 0%Z), s⟩~> val_int 0) ->
  (forall hv, 
    Inv N \* 
    (\*_(d <- Union (interval Z N) fsi1) R' d) \* 
    p ~⟨(i, 0%Z), s⟩~> val_int (Σ_(i <- interval Z N) (op hv i)) ==>
    Post hv) -> 
  {{ Pre }}
    [{
      {i| _  in single s tt => For Z N (trm_fun vr C)};
      {j| ld in Union (interval Z N) fsi1 => C1 ld}
    }]
  {{ hv, Post hv }}.
Proof.
  move=> IH Dj opP iNj ?? ??? ??? PostH.
  apply:himpl_trans; first eauto.
  rewrite /ntriple /nwp ?fset_of_cons /=.
  apply: himpl_trans; first last.
  { apply/wp_conseq=> ?; apply PostH. }
  rewrite ?Union_label union_empty_r.
  eapply wp_for with 
    (H:=(fun q hv => 
      Inv q \* 
      (\*_(d <- Union (interval Z q) fsi1) R' d) \*
      (\*_(d <- Union (interval q N) fsi1) R d) \* 
      p ~⟨(i, 0%Z), s⟩~> Σ_(l <- interval Z q) op hv l))
    (hv0:=fun=> 0)=> //; try eassumption.
  { clear -IH Dj iNj opP.
    move=>l hv ?; move: (IH l).
    rewrite /ntriple /nwp ?fset_of_cons /= ?fset_of_nil.
    rewrite union_empty_r intervalUr; try math.
    rewrite Union_upd //; first last. 
    { introv Neq. rewrite ?indom_union_eq ?indom_interval ?indom_single_eq.
      case=> [?[?|]|]; first by subst.
      { subst=> ?; apply/Dj=> //; math. }
      move=> ? [?|?]; subst; apply/Dj; math. }
    rewrite hbig_fset_union; first last.
    2-4: auto.
    2-3: hnf; auto.
    { rewrite disjoint_Union=> ? /[! indom_interval] ?.
      apply/Dj; math. }
    rewrite (@intervalU l N); last math.
    rewrite Union_upd //; first last.
    { introv Neq. rewrite ?indom_union_eq ?indom_interval ?indom_single_eq.
      case=> [?[?|]|]; first by subst.
      { subst=> ?; apply/Dj=> //; math. }
      move=> ? [?|?]; subst; apply/Dj; math. }
    rewrite // hbig_fset_union; first last.
    2-4: auto.
    2-3: hnf; auto.
    { rewrite disjoint_Union=> ? /[! indom_interval] ?.
      apply/Dj; math. }
    move=> Hwp.
    erewrite wp_ht_eq with (ht2:=(htrm_of
      ((Lab (pair i 0) (FH (single s tt) (fun=> subst vr l C))) ::
        (Lab (pair j 0) (FH (fsi1 l) (fun ld => C1 ld))) ::
        nil))).
    2:{
      intros (ll, d) H. unfold uni, htrm_of. simpl. 
      rewrite indom_union_eq ! indom_label_eq in H |- *.
      rewrite indom_single_eq in H |- *. 
      repeat case_if; try eqsolve.
      destruct C3 as (<- & HH). false C2. split; auto.
      rewrite indom_Union. exists l. rewrite indom_interval.
      split; try math; auto.
    }
    assert (Z <= l < N) as Htmp by math. 
    specialize (Hwp (Sum (interval Z l) (fun i => op hv i)) Htmp). clear Htmp.
    apply wp_equiv in Hwp. apply wp_equiv.
    eapply htriple_conseq_frame.
    1: apply Hwp.
    1: xsimpl. 1: xsimpl.
    hnf. intros v.
    xsimpl. xsimpl.
    rewrite <- intervalUr; try math. rewrite SumxSx; try math.
    hnf. intros h Hh. apply hsingle_inv in Hh. subst h.
    rewrite -> SumEq with (G:=fun i => op hv i).
    2:{ intros x. rewrite indom_interval. 
      unfold uni. intros HH. apply opP.
      intros. rewrite indom_label_eq. case_if; auto.
      destruct C0 as (_ & H0).
      false disjoint_inv_not_indom_both. 2: apply H. 2: apply H0.
      apply Dj; math.
    }
    rewrite -> opP with (hv':=v). 1: apply hsingle_intro.
    intros. unfold uni. rewrite indom_label_eq. case_if; eqsolve. }
  { move=> r hv hv' hvE.
    suff->:
      Σ_(l <- interval Z r) op hv l = 
      Σ_(l <- interval Z r) op hv' l by xsimpl.
    apply/SumEq=> *; apply/opP=> *; apply/hvE.
    rewrite indom_Union; eexists; rewrite indom_label_eq; autos*. }
  { rewrite [_ Z Z]intervalgt; last math.
    rewrite Union0 hbig_fset_empty Sum0. xsimpl. }
  { move=> ?.
    rewrite [_ N N]intervalgt; last math.
    rewrite Union0 hbig_fset_empty. xsimpl. }
  { simpl.
    intros. apply disjoint_of_not_indom_both. 
    intros. destruct x as (?, x). 
    rewrite indom_label_eq in H2. rewrite indom_label_eq in H3.
    destruct H2 as (_ & H2), H3 as (_ & H3). 
    revert H2 H3. apply disjoint_inv_not_indom_both, Dj=> //; math.
  }
  { rewrite disjoint_Union=> ??. 
    apply disjoint_of_not_indom_both. 
    intros. destruct x as (?, x).
    simpl in H. rewrite indom_single_eq in H.  
    injection H as <-.
    rewrite -> indom_Union in H0.
    destruct H0 as (? & ? & H0).
    rewrite indom_label_eq in H0. eqsolve.
  }
  by case=> l d; rewrite indom_label_eq /= /htrm_of; case: classicT.
Qed.

Lemma xfor_specialized_lemma (Inv : int -> hhprop) (R R' : IntDom.type -> hhprop) 
  s fsi1 vr
  Z N (C1 : IntDom.type -> trm) (i j : int) (C : trm)
  Pre Post
  (p : int -> loc) : 
  (forall (l : int),
    Z <= l < N ->
    {{ Inv l \* 
       (\*_(d <- ⟨(j, 0%Z), fsi1 l⟩) R d) \*
       (\*_(d <- (fsi1 l)) p d ~⟨(i, 0%Z), s⟩~> val_uninit) }}
      [{
        {i| _  in single s tt  => subst vr l C};
        {j| ld in fsi1 l       => C1 ld}
      }]
    {{ hv, 
        Inv (l + 1) \* 
        (\*_(d <- ⟨(j, 0%Z), fsi1 l⟩) R' d) \*
        (\*_(d <- (fsi1 l)) p d ~⟨(i, 0%Z), s⟩~> hv (Lab (j, 0%Z) d)) }}) ->
  (forall i0 j0 : int, i0 <> j0 -> disjoint (fsi1 i0) (fsi1 j0)) ->
  (i <> j) ->
  (Z <= N)%Z ->
  (forall t : val, subst "for" t C = C) -> 
  (forall t : val, subst "cnt" t C = C) ->
  (forall t : val, subst "cond" t C = C) ->
  var_eq vr "cnt" = false ->
  var_eq vr "for" = false ->
  var_eq vr "cond" = false ->
  (Pre ==> 
    Inv Z \* 
    (\*_(d <- Union (interval Z N) fsi1) R d) \*
    (\*_(d <- Union (interval Z N) fsi1) p d ~⟨(i, 0%Z), s⟩~> val_uninit)) ->
  (forall hv,
    Inv N \* 
    (\*_(d <- Union (interval Z N) fsi1) R' d) \*
    (\*_(d <- Union (interval Z N) fsi1) p d ~⟨(i, 0%Z), s⟩~> hv (Lab (j, 0%Z) d)) ==>
    Post hv) -> 
  {{ Pre }}
    [{
      {i| _  in single s tt => For Z N (trm_fun vr C)};
      {j| ld in Union (interval Z N) fsi1 => C1 ld}
    }]
  {{ hv, Post hv }}.
Proof.
  move=> IH Dj iNj ?? ??? ??? PostH.
  apply:himpl_trans; first eauto.
  rewrite /ntriple /nwp ?fset_of_cons /=.
  apply: himpl_trans; first last.
  { apply/wp_conseq=> ?; apply PostH. }
  rewrite ?Union_label union_empty_r.
  eapply wp_for with 
    (H:=(fun q hv => 
      Inv q \* 
      (\*_(d <- Union (interval Z q) fsi1) R' d) \*
      (\*_(d <- Union (interval q N) fsi1) R d) \* 
      (\*_(d <- Union (interval Z q) fsi1) p d ~⟨(i, 0%Z), s⟩~> hv (Lab (j, 0%Z) d)) \*
      (\*_(d <- Union (interval q N) fsi1) p d ~⟨(i, 0%Z), s⟩~> val_uninit)))
    (hv0:=fun=> 0) => //; try eassumption.
  { clear -IH Dj iNj.
    move=>l hv ?. 
    move: (IH l).
    rewrite /ntriple /nwp ?fset_of_cons /= ?fset_of_nil.
    rewrite union_empty_r intervalUr; try math.
    rewrite Union_upd //; first last.
    { introv Neq. rewrite ?indom_union_eq ?indom_interval ?indom_single_eq.
      case=> [?[?|]|]; first by subst.
      { subst=> ?; apply/Dj=> //; math. }
      move=> ? [?|?]; subst; apply/Dj; math. }
    rewrite hbig_fset_union; first last.
    2-4: auto.
    2-3: hnf; auto.
    { rewrite disjoint_Union=> ? /[! indom_interval] ?.
      apply/Dj; math. }
    rewrite (@intervalU l N); last math.
    rewrite Union_upd; first last. 
    { introv Neq. rewrite ?indom_union_eq ?indom_interval ?indom_single_eq.
      case=> [?[?|]|]; first by subst.
      { subst=> ?; apply/Dj=> //; math. }
      move=> ? [?|?]; subst; apply/Dj; math. }
    rewrite hbig_fset_union; first last.
    2-4: auto.
    2-3: hnf; auto.
    { rewrite disjoint_Union=> ? /[! indom_interval] ?.
      apply/Dj; math. }
    move=> Hwp.
    rewrite -> hbig_fset_union.
    2-3: hnf; auto.
    2: auto.
    2: { rewrite disjoint_Union=> ? /[! indom_interval] ?.
      apply/Dj; math. }
    erewrite wp_ht_eq with (ht2:=(htrm_of
      ((Lab (pair i 0) (FH (single s tt) (fun=> subst vr l C))) ::
        (Lab (pair j 0) (FH (fsi1 l) (fun ld => C1 ld))) ::
        nil))).
    2:{
      intros (ll, d) H. unfold uni, htrm_of. simpl. 
      rewrite indom_union_eq ! indom_label_eq in H |- *.
      rewrite indom_single_eq in H |- *. 
      repeat case_if; try eqsolve.
      destruct C3 as (<- & HH). false C2. split; auto.
      rewrite indom_Union. exists l. rewrite indom_interval.
      split; try math; auto.
    }
    assert (Z <= l < N) as Htmp by math. specialize (Hwp Htmp). clear Htmp.
    apply wp_equiv in Hwp. apply wp_equiv.
    eapply htriple_conseq_frame.
    1: apply Hwp.
    1: xsimpl. 1: xsimpl.
    hnf. intros v.
    xsimpl. xsimpl.
    rewrite -> hbig_fset_union.
    2-3: hnf; auto.
    2: auto.
    2: { rewrite disjoint_Union=> ? /[! indom_interval] ?.
      apply/Dj; math. }
    unfold uni.
    apply himpl_frame_lr.
    { apply hbig_fset_himpl.
      intros. case_if; auto.
      rewrite indom_label_eq in C0. eqsolve.
    }
    { apply hbig_fset_himpl.
      intros. case_if; auto.
      rewrite indom_label_eq in C0. destruct C0 as (_ & H1).
      rewrite indom_Union in H. 
      destruct H as (f & H & H2). rewrite -> indom_interval in H.
      false. revert H1 H2. apply disjoint_inv_not_indom_both, Dj.
      math.
    }
  }
  { intros. f_equal. f_equal. f_equal. f_equal. apply hbig_fset_eq.
    intros. rewrite -> H; auto.
    rewrite indom_Union in H0. rewrite indom_Union.
    destruct H0 as (f & H0 & H2). 
    exists f. rewrite indom_label_eq. intuition.
  }
  { rewrite [_ Z Z]intervalgt; last math.
    rewrite Union0 ! hbig_fset_empty. xsimpl. }
  { move=> ?.
    rewrite [_ N N]intervalgt; last math.
    rewrite Union0 ! hbig_fset_empty. xsimpl. }
  { simpl.
    intros. apply disjoint_of_not_indom_both. 
    intros. destruct x as (?, x).
    rewrite indom_label_eq in H2. rewrite indom_label_eq in H3.
    destruct H2 as (_ & H2), H3 as (_ & H3). 
    revert H2 H3. by apply disjoint_inv_not_indom_both, Dj.
  }
  { rewrite disjoint_Union=> ??. 
    apply disjoint_of_not_indom_both. 
    intros. destruct x as (?, x).
    simpl in H. rewrite indom_single_eq in H.  
    injection H as <-.
    rewrite -> indom_Union in H0.
    destruct H0 as (? & ? & H0).
    rewrite indom_label_eq in H0. eqsolve.
  }
  by case=> l d; rewrite indom_label_eq /= /htrm_of; case: classicT.
Qed.

Lemma lab_eqbE l1 l2: 
  (lab_eqb l1 l2) = (l1 = l2) :> Prop.
Proof. by extens; split=> [/lab_eqbP|->]// /[! eqbxx]. Qed.

Lemma xfor_big_op_lemma Inv (R R' : IntDom.type -> hhprop) 
  (op : (D -> val) -> int -> int) p 
  s fsi1 vr
  Z N (C1 : IntDom.type -> trm) (i j : int) (C : trm) C'
  Pre Post: 
  (forall (l : int) (x : int), 
    Z <= l < N ->
    {{ Inv l \* 
       (\*_(d <- ⟨(j, 0%Z), fsi1 l⟩) R d) \* 
       p ~⟨(i, 0%Z), s⟩~> (val_int x) }}
      [{
        {i| _  in single s tt  => subst vr l C};
        {j| ld in fsi1 l       => C1 ld}
      }]
    {{ hv, 
        Inv (l + 1) \* 
        (\*_(d <- ⟨(j, 0%Z), fsi1 l⟩) R' d) \* 
        p ~⟨(i, 0%Z), s⟩~> (val_int (x + (op hv l))) }}) ->
  (forall i j : int, i <> j -> Z <= i < N -> Z <= j < N -> disjoint (fsi1 i) (fsi1 j)) ->
  (forall (hv hv' : D -> val) m,
    (forall i, indom (fsi1 m) i -> hv[`j](i) = hv'[`j](i)) ->
    op hv m = op hv' m) ->
  (i <> j) ->
  (Z <= N)%Z ->
  (forall t : val, subst "for" t C = C) -> 
  (forall t : val, subst "cnt" t C = C) ->
  (forall t : val, subst "cond" t C = C) ->
  var_eq vr "cnt" = false ->
  var_eq vr "for" = false ->
  var_eq vr "cond" = false ->
  (Pre ==> 
    Inv Z \* 
    (\*_(d <- Union (interval Z N) fsi1) R d) \*
    p ~⟨(i, 0%Z), s⟩~> val_int 0) ->
  (forall hv, 
    Inv N \* 
    (\*_(d <- Union (interval Z N) fsi1) R' d) \* 
    p ~⟨(i, 0%Z), s⟩~> val_int (Σ_(i <- interval Z N) (op hv i)) ==>
    wp ⟨(i,0),single s tt⟩ (fun=> C') (fun hr' => Post (lab_fun_upd hr' hv (i,0)))) -> 
  {{ Pre }}
    [{
      {i| _  in single s tt => trm_seq (For Z N (trm_fun vr C)) C'};
      {j| ld in Union (interval Z N) fsi1 => C1 ld}
    }]
  {{ hv, Post hv }}.
Proof.
  intros.
  xfocus (j,0); rewrite ?eqbxx.
  have E: (lab_eqb (i, 0) (j,0) = false).
  { by apply/bool_ext; split=> //; rewrite lab_eqbE=> -[]. }
  rewrite E/= -xnwp1_lemma /= wp_equiv.
  apply/htriple_conseq; [|eauto|]; first last.
  { move=> ?. apply/wp_seq. }
  rewrite (xnwp1_lemma (FH (single s tt) (fun=> For Z N <{ fun_ {vr} => {C} }>)) ((i,0))).
  rewrite -wp_equiv.
  apply/(xunfocus_lemma (fun hr => WP [ _ in ⟨(i, 0), single s tt⟩  => C' ]
  { hr'0, Post ((hr \u_ ⟨(j, 0), Union (interval Z N) fsi1⟩) hr'0) }))=> /=; autos*.
  { by rewrite E. }
  move=> ??; fequals; apply/fun_ext_1=> ?. fequals.
  extens=> -[]??; rewrite /uni; case: classicT=> //.
  xfocus (i,0); rewrite ?eqbxx lab_eqb_sym E /=.
  apply/xunfocus_lemma; autos*=> /=.
  { by rewrite lab_eqb_sym E. }
  { move=> ??. remember ((_ \u_ _) _); reflexivity. }
  simpl.
  apply/xfor_big_op_lemma_aux; eauto.
  move=> hv. apply: himpl_trans; [|apply/wp_hv].
  move: (H11 hv); rewrite wp_equiv=> ?.
  xapp=> hv'. rewrite -/(lab_fun_upd _ _ _).
  xsimpl (lab_fun_upd hv' hv (i, 0))=> ?.
  apply: applys_eq_init; fequals; apply/fun_ext_1=> /=.
  case=> l x.
  rewrite /uni ?indom_label_eq; case: classicT.
  { by case=> <- /=; rewrite lab_eqb_sym E. }
  case: classicT=> //.
  case=> <- /=; rewrite eqbxx //.
Qed.

Tactic Notation "xfor_sum" constr(Inv) constr(R) uconstr(R') uconstr(op) constr(s) :=
  eapply (@xfor_big_op_lemma Inv R R' op s); 
  [ let L := fresh in 
    intros ?? L;
    xnsimpl
  | let Neq := fresh in
    let i   := fresh "i" in
    let j   := fresh "j" in 
    intros i j; 
    autorewrite with disjointE; try math
  | let hvE := fresh "hvE" in
  intros ??? hvE; try setoid_rewrite hvE; [eauto|autorewrite with indomE; try math]
  |
  |
  |
  |
  |
  |
  |
  |
  | rewrite /Inv /R; rewrite -> ?hbig_fset_hstar; xsimpl
  | intros ?; xsimpl
  ]=> //; autos*.

Lemma disjoint_single {T} (x y : T) : 
  disjoint (single x tt) (single y tt) = (x <> y).
Proof.
  extens; split; last apply/disjoint_single_single.
  move/[swap]->; exact/disjoint_single_single_same_inv.
Qed.

Lemma disjoint_interval (x1 y1 x2 y2 : int) : 
  disjoint (interval x1 y1) (interval x2 y2) = ((y1 <= x2) \/ (y2 <= x1) \/ (y1 <= x1) \/ (y2 <= x2)).
Proof.
  extens; split=> [/(@disjoint_inv_not_indom_both _ _ _ _ _)|].
  { setoid_rewrite indom_interval=> /[dup]/(_ x1)+/(_ x2).
   lia. }
  move=> H; apply/disjoint_of_not_indom_both=> ?; rewrite ?indom_interval.
  move: H; lia.
Qed.

Lemma disjoint_single_interval (x1 y1 x : int) : 
  disjoint (single x tt) (interval x1 y1) = ((x < x1) \/ (y1 <= x)).
Proof.
  extens; split=> [/(@disjoint_inv_not_indom_both _ _ _ _ _)|].
  { move=> /[dup]/(_ x); rewrite indom_interval indom_single_eq.
    lia. }
  move=> H; apply/disjoint_single_of_not_indom.
  rewrite indom_interval. math.
Qed.


Lemma disjoint_interval_single (x1 y1 x : int) : 
  disjoint (interval x1 y1) (single x tt) = ((x < x1) \/ (y1 <= x)).
Proof. by rewrite disjoint_comm disjoint_single_interval. Qed.

Lemma disjoint_label {T} (l l' : labType) (fs1 fs2 : fset T) : 
  disjoint (label (Lab l fs1)) (label (Lab l' fs2)) = ((l <> l') \/ disjoint fs1 fs2).
Proof.
  extens; split=> [/(@disjoint_inv_not_indom_both _ _ _ _ _)|].
  { move=> IN; case: (classicT (l = l')); [right|left]=> //; subst.
    apply/disjoint_of_not_indom_both=> x.
    move: (IN (Lab l' x)); rewrite ?indom_label_eq; autos*. }
  case: (classicT (l = l'))=> [<-|? _].
  { rewrite*  @disjoint_eq_label. }
  apply/disjoint_of_not_indom_both=> -[??]; rewrite ?indom_label_eq.
  case=><-; autos*.
Qed.


Global Hint Rewrite @disjoint_single disjoint_interval disjoint_single_interval 
  disjoint_interval_single @disjoint_eq_label @disjoint_label : disjointE.
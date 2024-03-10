# Artefact for LGTM

## Building Instructions

The version of Coq used in our development is **8.18.0**, where the version of underlying OCaml compiler is **4.13.1**. We recommend installing Coq and the required packages via OPAM. [The official page of OPAM](https://opam.ocaml.org/doc/Install.html) describes how to install and configure OPAM, and [the official page of Coq](https://coq.inria.fr/opam-using.html) describes how to install Coq and Coq packages with OPAM. 

We have tested on our machine that after executing `opam repo add coq-released https://coq.inria.fr/opam/released` according to the official page of Coq, running the following commands can install all required packages for compiling our project:

```bash
opam install coq-mathcomp-ssreflect=2.1.0
opam install coq-mathcomp-zify coq-mathcomp-algebra=2.1.0 coq-mathcomp-fingroup=2.1.0 coq-mathcomp-finmap=2.1.0
opam install coq-flocq
opam install coq-bignums=9.0.0+coq8.18
opam install coq-vcfloat --ignore-constraints-on=coq
```

The flag `--ignore-constraints-on` is necessary for working around some version constraints. 

### Build the Coq Project

Execute the following command in the terminal: 

```bash
make
```

Please note that warnings (in yellow colour) may appear during the compilation, but they will not cause the compilation to fail. 

## Navigation Guide

### Important Proof Rules

Structural rules:
- Focus: `wp_union` in `lib/seplog/LibWP.v`
- Product: `htriple_union_pointwise` in `lib/seplog/LibWP.v`
- Conseq: `htriple_conseq` in `lib/seplog/LibWP.v`
- Frame: `htriple_frame` in `lib/seplog/LibWP.v`

Lockstep rules: 
- Ret: `htriple_val` in `lib/seplog/LibWP.v`
- Read: `htriple_get` in `lib/seplog/LibWP.v`
- Asn: `htriple_set` in `lib/seplog/LibWP.v`
- Fr: `htriple_free` in `lib/seplog/LibWP.v`
- Alc: `htriple_ref` in `lib/seplog/LibWP.v`
- MAlc: `htriple_alloc` in `lib/seplog/LibWP.v`
- MFr: `htriple_dealloc` in `lib/seplog/LibWP.v`
- Let: `htriple_let` in `lib/seplog/LibWP.v`
- If: `htriple_if` in `lib/seplog/LibWP.v`
- Len: `htriple_array_length` in `lib/seplog/LibArray.v`
- AsnArr: `htriple_array_set` in `lib/seplog/LibArray.v`
- ReadArr: `htriple_array_get` in `lib/seplog/LibArray.v`

Domain substitution rule: 
- Subst: `htriple_hsub` in `lib/seplog/LibWP.v`

Rule for for-loops:
- For: `wp_for` in `lib/seplog/LibWP.v`

Rule for while-loops: 
- While: `xwhile_lemma` in `lib/seplog/LibLoops.v`

### Important Results

Mechanisation of the overview example from the paper can be found in `experiments` folder. 

Evaluation Case Studies: 
- #1:  `sum_spec` in `experiments/SV.v`
- #2:  `dotprod_spec` in `experiments/SV.v`
- #3:  `sv_dotprod_spec` in `experiments/SV.v`
- #4:  `sum_spec` in `experiments/COO.v`
- #5:  `sum_spec` in `experiments/CSR.v`
- #6:  `spmv_spec` in `experiments/CSR.v`
- #7:  `spmspv_spec` in `experiments/CSR.v`
- #8:  `sum_spec` in `experiments/uCSR.v`
- #9:  `spmv_spec` in `experiments/uCSR.v`
- #10: `spmspv_spec` in `experiments/uCSR.v`
- #11: `rlsum_spec` in `experiments/RL.v`
- #12: `alpha_blend_spec` in `experiments/RL.v`
- #13: `spmv_spec` in `experiments/CSR_float.v`

Mechanised proof of the overview case study, presented in Section 4, is located in `experiments/uCSR.v` with all correspondent comments.

### LGTM embedding details

The Coq-specific details of the framework are explained in `Triple.md`. `Triple.md` explains how LGTM specification triples are embedded in the Coq development.

### Recommended order of Artifact Evaluation 

1. `Triple.md` -- explains how LGTM triples are embedded 
2. `experiments/uCSR.v` -- explains the mechanised proof of Section 4 from the paper, as well as other uCSR related proofs.
3. `experiments/SV.v` -- explains the mechanised proofs related to operations on SV format.
4. `experiments/CSR.v` -- explains the CSR format. Mechanised proofs in `experiments/CSR.v` are similar to ones in `experiments/uCSR.v`.
5. Other `experiments/*` files
6. Files with metatheory mechanisation
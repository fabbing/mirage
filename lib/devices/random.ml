open Functoria.DSL

type random = job

let random = Functoria.job

let default_random =
  let packages =
    [ package ~min:"1.0.0" ~max:"2.0.0" "mirage-crypto-rng-mirage2" ]
  in
  let connect _ modname _ =
    (* here we could use the boot argument (--prng) to select the RNG! *)
    code ~pos:__POS__ "%s.initialize (module Mirage_crypto_rng.Fortuna)" modname
  in
  impl ~packages ~connect "Mirage_crypto_rng_mirage2" random

let no_random = impl "Mirage_runtime" random

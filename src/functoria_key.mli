(*
 * Copyright (c) 2015 Nicolas Ojeda Bar <n.oje.bar@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Configuration and runtime command-line arguments. *)

(** Cross-stage command-line arguments. *)
module Arg: sig
  (** Terms for cross-stage arguments.

      This module extends
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html}
      Cmdliner.Arg} to allow MetaOCaml-style typed cross-stage
      persistency of command-line arguments. *)

  (** {1 Argument converters} *)

  type 'a serialize = Format.formatter -> 'a -> unit
  (** The type for command-line argument serializers. A value of type
      ['a serialize] generates a syntactically valid OCaml
      representation which evaluates to a value of type ['a]. *)

  type 'a runtime_conv = string
  (** The type for commmand-line argument converters used at
      runtime. A value of type ['a runtime_conv] is a symbol name of
      type
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#TYPEconverter}
      Cmdliner.Arg.converter}. *)

  type 'a converter = 'a Cmdliner.Arg.converter * 'a serialize * 'a runtime_conv
  (** The type for argument converters. A value of [(c, s, r)] of type
      ['a converter] is the argument converter using [c] to convert
      user strings into OCaml value, [s] to convert OCaml values into
      strings interpretable as OCaml expressions, and the function
      named [r] to convert user strings into OCaml values at
      runtime. *)

  val string: string converter
  (** [string] converts strings. *)

  val bool: bool converter
  (** [bool] converts booleans. *)

  val int: int converter
  (** [int] converts integers. *)

  val list: 'a converter -> 'a list converter
  (** [list t] converts lists of [t]s. *)

  val some: 'a converter -> 'a option converter
  (** [some t] converts [t] options. *)

  (** {1 Arguments and their information} *)

  type 'a t
  (** The type for arguments holding data of type ['a]. *)

  type info
  (** The type for information about cross-stage command-line
      arguments. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#arginfo}
      Cmdliner.Arg#TYPEinfo}. *)

  val info:
    ?docs:string -> ?docv:string -> ?doc:string -> ?env:string ->
    string list -> info
  (** Define cross-stage information for an argument. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#TYPEinfo}
      Cmdliner.Arg.info}.*)


  (** {1 Optional Arguments} *)

  (** The type for specifying at which stage an argument is available.

      {ul
      {- [`Configure] means that the argument is read on the
         command-line at configuration-time.}
      {- [`Run] means that the argument is read on the command-line at
         runtime.}
      {- [`Both] means that the argument is read on the command-line
         both at configuration-time and runt-ime.}
      } *)
  type stage = [
    | `Configure
    | `Run
    | `Both
  ]

  val opt: ?stage:stage -> 'a converter -> 'a -> info -> 'a t
  (** [opt conv v i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#VALopt}
      Cmdliner.Arg.opt} but for cross-stage optional command-line
      arguments. If not set, [stage] is [`Both]. *)

  val flag: ?stage:stage -> info -> bool t
  (** [flag i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#VALflag}
      Cmdliner.Arg.opt} but for cross-stage command-line flags. If not
      set, [stage] is [`Both]. *)

end

type +'a value
(** The type for configure-time and run-time values. Values can be
    parsed from the command-line at configure and/or runtime, or can
    be provided as OCaml values in the application configuration file
    (ie. {i config.ml}). *)

val pure: 'a -> 'a value
(** [pure x] is a value without any dependency. *)

val ($): ('a -> 'b) value -> 'a value -> 'b value
(** [f $ v] is is the value resulting from the application of
    [f]'value to [v]'s value. [$] is the usual {i app} operator for
    {{:http://dx.doi.org/10.1017/S0956796807006326}applicative
    functor}. *)

val map: ('a -> 'b) -> 'a value -> 'b value
(** [map f v] is [pure f $ v]. *)

val if_: bool value -> 'a -> 'a -> 'a value
(** [if_ v x y] is [map (fun b -> if b then x else y) v]. *)

val default: 'a value -> 'a
(** [default v] returns the default value for [v]. *)

(** {1 Configuration Keys} *)

type 'a key
(** The type for configuration keys. Keys form a directed and acyclic
    dynamic graph of dependent values that need to be evaluated in
    order to obtain {!values}. Vertices of the key graph hold
    {{!value}values}. Edges represent direct evaluation dependencies
    between values.

    Keys are used to retrieve the cross-stage values they are holding
    (by indexing contents in the autogenerated [Bootgen_var] module)
    but also to parametrize the choice of
    {{!Functoria_dsl.if_impl}module implementation}. *)


val create: string -> 'a Arg.t -> 'a key
(** [create n a] is the key named [n] whose contents is determined by
    parsing the command-line argument [a]. *)

val value: 'a key -> 'a value
(** [value k] is the value parsed by [k]. *)

type t
(** The type for untyped keys. *)

val compare: t -> t -> int
(** [compare] compares untyped keys. *)

val v: 'a key -> t
(** [v key] is [key] by with all type information erased. This allows
    to put them in a set/list. *)

val pp: t Fmt.t
(** [pp fmt k] prints the name of [k]. *)

val with_deps: keys:t list -> 'a value -> 'a value
(** [with_deps deps v] is the value [v] with added dependencies. *)

val deps: 'a value -> t list
(** [deps v] is the dependencies of [v]. *)

val pp_deps: 'a value Fmt.t
(** [pp_deps fmt v] prints the name of the dependencies of [v]. *)

(** {1 Stages} *)

val is_runtime: t -> bool
(** [is_runtime k] is true if [k]'s stage is [`Run] or [`Both]. *)

val is_configure: t -> bool
(** [is_configure k] is true if [k]'s stage is [`Configure] or [`Both]. *)

val filter_stage: Arg.stage -> t list -> t list
(** [filter_stage s ks] is [ks] but with only keys available at stage
    [s]. *)

(** {1 Alias}

    Alias allows to define virtual keys in terms of other keys at
    configuration time only. *)
module Alias: sig

  type 'a t
  (** The type for key alias. *)

  val add: 'b key -> ('a -> 'b option) -> 'a t -> 'a t
  (** [add k f a] set [a] as an alias for the key [k]: setting [a] on
      the command-line will set [k] to [f] applied to [a]'s value. If
      [f] returns [None], no value is set. *)

  val flag: Arg.info -> bool t
  (** [flag] is similar to {!Arg.flag} but defines configure-only
      command-line flag alias. Set [stage] to [`Configure]. *)

  val opt: 'a Arg.converter -> 'a -> Arg.info -> 'a t
  (** [opt] is similar to {!Arg.opt} but defines configure-only
      optional command-line arguments. Set [stage] to [`Configure]. *)

end

val alias: string -> 'a Alias.t -> 'a key
(** Similar to {!create} but for command-line alias. *)

val aliases: t -> t list
(** [aliases t] is the list of [t]'s aliases. *)

(** {1 Parsing context} *)

type context
(** The type for values holding parsing context. *)

val parse: ?stage:Arg.stage -> t list -> context Cmdliner.Term.t
(** [parse ks] is a [Cmdliner]
    {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Term.html#TYPt}
    term} that evaluates into a parsing context for the keys [ks]. *)

val parse_value: ?stage:Arg.stage -> 'a value -> 'a Cmdliner.Term.t
(** [parse_value v] is [parse @@ deps v] and returns the content of
    [v]. *)

val is_parsed: context -> 'a value -> bool
(** [is_parsed p v] returns [true] iff all the dependencies of [v]
    have been parsed. *)

val peek: context -> 'a value -> 'a option
(** [peek p v] returns [Some x] if [v] has been resolved to [x] and
    [None] otherwise. *)

val eval: context -> 'a value -> 'a
(** [eval p v] resolves [v], using default values if necessary. *)

val get: context -> 'a key -> 'a
(** [get p k] resolves [k], using default values if necessary. *)

val pp_parsed: context -> t list Fmt.t
(** [pp_parsed p fmt set] prints the keys in [set] using the context
    [c]. *)

(** {1 Code Serialization} *)

val ocaml_name: t -> string
(** [ocaml_name k] is the ocaml name of [k]. *)

val serialize_call: t Fmt.t
(** [serialize_call fmt k] outputs [Bootvar_gen.n ()] to [fmt], where
    [n] is [k]'s {{!ocaml_name}OCaml name}. *)

val serialize: context -> t Fmt.t
(** [serialize ctx ppf k] outputs the [Cmdliner] runes to parse
    command-line arguments represented by [k] at runtime. *)

(**/**)

val module_name: string
(** Name of the generated module containing the keys. *)

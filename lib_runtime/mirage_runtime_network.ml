open Cmdliner

let pf = Format.fprintf
let str = Format.asprintf

let pp_group ppf = function
  | None -> pf ppf "the unikernel"
  | Some s -> pf ppf "the %s group" s

let runtime_arg ?(group = "") ~docs ?docv ~doc ~default c name =
  let prefix = if group = "" then group else group ^ "-" in
  let doc = Arg.info ~docs ?docv ~doc [ prefix ^ name ] in
  Arg.(value & opt c default doc)

let interface ?group ?(docs = Mirage_runtime.s_net) default =
  let doc = str "The network interface listened by %a." pp_group group in
  runtime_arg ~doc ~default ?group ~docs ~docv:"INTERFACE" Arg.string
    "interface"

module Conv = struct
  let conv of_string to_string : _ Cmdliner.Arg.conv =
    let pp ppf v = Format.pp_print_string ppf (to_string v) in
    Cmdliner.Arg.conv (of_string, pp)

  let ipv4_address = conv Ipaddr.V4.of_string Ipaddr.V4.to_string
  let ipv4 = conv Ipaddr.V4.Prefix.of_string Ipaddr.V4.Prefix.to_string
  let ipv6_address = conv Ipaddr.V6.of_string Ipaddr.V6.to_string
  let ipv6 = conv Ipaddr.V6.Prefix.of_string Ipaddr.V6.Prefix.to_string
  let ip_address = conv Ipaddr.of_string Ipaddr.to_string
end

open Conv

module V4 = struct
  let network ?group ?(docs = Mirage_runtime.s_net) default =
    let doc =
      str
        "The network of %a specified as an IP address and netmask, e.g. \
         192.168.0.1/16 ."
        pp_group group
    in
    runtime_arg ~doc ~docs ~docv:"PREFIX" ~default ?group ipv4 "ipv4"

  let gateway ?group ?(docs = Mirage_runtime.s_net) default =
    let doc = str "The gateway of %a." pp_group group in
    runtime_arg ~doc ~docs ~docv:"IP" ~default ?group
      Arg.(some ipv4_address)
      "ipv4-gateway"
end

module V6 = struct
  let network ?group ?(docs = Mirage_runtime.s_net) default =
    let doc =
      str "The network of %a specified as IPv6 address and prefix length."
        pp_group group
    in
    runtime_arg ~doc ~docs ~docv:"PREFIX" ~default ?group Arg.(some ipv6) "ipv6"

  let gateway ?group ?(docs = Mirage_runtime.s_net) default =
    let doc = str "The gateway of %a." pp_group group in
    runtime_arg ~doc ~docs ~docv:"IP" ~default ?group
      Arg.(some ipv6_address)
      "ipv6-gateway"

  let accept_router_advertisements ?group ?(docs = Mirage_runtime.s_net) () =
    let doc = str "Accept router advertisements for %a." pp_group group in
    runtime_arg ~doc ~docs ?group ~default:true Arg.bool
      "accept-router-advertisements"
end

let ipv4_only ?group ?(docs = Mirage_runtime.s_net) () =
  let doc = str "Only use IPv4 for %a." pp_group group in
  runtime_arg ~doc ~docs ?group ~default:false Arg.bool "ipv4-only"

let ipv6_only ?group ?(docs = Mirage_runtime.s_net) () =
  let doc = str "Only use IPv6 for %a." pp_group group in
  runtime_arg ~doc ~docs ?group ~default:false Arg.bool "ipv6-only"

let resolver ?group ?(docs = Mirage_runtime.s_net) ?default () =
  let doc = str "DNS resolver (default to anycast.censurfridns.dk)" in
  runtime_arg ~doc ~docv:"IP" ~docs ?group ~default
    Arg.(some (list string))
    "resolver"

let syslog ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "syslog server" in
  runtime_arg ~doc ~docv:"IP" ~docs ?group ~default
    Arg.(some ip_address)
    "syslog"

let monitor ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "monitor server" in
  runtime_arg ~doc ~docv:"IP" ~docs ?group ~default
    Arg.(some ip_address)
    "monitor"

let syslog_port ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "syslog server port" in
  runtime_arg ~doc ~docs ~docv:"PORT" ?group ~default
    Arg.(some int)
    "syslog-port"

let syslog_hostname ?group ?(docs = Mirage_runtime.s_log) default =
  let doc = str "hostname to report to syslog" in
  runtime_arg ~doc ~docs ~docv:"NAME" ?group ~default Arg.string
    "syslog-hostname"

module Arg = Conv

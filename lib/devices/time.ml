open Functoria.DSL

type time = TIME

let time = typ TIME

let default_time =
  let unix_time =
    impl ~packages:[ package "mirage-time" ] "Unix_os.Time" time
  in
  let solo5_time =
    impl ~packages:[ package "mirage-time" ] "Solo5_os.Time" time
  in
  let xen_time = impl ~packages:[ package "mirage-time" ] "Xen_os.Time" time in
  let unikraft_time =
    impl ~packages:[ package "mirage-time" ] "Unikraft_os.Time" time
  in
  match_impl
    Key.(value target)
    [
      (`Unix, unix_time);
      (`MacOSX, unix_time);
      (`Xen, xen_time);
      (`Qubes, xen_time);
      (`Virtio, solo5_time);
      (`Hvt, solo5_time);
      (`Spt, solo5_time);
      (`Muen, solo5_time);
      (`Genode, solo5_time);
      (`QEMU, unikraft_time);
      (`Firecracker, unikraft_time);
    ]
    ~default:unix_time

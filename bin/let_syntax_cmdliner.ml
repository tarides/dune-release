open Cmdliner.Term

let ( let+ ) t f = const f $ t
let ( and+ ) a b = const (fun x y -> (x, y)) $ a $ b

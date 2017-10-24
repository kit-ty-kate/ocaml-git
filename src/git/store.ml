(*
 * Copyright (c) 2013-2017 Thomas Gazagnaire <thomas@gazagnaire.org>
 * and Romain Calascibetta <romain.calascibetta@gmail.com>
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

module type LOOSE =
sig
  type t
  type state

  type kind =
    [ `Commit
    | `Tree
    | `Tag
    | `Blob ]

  module Hash
    : S.HASH
  module Path
    : S.PATH
  module FileSystem
    : S.FS
      with type path = Path.t
  module Inflate
    : S.INFLATE
  module Deflate
    : S.DEFLATE

  module Value
    : Value.S
      with module Hash = Hash
       and module Inflate = Inflate
       and module Deflate = Deflate

  type error =
    [ `SystemFile of FileSystem.File.error
    | `SystemDirectory of FileSystem.Dir.error
    | `SystemIO of string
    | Value.D.error
    | Value.E.error ]

  val pp_error : error Fmt.t

  val lookup_p : state -> Hash.t -> Hash.t option Lwt.t
  val lookup : state -> Hash.t -> Hash.t option Lwt.t

  val exists : state -> Hash.t -> bool Lwt.t

  val list : state -> Hash.t list Lwt.t

  val read_p :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> raw:Cstruct.t
    -> window:Inflate.window
    -> state -> Hash.t -> (t, error) result Lwt.t

  val read_s : state -> Hash.t -> (t, error) result Lwt.t
  val read : state -> Hash.t -> (t, error) result Lwt.t

  val size_p :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> raw:Cstruct.t
    -> window:Inflate.window
    -> state -> Hash.t -> (int64, error) result Lwt.t

  val size_s : state -> Hash.t -> (int64, error) result Lwt.t
  val size : state -> Hash.t -> (int64, error) result Lwt.t

  val write_p :
       ztmp:Cstruct.t
    -> raw:Cstruct.t
    -> state -> t -> (Hash.t * int, error) result Lwt.t

  val write_s : state -> t -> (Hash.t * int, error) result Lwt.t
  val write : state -> t -> (Hash.t * int, error) result Lwt.t

  val write_inflated : state -> kind:kind -> Cstruct.t -> Hash.t Lwt.t

  val raw_p :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> window:Inflate.window
    -> raw:Cstruct.t
    -> state -> Hash.t -> (kind * Cstruct.t, error) result Lwt.t

  val raw_s : state -> Hash.t -> (kind * Cstruct.t, error) result Lwt.t
  val raw : state -> Hash.t -> (kind * Cstruct.t, error) result Lwt.t

  val raw_wa :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> window:Inflate.window
    -> raw:Cstruct.t
    -> result:Cstruct.t
    -> state -> Hash.t -> (kind * Cstruct.t, error) result Lwt.t

  val raw_was : Cstruct.t -> state -> Hash.t -> (kind * Cstruct.t, error) result Lwt.t

  module D
    : S.DECODER
      with type t = t
       and type raw = Cstruct.t
       and type init = Inflate.window * Cstruct.t * Cstruct.t
       and type error = [ `Decoder of string | `Inflate of Inflate.error ]

  module E
    : S.ENCODER
      with type t = t
       and type raw = Cstruct.t
       and type init = int * t * int * Cstruct.t
       and type error = [ `Deflate of Deflate.error ]
end

module type PACK =
sig
  type t
  type value
  type state

  module Hash
    : S.HASH
  module Path
    : S.PATH
  module FileSystem
    : S.FS
      with type path = Path.t
  module Inflate
    : S.INFLATE
  module Deflate
    : S.DEFLATE
  module PACKDecoder
    : Unpack.DECODER
      with module Hash = Hash
       and module Inflate = Inflate
  module PACKEncoder
    : Pack.ENCODER
      with module Hash = Hash
       and module Deflate = Deflate
  module IDXDecoder
    : Index_pack.LAZY
      with module Hash = Hash
  module IDXEncoder
    : Index_pack.ENCODER
      with module Hash = Hash
  module Pack_info
    : Pack_info.S
      with module Hash = Hash
       and module Inflate = Inflate

  type error =
    [ `PackDecoder of PACKDecoder.error
    | `PackEncoder of PACKEncoder.error
    | `PackInfo of Pack_info.error
    | `IdxDecoder of IDXDecoder.error
    | `IdxEncoder of IDXEncoder.error
    | `SystemFile of FileSystem.File.error
    | `SystemMapper of FileSystem.Mapper.error
    | `SystemDir of FileSystem.Dir.error
    | `Invalid_hash of Hash.t
    | `Delta of PACKEncoder.Delta.error
    | `SystemIO of string
    | `Integrity of string
    | `Not_found ]

  val pp_error : error Fmt.t

  val lookup : state -> Hash.t -> (Hash.t * (Crc32.t * int64)) option Lwt.t

  val exists : state -> Hash.t -> bool Lwt.t

  val list : state -> Hash.t list Lwt.t

  val read_p :
       ztmp:Cstruct.t
    -> window:Inflate.window
    -> state -> Hash.t -> (t, error) result Lwt.t

  val read_s : state -> Hash.t -> (t, error) result Lwt.t
  val read : state -> Hash.t -> (t, error) result Lwt.t

  val size_p :
       ztmp:Cstruct.t
    -> window:Inflate.window
    -> state -> Hash.t -> (int, error) result Lwt.t

  val size_s : state -> Hash.t -> (int, error) result Lwt.t
  val size : state -> Hash.t -> (int, error) result Lwt.t

  type stream = unit -> Cstruct.t option Lwt.t

  val from : state -> stream -> (Hash.t * int, error) result Lwt.t

  val make : state -> ?window:[ `Object of int | `Memory of int ] -> ?depth:int -> value list -> (stream, error) result Lwt.t
end

module type S =
sig
  type t

  (* XXX(dinosaure): Functorized module. *)
  module Hash
    : S.HASH
  module Path
    : S.PATH
  module Inflate
    : S.INFLATE
  module Deflate
    : S.DEFLATE
  module Lock
    : S.LOCK
  module FileSystem
    : S.FS
      with type path = Path.t
       and type File.lock = Lock.elt

  module Value
    : Value.S
      with module Hash = Hash
       and module Inflate = Inflate
       and module Deflate = Deflate
  module Reference
    : Reference.IO
      with module Hash = Hash
       and module Path = Path
       and module Lock = Lock
       and module FileSystem = FileSystem

  module PACKDecoder
    : Unpack.DECODER
      with module Hash = Hash
       and module Inflate = Inflate
  module PACKEncoder
    : Pack.ENCODER
      with module Hash = Hash
       and module Deflate = Deflate

  module Loose
    : LOOSE
      with type t = Value.t
       and type state = t
       and module Hash = Hash
       and module Path = Path
       and module Inflate = Inflate
       and module Deflate = Deflate
       and module FileSystem = FileSystem

  module Pack
    : PACK
      with type t = PACKDecoder.Object.t
       and type value = Value.t
       and type state = t
       and module Hash = Hash
       and module Path = Path
       and module FileSystem = FileSystem
       and module Inflate = Inflate

  type kind =
    [ `Commit
    | `Tree
    | `Tag
    | `Blob ]

  type error =
    [ Loose.error
    | Pack.error ]

  val pp_error : error Fmt.t

  val create :
       ?root:Path.t
    -> ?dotgit:Path.t
    -> ?compression:int
    -> unit -> (t, error) result Lwt.t

  val dotgit : t -> Path.t
  val root : t -> Path.t
  val compression : t -> int

  val exists : t -> Hash.t -> bool Lwt.t

  val list : t -> Hash.t list Lwt.t

  val read_p :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> raw:Cstruct.t
    -> window:Inflate.window
    -> t -> Hash.t -> (Value.t, error) result Lwt.t

  val read_s : t -> Hash.t -> (Value.t, error) result Lwt.t
  val read : t -> Hash.t -> (Value.t, error) result Lwt.t
  val read_exn : t -> Hash.t -> Value.t Lwt.t

  val write_p :
       ztmp:Cstruct.t
    -> raw:Cstruct.t
    -> t -> Value.t -> (Hash.t * int, error) result Lwt.t

  val write_s : t -> Value.t -> (Hash.t * int, error) result Lwt.t
  val write : t -> Value.t -> (Hash.t * int, error) result Lwt.t

  val size_p :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> raw:Cstruct.t
    -> window:Inflate.window
    -> t -> Hash.t -> (int64, error) result Lwt.t

  val size_s : t -> Hash.t -> (int64, error) result Lwt.t
  val size : t -> Hash.t -> (int64, error) result Lwt.t

  val raw_p :
       ztmp:Cstruct.t
    -> dtmp:Cstruct.t
    -> raw:Cstruct.t
    -> window:Inflate.window
    -> t -> Hash.t -> (kind * Cstruct.t) option Lwt.t

  val raw_s : t -> Hash.t -> (kind * Cstruct.t) option Lwt.t
  val raw : t -> Hash.t -> (kind * Cstruct.t) option Lwt.t

  val read_inflated  : t -> Hash.t -> (kind * Cstruct.t) option Lwt.t

  val write_inflated : t -> kind:kind -> Cstruct.t -> Hash.t Lwt.t

  val contents : t -> ((Hash.t * Value.t) list, error) result Lwt.t

  val buffer_window : t -> Inflate.window
  val buffer_zl : t -> Cstruct.t
  val buffer_de : t -> Cstruct.t
  val buffer_io : t -> Cstruct.t

  val fold : t -> ('a -> ?name:Path.t -> length:int64 -> Hash.t -> Value.t -> 'a Lwt.t) -> path:Path.t -> 'a -> Hash.t -> 'a Lwt.t

  module Ref :
  sig
    module Packed_refs
      : Packed_refs.S
        with module Hash = Hash
         and module Path = Path
         and module FileSystem = FileSystem

    type nonrec error =
      [ Packed_refs.error
      | error
      | `Invalid_reference of Reference.t ]

    val pp_error : error Fmt.t

    val graph_p :
         dtmp:Cstruct.t
      -> raw:Cstruct.t
      -> t -> (Hash.t Reference.Map.t, error) result Lwt.t

    val graph : t -> (Hash.t Reference.Map.t, error) result Lwt.t

    val normalize : Hash.t Reference.Map.t -> Reference.head_contents -> (Hash.t, error) result Lwt.t

    val list_p :
         dtmp:Cstruct.t
      -> raw:Cstruct.t
      -> t -> (Reference.t * Hash.t) list Lwt.t

    val list_s : t -> (Reference.t * Hash.t) list Lwt.t
    val list : t -> (Reference.t * Hash.t) list Lwt.t

    val remove_p :
         dtmp:Cstruct.t
      -> raw:Cstruct.t
      -> ?locks:Lock.t
      -> t -> Reference.t -> (unit, error) result Lwt.t

    val remove_s : t -> ?locks:Lock.t -> Reference.t -> (unit, error) result Lwt.t
    val remove : t -> ?locks:Lock.t -> Reference.t -> (unit, error) result Lwt.t

    val read_p :
         dtmp:Cstruct.t
      -> raw:Cstruct.t
      -> t -> Reference.t -> ((Reference.t * Reference.head_contents), error) result Lwt.t

    val read_s : t -> Reference.t -> ((Reference.t * Reference.head_contents), error) result Lwt.t
    val read : t -> Reference.t -> ((Reference.t * Reference.head_contents), error) result Lwt.t

    val write_p :
         ?locks:Lock.t
      -> dtmp:Cstruct.t
      -> raw:Cstruct.t
      -> t -> Reference.t -> Reference.head_contents -> (unit, error) result Lwt.t

    val write_s : t -> ?locks:Lock.t -> Reference.t -> Reference.head_contents -> (unit, error) result Lwt.t
    val write : t -> ?locks:Lock.t -> Reference.t -> Reference.head_contents -> (unit, error) result Lwt.t

    val test_and_set :
        t
     -> ?locks:Lock.t
     -> Reference.t
     -> test:Reference.head_contents option
     -> set:Reference.head_contents option
     -> (bool, error) result Lwt.t
  end

  val clear_caches : ?locks:Lock.t -> t -> unit Lwt.t
  val reset        : ?locks:Lock.t -> t -> (unit, Ref.error) result Lwt.t
end

module Option =
struct
  let get ~default = function Some x -> x | None -> default
  let map f a = match a with Some a -> Some (f a) | None -> None
end

module Make
    (H : S.HASH with type Digest.buffer = Cstruct.t
                 and type hex = string)
    (P : S.PATH)
    (L : S.LOCK with type key = P.t
                 and type +'a io = 'a Lwt.t)
    (FS : S.FS with type path = P.t
                and type File.raw = Cstruct.t
                and type File.lock = L.elt
                and type Mapper.raw = Cstruct.t
                and type +'a io = 'a Lwt.t)
    (I : S.INFLATE)
    (D : S.DEFLATE)
  : S with module Hash = H
       and module Path = P
       and module Lock = L
       and module FileSystem = FS
       and module Inflate = I
       and module Deflate = D
= struct
  module Hash = H
  module Path = P
  module Inflate = I
  module Deflate = D
  module Lock = L
  module FileSystem = FS

  module LooseImpl
    : Loose.S
      with module Hash = Hash
       and module Path = Path
       and module FileSystem = FileSystem
       and module Inflate = Inflate
       and module Deflate = Deflate
    = Loose.Make(H)(P)(FS)(I)(D)

  module PackImpl
    : Pack_engine.S
      with module Hash = Hash
       and module Path = Path
       and module FileSystem = FileSystem
       and module Inflate = Inflate
       and module Deflate = Deflate
    = Pack_engine.Make(H)(P)(FS)(I)(D)

  module Value
    : Value.S
      with module Hash = Hash
       and module Inflate = Inflate
       and module Deflate = Deflate
       and module Blob = LooseImpl.Blob
       and module Tree = LooseImpl.Tree
       and module Tag = LooseImpl.Tag
       and module Commit = LooseImpl.Commit
       and type t = LooseImpl.t
    = LooseImpl

  module PACKDecoder = PackImpl.PACKDecoder
  module PACKEncoder = PackImpl.PACKEncoder
  module IDXDecoder = PackImpl.IDXDecoder

  module Reference = Reference.IO(H)(P)(L)(FS)

  module DoubleHash =
  struct
    type t = Hash.t * Hash.t

    let hash = Hashtbl.hash

    let equal (a, b) (c, d) =
      Hash.equal a c && Hash.equal b d
  end

  module HashInt64 =
  struct
    type t = Hash.t * int64

    let hash = Hashtbl.hash

    let equal (a, b) (c, d) =
      Hash.equal a c && Int64.equal b d
  end

  (* XXX(dinosaure): need to limit the weight of [CacheObject] and
     [CacheValue] by the memory consumption of the data stored - and
     not by the number of theses data. Indeed, 5 commits is more
     cheaper than 1 blob sometimes. *)
  module CacheObject   = Lru.M.Make(DoubleHash)(struct type t = PACKDecoder.Object.t let weight _ = 1 end)
  module CacheValue    = Lru.M.Make(Hash)(struct type t = Value.t let weight _ = 1 end)
  module CachePack     = Lru.M.Make(Hash)(struct type t = PACKDecoder.t let weight _ = 1 end) (* fixed size *)
  module CacheIndex    = Lru.M.Make(Hash)(struct type t = IDXDecoder.t let weight _ = 1 end) (* not fixed size by consider than it's ok. *)
  module CacheRevIndex = Lru.M.Make(HashInt64)(struct type t = Hash.t let weight _ = 1 end) (* fixed size *)

  type cache =
    { objects     : CacheObject.t
    ; values      : CacheValue.t
    ; packs       : CachePack.t
    ; indexes     : CacheIndex.t
    ; revindexes  : CacheRevIndex.t }
  and buffer =
    { window      : Inflate.window
    ; io          : Cstruct.t
    ; zl          : Cstruct.t
    ; de          : Cstruct.t }
  and t =
    { dotgit      : Path.t
    ; root        : Path.t
    ; compression : int
    ; cache       : cache
    ; buffer      : buffer
    ; engine      : PackImpl.t }

  module Loose =
  struct
    module Hash = Hash
    module Path = Path
    module FileSystem = FileSystem
    module Inflate = Inflate
    module Deflate = Deflate
    module Value = Value

    type state = t
    type t = LooseImpl.t

    type kind = LooseImpl.kind

    type error = LooseImpl.error

    let pp_error = LooseImpl.pp_error

    let read_p ~ztmp ~dtmp ~raw ~window t =
      LooseImpl.read ~root:t.dotgit ~window ~ztmp ~dtmp ~raw
    let size_p ~ztmp ~dtmp ~raw ~window t =
      LooseImpl.size ~root:t.dotgit ~window ~ztmp ~dtmp ~raw
    let write_p ~ztmp ~raw t value =
      LooseImpl.write ~root:t.dotgit ~ztmp ~raw ~level:t.compression value

    let exists t =
      LooseImpl.exists
        ~root:t.dotgit
    let read_s t =
      LooseImpl.read
        ~root:t.dotgit
        ~window:t.buffer.window
        ~ztmp:t.buffer.zl
        ~dtmp:t.buffer.de
        ~raw:t.buffer.io
    let read = read_s
    let size_s t =
      LooseImpl.size
        ~root:t.dotgit
        ~window:t.buffer.window
        ~ztmp:t.buffer.zl
        ~dtmp:t.buffer.de
        ~raw:t.buffer.io
    let size = size_s
    let list t =
      LooseImpl.list
        ~root:t.dotgit
    let write_s t value =
      write_p ~ztmp:t.buffer.zl ~raw:t.buffer.io t value
    let write = write_s

    let lookup_p t hash =
      let open Lwt.Infix in

      LooseImpl.exists ~root:t.dotgit hash >|= function
      | true -> Some hash
      | false -> None

    let lookup = lookup_p

    let raw_p ~ztmp ~dtmp ~window ~raw t hash =
      LooseImpl.inflate ~root:t.dotgit ~window ~ztmp ~dtmp ~raw hash

    let raw_s t hash =
      raw_p
        ~window:t.buffer.window
        ~ztmp:t.buffer.zl
        ~dtmp:t.buffer.de
        ~raw:t.buffer.io
        t hash

    let raw = raw_s

    let raw_wa ~ztmp ~dtmp ~window ~raw ~result t hash =
      LooseImpl.inflate_wa ~root:t.dotgit ~window ~ztmp ~dtmp ~raw ~result hash

    let raw_was result t hash =
      raw_wa
        ~window:t.buffer.window
        ~ztmp:t.buffer.zl
        ~raw:t.buffer.io
        ~dtmp:t.buffer.de
        ~result
        t hash

    let write_inflated t ~kind value =
      let open Lwt.Infix in

      LooseImpl.write_inflated
        ~root:t.dotgit
        ~level:t.compression
        ~raw:t.buffer.io
        ~kind
        value >>= function
      | Ok hash -> Lwt.return hash
      | Error (#LooseImpl.error as err) ->
        Lwt.fail (Failure (Fmt.strf "%a" LooseImpl.pp_error err))

    module D
      : S.DECODER
        with type t = t
         and type raw = Cstruct.t
         and type init = Inflate.window * Cstruct.t * Cstruct.t
         and type error = Value.D.error
      = Value.D

    module E
      : S.ENCODER
        with type t = t
         and type raw = Cstruct.t
         and type init = int * t * int * Cstruct.t
         and type error = Value.E.error
      = Value.E
  end

  module Pack =
  struct
    module Hash = Hash
    module Path = Path
    module FileSystem = FileSystem
    module Inflate = Inflate
    module Deflate = Deflate

    module Pack_info = PackImpl.Pack_info
    module IDXEncoder = PackImpl.IDXEncoder
    module IDXDecoder = PackImpl.IDXDecoder
    module PACKEncoder = PackImpl.PACKEncoder
    module PACKDecoder = PackImpl.PACKDecoder

    module Log =
    struct
      let src = Logs.Src.create "git.store.pack" ~doc:"logs git's store event (pack)"
      include (val Logs.src_log src : Logs.LOG)
    end

    type state = t

    type error =
      [ `SystemIO of string
      | `Delta of PACKEncoder.Delta.error
      | PackImpl.error ]

    let pp_error ppf = function
      | `SystemIO err -> Fmt.pf ppf "(`SystemIO %s)" err
      | `Delta err -> Fmt.pf ppf "(`Delta %a)" PACKEncoder.Delta.pp_error err
      | #PackImpl.error as err -> PackImpl.pp_error ppf err

    type t = PACKDecoder.Object.t
    type value = Value.t

    let lookup t hash =
      PackImpl.lookup t.engine hash

    let exists t hash =
      PackImpl.exists t.engine hash

    let list t =
      PackImpl.list t.engine

    let read_p ~ztmp ~window t hash =
      let open Lwt.Infix in

      exists t hash >>= function
      | false -> Lwt.return (Error `Not_found)
      | true ->
        Log.debug (fun l -> l "Git object %a found in a PACK file."
                      Hash.pp hash);

        let ( >!= ) = Lwt_result.bind_lwt_err in

        PackImpl.read ~root:t.dotgit ~ztmp ~window t.engine hash
        >!= (fun err -> Lwt.return (err :> error))

    let read_s t hash =
      read_p ~ztmp:t.buffer.zl ~window:t.buffer.window t hash

    let read = read_s

    let size_p ~ztmp ~window t hash =
      let open Lwt.Infix in

      exists t hash >>= function
      | false -> Lwt.return (Error `Not_found)
      | true ->
        let ( >!= ) = Lwt_result.bind_lwt_err in

        PackImpl.size ~root:t.dotgit ~ztmp ~window t.engine hash
        >!= (fun err -> Lwt.return (err :> error))

    let size_s t hash =
      size_p
        ~ztmp:t.buffer.zl
        ~window:t.buffer.window
        t hash

    let size = size_s

    type stream = unit -> Cstruct.t option Lwt.t

    let random_string len =
      let gen () = match Random.int (26 + 26 + 10) with
        | n when n < 26 -> int_of_char 'a' + n
        | n when n < 26 + 26 -> int_of_char 'A' + n - 26
        | n -> int_of_char '0' + n - 26 - 26
      in
      let gen () = char_of_int (gen ()) in

      Bytes.create len |> fun raw ->
      for i = 0 to len - 1 do Bytes.set raw i (gen ()) done;
      Bytes.unsafe_to_string raw


    let to_temp_file fmt stream =
      let filename_of_pack = fmt (random_string 10) in

      let open Lwt.Infix in

      FileSystem.Dir.temp () >>= fun temp_dir ->
      FileSystem.File.open_w ~mode:0o644 Path.(temp_dir / filename_of_pack) >>= function
      | Error err -> Lwt.return (Error (`SystemFile err))
      | Ok fd ->
        Log.debug (fun l -> l ~header:"to_temp_file" "Save the pack stream to the file %a."
                      Path.pp Path.(temp_dir / filename_of_pack));

        let rec go ?chunk ~call () = Lwt_stream.peek stream >>= function
          | None ->
            Log.debug (fun l -> l ~header:"to_temp_file" "Pack stream saved to the file %a."
                          Path.pp Path.(temp_dir / filename_of_pack));

            (FileSystem.File.close fd >>= function
              | Ok () -> Lwt.return (Ok Path.(temp_dir / filename_of_pack))
              | Error err ->
                Log.err (fun l -> l ~header:"to_temp_file" "Cannot close the file: %s." filename_of_pack);
                Lwt.return (Error (`SystemFile err)))
          | Some raw ->
            Log.debug (fun l -> l ~header:"to_temp_file" "Receive a chunk of the pack stream (length: %d)."
                          (Cstruct.len raw));

            let off, len = match chunk with
              | Some (off, len) -> off, len
              | None -> 0, Cstruct.len raw
            in

            FileSystem.File.write raw ~off ~len fd >>= function
            | Ok 0 when len <> 0 ->
              if call = 50 (* XXX(dinosaure): as argument? *)
              then
                let err = Fmt.strf "Impossible to store the file: %s." filename_of_pack in

                FileSystem.File.close fd >>= function
                | Ok () -> Lwt.return (Error (`SystemIO err))
                | Error _ ->
                  Log.err (fun l -> l ~header:"to_temp_file" "Cannot close the file: %s." filename_of_pack);
                  Lwt.return (Error (`SystemIO err))
              else go ?chunk ~call:(call + 1) ()
            | Ok n when n = len ->
              Log.debug (fun l -> l ~header:"to_temp_file" "Consume current chunk of the pack stream.");
              Lwt_stream.junk stream >>= fun () -> go ~call:0 ()
            | Ok n ->
              let chunk = (off + n, len - n) in
              go ~chunk ~call:0 ()
            | Error err ->
              FileSystem.File.close fd >>= function
              | Ok () -> Lwt.return (Error (`SystemFile err))
              | Error _ ->
                Log.err (fun l -> l ~header:"to_temp_file" "Cannot close the file: %s." filename_of_pack);
                Lwt.return (Error (`SystemFile err))
        in

        go ~call:0 ()

    let extern git hash =
      let open Lwt.Infix in

      read_p
        ~ztmp:git.buffer.zl
        ~window:git.buffer.window
        git hash >>= function
      | Ok o ->
        Lwt.return (Some (o.PACKDecoder.Object.kind, o.PACKDecoder.Object.raw))
      | Error _ -> Loose.lookup git hash >>= function
        | None -> Lwt.return None
        | Some _ ->
          Loose.raw_p
            ~window:git.buffer.window
            ~ztmp:git.buffer.zl
            ~dtmp:git.buffer.de
            ~raw:git.buffer.io
            git hash >>= function
          | Error #Loose.error -> Lwt.return None
          | Ok v -> Lwt.return (Some v)

    module GC =
      Gc.Make(struct
        module Hash = Hash
        module Path = Path
        module Value = Value
        module Deflate = Deflate

        type nonrec t = state
        type nonrec error = error
        type kind = PACKDecoder.kind

        let pp_error = pp_error
        let read_inflated = extern
        let contents _ = assert false
      end)

    let make = GC.make_stream

    let canonicalize git path_pack decoder_pack fdp ~htmp ~rtmp ~ztmp ~window delta info =
      let k2k = function
        | `Commit -> Pack.Kind.Commit
        | `Blob -> Pack.Kind.Blob
        | `Tree -> Pack.Kind.Tree
        | `Tag -> Pack.Kind.Tag
      in

      let open Lwt.Infix in

      let make acc (hash, (_, offset)) =
        PACKDecoder.optimized_get' ~h_tmp:htmp decoder_pack offset rtmp ztmp window >>= function
        | Error err ->
          Log.err (fun l -> l ~header:"from" "Retrieve an error when we try to \
                                              resolve the object at the offset %Ld \
                                              in the temporary pack file %a: %a."
                      offset Path.pp path_pack PACKDecoder.pp_error err);
          Lwt.return acc
        | Ok obj ->
          let delta = match obj.PACKDecoder.Object.from with
            | PACKDecoder.Object.External hash -> Some (PACKEncoder.Entry.From hash)
            | PACKDecoder.Object.Direct _ -> None
            | PACKDecoder.Object.Offset { offset; _ } ->
              try let (_, hash) = Pack_info.Graph.find offset info.Pack_info.graph in
                Option.map (fun hash -> PACKEncoder.Entry.From hash) hash
              with Not_found -> None
          in

          Lwt.return (PACKEncoder.Entry.make hash ?delta (k2k obj.PACKDecoder.Object.kind) obj.PACKDecoder.Object.length :: acc)
      in

      let external_ressources acc =
        List.fold_left
          (fun acc (_, hunks_descr) ->
             let open Pack_info in

             match hunks_descr.PACKDecoder.H.reference with
             | PACKDecoder.H.Hash hash when not (Radix.exists info.tree hash) ->
               (try List.find (Hash.equal hash) acc |> fun _ -> acc
                with Not_found -> hash :: acc)
             | _ -> acc)
          [] delta
        |> Lwt_list.fold_left_s
          (fun acc hash -> extern git hash >>= function
             | None ->
               Lwt.return acc
             | Some (kind, raw) ->
               let entry = PACKEncoder.Entry.make hash (k2k kind) (Int64.of_int (Cstruct.len raw)) in
               Lwt.return (entry :: acc))
          acc
      in

      let get hash =
        if Pack_info.Radix.exists info.Pack_info.tree hash
        then PACKDecoder.get_with_allocation
            ~h_tmp:htmp
            decoder_pack
            hash
            ztmp window >>= function
          | Error _ ->
            Lwt.return None
          | Ok obj -> Lwt.return (Some obj.PACKDecoder.Object.raw)
        else extern git hash >|= function
          | Some (_, raw) -> Some raw
          | None -> None
      in

      let tag _ = false in

      Pack_info.Radix.to_list info.Pack_info.tree
      |> Lwt_list.fold_left_s make []
      >>= external_ressources
      >>= fun entries -> PACKEncoder.Delta.deltas ~memory:false entries get tag 10 50
      >>= function
      | Error err -> Lwt.return (Error (`Delta err))
      | Ok entries ->
        PackImpl.save_pack_file
          (Fmt.strf "pack-%s.pack")
          entries
          (fun hash ->
             if Pack_info.Radix.exists info.Pack_info.tree hash
             then PACKDecoder.get_with_allocation
                 ~h_tmp:htmp
                 decoder_pack
                 hash
                 ztmp window >>= function
               | Error _ ->
                 Lwt.return None
               | Ok obj ->
                 Lwt.return (Some (obj.PACKDecoder.Object.raw))
             else extern git hash >|= function
               | Some (_, raw) -> Some raw
               | None -> None)
          >>= function
          | Error err -> Lwt.return (Error (err :> error))
          | Ok (path, sequence, hash_pack) ->
            PackImpl.save_idx_file ~root:git.dotgit sequence hash_pack >>= function
            | Error err -> Lwt.return (Error (err :> error))
            | Ok () ->
              let filename_pack = Fmt.strf "pack-%s.pack" (Hash.to_hex hash_pack) in

              (FileSystem.File.move path Path.(git.dotgit / "objects" / "pack" / filename_pack) >>= function
              | Error sys_err -> Lwt.return (Error (`SystemFile sys_err))
              | Ok () -> Lwt.return (Ok (hash_pack, List.length entries)))
              >>= fun ret ->
              FileSystem.Mapper.close fdp >>= function
              | Error sys_err ->
                Log.err (fun l -> l ~header:"canonicalize" "Impossible to close the pack file %a: %a."
                            Path.pp path_pack FileSystem.Mapper.pp_error sys_err);
                Lwt.return ret
              | Ok () -> Lwt.return ret

    let from git stream =
      let open Lwt.Infix in

      let ztmp = Cstruct.create 0x8000 in
      let window = Inflate.window () in

      let stream0, stream1 =
        let stream', push' = Lwt_stream.create () in

        Lwt_stream.from
          (fun () -> stream () >>= function
             | Some raw ->
               Log.debug (fun l -> l ~header:"from" "Dispatch a chunk of the PACK stream (length: %d)."
                             (Cstruct.len raw));
               push' (Some raw);
               Lwt.return (Some raw)
             | None ->
               Log.debug (fun l -> l ~header:"from" "Dispatch end of the PACK stream.");
               push' None;
               Lwt.return None),
        stream'
      in

      let info = Pack_info.v (Hash.of_hex (String.make (Hash.Digest.length * 2) '0')) in

      let ( >!= ) = Lwt_result.bind_lwt_err in

      let open Lwt_result in

      (Pack_info.from_stream ~ztmp ~window info (fun () -> Lwt_stream.get stream0)
       >!= (fun sys_err -> Lwt.return (`PackInfo sys_err))) >>= fun info ->
      to_temp_file (Fmt.strf "pack-%s.pack") stream1 >>= fun path ->

      let module Graph = Pack_info.Graph in
      let open Lwt.Infix in

      FileSystem.Mapper.openfile path >>= function
      | Error err -> Lwt.return (Error (`SystemMapper err))
      | Ok fdp ->
        let `Partial { Pack_info.Partial.hash = hash_pack; Pack_info.Partial.delta; } = info.Pack_info.state in

        let htmp =
          let raw = Cstruct.create (info.Pack_info.max_length_insert_hunks * (info.Pack_info.max_depth + 1)) in
          Array.init
            (info.Pack_info.max_depth + 1)
            (fun i -> Cstruct.sub raw (i * info.Pack_info.max_length_insert_hunks) info.Pack_info.max_length_insert_hunks)
        in

        let rtmp =
          Cstruct.create info.Pack_info.max_length_object,
          Cstruct.create info.Pack_info.max_length_object,
          info.Pack_info.max_length_object
        in

        PACKDecoder.make fdp
          (fun _ -> None)
          (fun hash -> Pack_info.Radix.lookup info.Pack_info.tree hash)
          (* XXX(dinosaure): this function will be updated. *)
          (fun _ -> None)
          (fun hash -> extern git hash)
        >>= function
        | Error err -> Lwt.return (Error (`SystemMapper err))
        | Ok decoder ->
          let hash_of_object obj =
            let ctx = Hash.Digest.init () in
            let hdr = Fmt.strf "%s %Ld\000"
                (match obj.PACKDecoder.Object.kind with
                 | `Commit -> "commit"
                 | `Blob   -> "blob"
                 | `Tree   -> "tree"
                 | `Tag    -> "tag")
                obj.PACKDecoder.Object.length
            in

            Hash.Digest.feed ctx (Cstruct.of_string hdr);
            Hash.Digest.feed ctx obj.PACKDecoder.Object.raw;
            Hash.Digest.get ctx
          in

          let crc obj = match obj.PACKDecoder.Object.from with
            | PACKDecoder.Object.Offset { crc; _ } -> crc
            | PACKDecoder.Object.External _ ->
              raise (Invalid_argument "Try to get the CRC-32 checksum from an external ressource.")
            | PACKDecoder.Object.Direct { crc; _ } -> crc
          in

          Lwt_list.fold_left_s
            (fun ((decoder, tree, graph) as acc) (offset, hunks_descr) ->
               PACKDecoder.optimized_get'
                 ~h_tmp:htmp
                 decoder
                 offset
                 rtmp ztmp window >>= function
               | Ok obj ->
                 let hash = hash_of_object obj in
                 let crc = crc obj in
                 let tree = Pack_info.Radix.bind tree hash (crc, offset) in

                 let graph =
                   let open Pack_info in

                   let depth_source, _ = match hunks_descr.PACKDecoder.H.reference with
                     | PACKDecoder.H.Offset rel_off ->
                       (try Graph.find Int64.(sub offset rel_off) graph
                        with Not_found -> 0, None)
                     | PACKDecoder.H.Hash hash_source ->
                       try match Radix.lookup tree hash_source with
                         | Some (_, abs_off) -> Graph.find abs_off graph
                         | None -> 0, None
                       with Not_found -> 0, None
                   in

                   Graph.add offset (depth_source + 1, Some hash) graph
                 in

                 Lwt.return
                   (PACKDecoder.update_idx (Pack_info.Radix.lookup tree) decoder,
                    tree, graph)
               | Error err ->
                 Log.err (fun l -> l ~header:"from" "Retrieve an error when we try to \
                                                     resolve the object at the offset %Ld \
                                                     in the temporary pack file %a: %a."
                             offset Path.pp path PACKDecoder.pp_error err);
                 Lwt.return acc)
            (decoder, info.Pack_info.tree, info.Pack_info.graph) delta
          >>= fun (decoder, tree', graph') ->

          let is_total =
            Pack_info.Graph.for_all
              (fun _ -> function (_, Some _) -> true | (_, None) -> false)
              graph'
          in

          if is_total
          then
            Lwt_list.for_all_p
              (fun (_, hunks_descr) ->
                 let open Pack_info in

                 match hunks_descr.PACKDecoder.H.reference with
                 | PACKDecoder.H.Offset _ -> Lwt.return true
                 | PACKDecoder.H.Hash hash ->
                   Lwt.return (Radix.exists tree' hash))
              delta
            >>= fun is_not_thin ->
            if is_not_thin
            then
              let open Lwt_result in

              let info =
                { info with Pack_info.tree = tree'
                          ; Pack_info.graph = graph'
                          ; Pack_info.state =
                              `Full { Pack_info.Full.thin = not is_not_thin
                                    ; Pack_info.Full.hash = hash_pack } }
              in

              (FileSystem.Mapper.close fdp
               >!= fun sys_err -> Lwt.return (`SystemMapper sys_err))
              >>= fun () -> PackImpl.add_total ~root:git.dotgit git.engine path info
              >!= fun err -> Lwt.return (err :> error)
            else
              let open Lwt_result in

              canonicalize git path decoder fdp ~htmp ~rtmp ~ztmp ~window delta info
              >>= fun (hash, count) ->
              (PackImpl.add_exists ~root:git.dotgit git.engine hash
               >!= (fun err -> Lwt.return (err :> error)))
              >>= fun () -> Lwt.return (Ok (hash, count))
          else Lwt.return
              (Error (`Integrity (Fmt.strf "Impossible to get all informations from the file: %a."
                                    Hash.pp hash_pack)))
  end

  module Log =
  struct
    let src = Logs.Src.create "git.store" ~doc:"logs git's store event"
    include (val Logs.src_log src : Logs.LOG)
  end

  type error = [ Loose.error | Pack.error ]

  type kind =
    [ `Commit
    | `Blob
    | `Tree
    | `Tag ]

  let pp_error ppf = function
    | #Loose.error as err -> Fmt.pf ppf "%a" Loose.pp_error err
    | #Pack.error as err -> Fmt.pf ppf "%a" Pack.pp_error err

  let read_p ~ztmp ~dtmp ~raw ~window state hash =
    let open Lwt.Infix in

    Pack.read_p ~ztmp ~window state hash >>= function
    | Ok o ->
      (match o.PACKDecoder.Object.kind with
       | `Commit ->
         Value.Commit.D.to_result o.PACKDecoder.Object.raw
         |> Rresult.R.map (fun v -> Value.Commit v)
       | `Blob ->
         Value.Blob.D.to_result o.PACKDecoder.Object.raw
         |> Rresult.R.map (fun v -> Value.Blob v)
       | `Tree ->
         Value.Tree.D.to_result o.PACKDecoder.Object.raw
         |> Rresult.R.map (fun v -> Value.Tree v)
       | `Tag ->
         Value.Tag.D.to_result o.PACKDecoder.Object.raw
         |> Rresult.R.map (fun v -> Value.Tag v))
      |> (function
          | Error (`Decoder err) -> Lwt.return (Error (`Decoder err))
          | Ok v -> Lwt.return (Ok v))
    | Error (#Pack.error as err) -> Loose.lookup state hash >>= function
      | None -> Lwt.return (Error err)
      | Some _ -> Loose.read_p ~window ~ztmp ~dtmp ~raw state hash >>= function
        | Error (#Loose.error as err) -> Lwt.return (Error err)
        | Ok v -> Lwt.return (Ok v)

  let read_s t hash =
    Log.debug (fun l -> l ~header:"read_s" "Request to read %a in the current Git repository." Hash.pp hash);

    read_p
      ~ztmp:t.buffer.zl
      ~dtmp:t.buffer.de
      ~raw:t.buffer.io
      ~window:t.buffer.window
      t hash

  let read =
    Log.debug (fun l -> l ~header:"read" "Use the alias of read_s");
    read_s

  let read_exn t hash =
    let open Lwt.Infix in

    read t hash >>= function
    | Error _ ->
      let err = Fmt.strf "Git.Store.read_exn: %a not found" Hash.pp hash in
      Lwt.fail (Invalid_argument err)
    | Ok v -> Lwt.return v

  let write_p ~ztmp ~raw state hash =
    let open Lwt.Infix in
    Loose.write_p ~ztmp ~raw state hash >|= function
    | Error (#LooseImpl.error as err) -> Error (err :> error)
    | Ok v -> Ok v

  let write_s state hash =
    let open Lwt.Infix in
    Loose.write_s state hash >|= function
    | Error (#LooseImpl.error as err) -> Error (err :> error)
    | Ok v -> Ok v

  let write = write_s

  let raw_p ~ztmp ~dtmp ~raw ~window state hash =
    let open Lwt.Infix in

    Pack.read_p ~ztmp ~window state hash >>= function
    | Ok o ->
      Lwt.return (Some (o.PACKDecoder.Object.kind, o.PACKDecoder.Object.raw))
    | Error _ -> Loose.lookup state hash >>= function
      | None -> Lwt.return None
      | Some _ -> Loose.raw_p ~window ~ztmp ~dtmp ~raw state hash >>= function
        | Error #Loose.error -> Lwt.return None
        | Ok v -> Lwt.return (Some v)

  let raw_s t hash =
    raw_p
      ~ztmp:t.buffer.zl
      ~dtmp:t.buffer.de
      ~raw:t.buffer.io
      ~window:t.buffer.window
      t hash

  let raw = raw_s

  let read_inflated t hash =
    raw_s t hash

  let write_inflated t ~kind value =
    Loose.write_inflated t ~kind value

  let indexes git =
    let open Lwt.Infix in

    FileSystem.Dir.contents ~dotfiles:false ~rel:false Path.(git / "objects" / "pack")[@warning "-44"]
    >>= function
    | Ok lst ->
      Lwt_list.fold_left_s
        (fun acc path ->
           if Path.has_ext "idx" path
           then Lwt.return (path :: acc)
           else Lwt.return acc)
        [] lst
      >>= PackImpl.v >|= fun v -> Ok v
    | Error err -> Lwt.return (Error err)

  let lookup_p state hash =
    let open Lwt.Infix in

    Pack.lookup state hash
    >>= function
    | Some (hash_pack, (_, offset)) -> Lwt.return (`PackDecoder (hash_pack, offset))
    | None -> Loose.lookup state hash >>= function
      | Some _ -> Lwt.return `Loose
      | None -> Lwt.return `Not_found

  let lookup = lookup_p

  let exists state hash =
    let open Lwt.Infix in

    lookup state hash >|= function
    | `Not_found -> false
    | _ -> true

  let list state =
    let open Lwt.Infix in

    Loose.list state
    >>= fun looses -> Pack.list state
    >|= fun packed -> List.append looses packed

  let size_p ~ztmp ~dtmp ~raw ~window state hash =
    let open Lwt.Infix in
    Pack.size_p ~ztmp ~window state hash >>= function
    | Ok v -> Lwt.return (Ok (Int64.of_int v))
    | Error (#Pack.error as err) ->
      Loose.exists state hash >>= function
      | true -> Loose.size_p ~ztmp ~dtmp ~raw ~window state hash >|= Rresult.R.reword_error (fun x -> (x :> error))
      | false -> Lwt.return (Error (err :> error))

  let size_s state hash =
    size_p
      ~ztmp:state.buffer.zl
      ~dtmp:state.buffer.de
      ~raw:state.buffer.io
      ~window:state.buffer.window
      state hash

  let size = size_s

  exception Leave of error

  let contents state =
    let open Lwt.Infix in

    list state
    >>= fun lst ->
    Lwt.try_bind
      (fun () -> Lwt_list.map_s
          (fun hash -> read state hash
            >>= function
            | Ok v -> Lwt.return (hash, v)
            | Error err ->
              Log.err (fun l -> l ~header:"contents" "Retrieve an error: %a." pp_error err);
              Lwt.fail (Leave err))
          lst)
      (fun lst -> Lwt.return (Ok lst))
      (function Leave err -> Lwt.return (Error err)
              | exn -> Lwt.fail exn)

  (*
  let delta entries tagger ?(depth = 50) ?(window = `Object 10) state =
    let open Lwt.Infix in

    let memory, window = match window with `Object w -> false, w | `Memory w -> true, w  in
    let read hash = raw_s state hash >|= function Some (_, raw) -> Some raw | None -> None in

    PACKEncoder.Delta.deltas ~memory entries read tagger depth window

  let gc git =
    let window = `Object 10 in
    let depth = 50 in

    let open Lwt.Infix in

    let memory, window = match window with `Object w -> false, w | `Memory w -> true, w in
    let read hash = raw_s git hash >|= function Some (_, raw) -> Some raw | None -> None in
    let tagger _ = false in

    let names = Hashtbl.create 1024 in

    let make (hash, value) =
      let name =
        try Some (Hashtbl.find names hash)
        with Not_found -> None
      in

      let kind = match value with
        | Value.Commit _ -> Pack.Kind.Commit
        | Value.Tree _ -> Pack.Kind.Tree
        | Value.Tag _ -> Pack.Kind.Tag
        | Value.Blob _ -> Pack.Kind.Blob
      in

      let entry =
        PACKEncoder.Entry.make
          hash
          ?name
          kind
          (Value.F.length value)
      in

      Lwt.return entry
    in

    let random_string len =
      let gen () = match Random.int (26 + 26 + 10) with
        | n when n < 26 -> int_of_char 'a' + n
        | n when n < 26 + 26 -> int_of_char 'A' + n - 26
        | n -> int_of_char '0' + n - 26 - 26
      in

      let gen () = char_of_int (gen ()) in
      Bytes.create len |> fun raw ->
      for i = 0 to len - 1 do Bytes.set raw i (gen ()) done;
      Bytes.unsafe_to_string raw
    in

    let pack_filename = Fmt.strf "pack-%s.pack" (random_string 10) in

    contents git >>= function
    | Error _ -> assert false
    | Ok objects ->
      Lwt_list.iter_p (fun (_, value) -> match value with
          | Value.Tree tree ->
            Lwt_list.iter_p
              (fun entry ->
                 Hashtbl.add names
                   entry.Value.Tree.node
                   entry.Value.Tree.name;
                 Lwt.return ())
              (tree :> Value.Tree.entry list)
          | _ -> Lwt.return ())
        objects
      >>= fun () ->
      Lwt.Infix.(Lwt_list.map_p make objects)
      >>= fun entries ->
      PACKEncoder.Delta.deltas ~memory entries read tagger depth window >>= function
      | Error _ -> assert false
      | Ok entries ->
        let ztmp = Cstruct.create 0x8000 in
        let state = PACKEncoder.default ztmp entries in

        let module EncoderPack =
        struct
          type state = PACKEncoder.t
          type raw = Cstruct.t
          type result = Hash.t * (Crc32.t * int64) PACKEncoder.Radix.t
          type error = PACKEncoder.error

          let raw_length = Cstruct.len
          let raw_blit = Cstruct.blit

          let raw_empty = Cstruct.create 0

          let eval dst state =
            let rec go ?(src = raw_empty) state = match PACKEncoder.eval src dst state with
              | `Flush state -> Lwt.return (`Flush state)
              | `End (state, hash) -> Lwt.return (`End (state, (hash, PACKEncoder.idx state)))
              | `Error (state, err) -> Lwt.return (`Error (state, err))
              | `Await state ->
                let hash = PACKEncoder.expect state in

                raw_s git hash >>= function
                | Some (_, raw) -> go ~src:raw (PACKEncoder.refill 0 (Cstruct.len raw) state)
                | None -> Lwt.fail (Failure (Fmt.strf "Invalid requested hash: %a." Hash.pp hash))
            in
            go state

          let flush = PACKEncoder.flush
          let used = PACKEncoder.used_out
        end
        in

        let raw = Cstruct.create 0x8000 in
        let ( >?= ) a f = Lwt_result.map_err f a in

        let open Lwt_result in

        Lwt.Infix.(FileSystem.Dir.temp () >>= fun path -> Lwt.return (Ok path)) >>= fun temp ->
        (FileSystem.File.open_w ~mode:0o644 Path.(temp / pack_filename)
         >?= fun err -> `SystemFile err)
        >>= fun write ->
        Lwt.Infix.(
          Helper.safe_encoder_to_file
            ~limit:50
            (module EncoderPack)
            FileSystem.File.write
            write raw state
          >>= (fun v -> FileSystem.File.close write >>= fun v' -> match v, v' with
            (* XXX(dinosaure): this semantic is, when we catch an
               error from the close() syscall, we quiet in all case
               expect when the encoder returns [Ok _]. *)

            | v, Ok () -> Lwt.return v
            | (Ok _ as v), Error sys_err ->
              Log.err (fun l -> l ~header:"gc" "Catch an error when we close the PACK file: %a."
                          FileSystem.File.pp_error sys_error);
              Lwt.return v
            | Error v, Error v' ->
              Log.err (fun l -> l ~header:"gc" "Error from the encoder and from the close() syscall (%a)."
                          FileSystem.File.pp_error v')
            | Ok _, Error v' -> Lwt.return (Error (`FileSystem v')))
              >?= (function
                  | `Stack -> `SystemIO (Fmt.strf "Impossible to store the pack file.")
                  | `Encoder err -> `PackEncoder err
                  | `Writer err -> `SystemFile err))
        >>= fun (hash, idx) ->
        let pack_filename' = Fmt.strf "pack-%a.pack" Hash.pp hash in
        (FileSystem.File.move Path.(temp / pack_filename) Path.(t.dotgit / "objects" / "pack" / pack_filename')
         >?= fun err -> `SystemFile err)
        >>= fun () ->

        let state = IDXEncoder.default (PACKEncoder.Radix.to_sequence idx) hash in

        let module EncoderIdx =
        struct
          type state = IDXEncoder.t
          type raw = Cstruct.t
          type result = unit
          type error =IDXEncoder.error

          let raw_length = Cstruct.len
          let raw_blit = Cstruct.blit

          let eval dst state = match IDXEncoder.eval dst state with
            | `Flush state -> Lwt.return (`Flush state)
            | `End state -> Lwt.return (`End (state, ()))
            | `Error _ as err -> Lwt.return err

          let flush = IDXEncoder.flush
          let used = IDXEncoder.used_out
        end
        in

        let idx_filename = Fmt.strf "pack-%a.idx" Hash.pp hash in

        (FileSystem.File.open_w ~mode:0o644 Path.(

        assert false
  *)

  module T =
    Traverse_bfs.Make(struct
      module Hash = Hash
      module Path = Path
      module Value = Value

      type nonrec t = t
      type nonrec error = error

      let pp_error = pp_error
      let read = read
    end)

  let fold = T.fold

  module Ref =
  struct
    module Packed_refs = Packed_refs.Make(Hash)(Path)(FileSystem)
    (* XXX(dinosaure): we need to check the packed references when we write and remove. *)

    let pp_error ppf = function
      | #Packed_refs.error as err -> Fmt.pf ppf "%a" Packed_refs.pp_error err
      | #error as err -> Fmt.pf ppf "%a" pp_error err
      | `Invalid_reference err ->
        Helper.ppe ~name:"`Invalid_reference" Reference.pp ppf err

    type nonrec error =
      [ Packed_refs.error
      | error
      | `Invalid_reference of Reference.t ]

    let contents top =
      let open Lwt.Infix in

      let ( >?= ) = Lwt_result.bind in

      let rec lookup acc dir =
        FileSystem.Dir.contents ~rel:true Path.(top // dir)
        >?= fun l ->
          Lwt_list.filter_p
            (fun x -> FileSystem.is_dir Path.(top // dir // x) >|= function Ok v -> v | Error _ -> false) l
          >>= fun dirs ->
          Lwt_list.filter_p
            (fun x -> FileSystem.is_file Path.(top // dir // x) >|= function Ok v -> v | Error _ -> false) l
          >>= Lwt_list.map_p (fun file -> Lwt.return (Path.append dir file)) >>= fun files ->

          Lwt_list.fold_left_s
            (function Ok acc -> fun x -> lookup acc Path.(dir // x)
                    | Error _ as e -> fun _ -> Lwt.return e)
            (Ok acc) dirs >?= fun acc -> Lwt.return (Ok (acc @ files))
      in

      lookup [] (Path.v ".")

    module Graph = Reference.Map

    module Log =
    struct
      let src = Logs.Src.create "git.store.ref" ~doc:"logs git's store reference event"
      include (val Logs.src_log src : Logs.LOG)
    end

    (* XXX(dinosaure): this function does not return any {!Error} value. *)
    let graph_p ~dtmp ~raw t =
      let open Lwt.Infix in

      contents Path.(t.dotgit / "refs") >>= function
      | Error sys_err ->
        Log.err (fun l -> l ~header:"graph_p" "Retrieve an error: %a." FileSystem.Dir.pp_error sys_err);
        Lwt.return (Error (`SystemDirectory sys_err))
      | Ok files ->
        Log.debug (fun l -> l ~header:"graph_p" "Retrieve these files: %a."
                      (Fmt.hvbox (Fmt.list Path.pp)) files);

        Lwt_list.fold_left_s
          (fun acc abs_ref ->
             (* XXX(dinosaure): we already normalize the reference (which is
                absolute). so we consider than the root as [/]. *)
             Reference.read ~root:t.dotgit (Reference.of_path abs_ref) ~dtmp ~raw
             >|= function
             | Ok v -> v :: acc
             | Error err ->
               Log.err (fun l -> l ~header:"graph_p" "Retrieve an error when we read reference %a: %a."
                           Reference.pp (Reference.of_path abs_ref)
                           Reference.pp_error err);
               acc)
          [] (Reference.(to_path head) :: files)
        >>= fun lst -> Lwt_list.fold_left_s
          (fun (rest, graph) -> function
             | refname, Reference.Hash hash ->
               Lwt.return (rest, Graph.add refname hash graph)
             | refname, Reference.Ref link ->
               Log.debug (fun l -> l ~header:"graph_p" "Putting the reference %a -> %a as a partial value."
                             Reference.pp refname Reference.pp link);
               Lwt.return ((refname, link) :: rest, graph))
          ([], Graph.empty) lst
        >>= fun (partial, graph) ->
        Packed_refs.read ~root:t.dotgit ~dtmp ~raw >>= function
        | Ok packed_refs ->
          Lwt_list.fold_left_s
            (fun graph -> function
               | `Peeled _ -> Lwt.return graph
               | `Ref (refname, hash) -> Lwt.return (Graph.add (Reference.of_string refname) hash graph))
            graph packed_refs
          >>= fun graph -> Lwt_list.fold_left_s
            (fun graph (refname, link) ->
               Log.debug (fun l -> l ~header:"graph_p" "Resolving the reference %a -> %a."
                             Reference.pp refname Reference.pp link);

               try let hash = Graph.find link graph in Lwt.return (Graph.add refname hash graph)
               with Not_found -> Lwt.return graph)
            graph partial
          >|= fun graph -> Ok graph
        | Error #Packed_refs.error ->
          Lwt_list.fold_left_s
            (fun graph (refname, link) ->
               Log.debug (fun l -> l ~header:"graph_p" "Resolving the reference %a -> %a."
                             Reference.pp refname Reference.pp link);

               try let hash = Graph.find link graph in Lwt.return (Graph.add refname hash graph)
               with Not_found -> Lwt.return graph)
            graph partial
          >|= fun graph -> Ok graph
    [@@warning "-44"]

    let graph t = graph_p t ~dtmp:t.buffer.de ~raw:t.buffer.io

    let normalize graph = function
      | Reference.Hash hash -> Lwt.return (Ok hash)
      | Reference.Ref refname ->
        try Lwt.return (Ok (Graph.find refname graph))
        with Not_found -> Lwt.return (Error (`Invalid_reference refname))

    let list_p ~dtmp ~raw t =
      let open Lwt.Infix in

      graph_p t ~dtmp ~raw >>= function
      | Ok graph ->
        Graph.fold (fun refname hash acc -> (refname, hash) :: acc) graph []
        |> List.stable_sort (fun (a, _) (b, _) -> Reference.compare a b)
        |> fun lst -> Lwt.return lst
      | Error _ -> Lwt.return []

    let list_s t = list_p t ~dtmp:t.buffer.de ~raw:t.buffer.io

    let list = list_s

    let remove_p ~dtmp ~raw ?locks t reference =
      let open Lwt.Infix in

      let lock = match locks with
        | Some locks -> Some (Lock.make locks Path.(v "global"))[@warning "-44"]
        | None -> None
      in

      Lock.with_lock lock @@ fun () ->
      (Packed_refs.read ~root:t.dotgit ~dtmp ~raw >>= function
        | Error _ -> Lwt.return None
        | Ok packed_refs ->
          Lwt_list.exists_p
            (function
              | `Peeled _ -> Lwt.return false
              | `Ref (refname, _) ->
                Lwt.return Reference.(equal (of_string refname) reference))
            packed_refs
          >>= function
          | false -> Lwt.return None
          | true ->
            Lwt_list.fold_left_s
              (fun acc -> function
                 | `Peeled hash -> Lwt.return (`Peeled hash :: acc)
                 | `Ref (refname, hash) when not Reference.(equal (of_string refname) reference) ->
                   Lwt.return (`Ref (refname, hash) :: acc)
                 | _ -> Lwt.return acc)
              [] packed_refs
            >|= fun packed_refs' -> Some packed_refs')
      >>= (function
          | None -> Lwt.return (Ok ())
          | Some packed_refs' ->
            Packed_refs.write ~root:t.dotgit ~raw packed_refs' >>= function
            | Ok () -> Lwt.return (Ok ())
            | Error (#Packed_refs.error as err) -> Lwt.return (Error (err : error)))
      >>= function
      | Error _ as err -> Lwt.return err
      | Ok () ->
        Reference.remove ~root:t.dotgit reference >>= function
        | Ok () -> Lwt.return (Ok ())
        | Error (#Reference.error as err) -> Lwt.return (Error (err : error))

    let remove_s t ?locks reference =
      remove_p t ?locks ~dtmp:t.buffer.de ~raw:t.buffer.io reference

    let remove = remove_s

    let read_p ~dtmp ~raw t reference =
      let open Lwt.Infix in

      FileSystem.is_file Path.(t.dotgit // (Reference.to_path reference)) >>= function
      | Ok true ->
        (Reference.read ~root:t.dotgit ~dtmp ~raw reference >|= function
          | Ok _ as v -> v
          | Error (#Reference.error as err) -> Error (err : error))
      | Ok false | Error _ ->
        Packed_refs.read ~root:t.dotgit ~dtmp ~raw >>= function
        | Error (#Packed_refs.error as err) -> Lwt.return (Error (err : error))
        | Ok lst ->
          Lwt.catch
            (fun () -> Lwt_list.find_s
                (function `Peeled _ -> Lwt.return false
                        | `Ref (refname, _) -> Lwt.return Reference.(equal (of_string refname) reference))
                lst >|= function `Ref (_, hash) -> Ok (reference, Reference.Hash hash)
                               | `Peeled _ -> assert false)
            (function _ -> Lwt.return (Error `Not_found))

    let read_s t reference =
      read_p t ~dtmp:t.buffer.de ~raw:t.buffer.io reference

    let read = read_s

    let write_p ?locks ~dtmp ~raw t reference value =
      let open Lwt.Infix in

      let lock = match locks with
        | Some locks -> Some (Lock.make locks Path.(v "global"))[@warning "-44"]
        | None -> None
      in

      Lock.with_lock lock @@ fun () ->
      Reference.write ~root:t.dotgit ~raw reference value >>= function
      | Error (#Reference.error as err) -> Lwt.return (Error (err : error))
      | Ok () ->
        Packed_refs.read ~root:t.dotgit ~dtmp ~raw >>= function
        | Error _ -> Lwt.return (Ok ())
        | Ok packed_refs ->
          Lwt_list.exists_s (function `Peeled _ -> Lwt.return false
                                    | `Ref (refname, _) -> Lwt.return Reference.(equal (of_string refname) reference))
            packed_refs
          >>= function
          | false -> Lwt.return (Ok ())
          | true ->
            Lwt_list.fold_left_s
              (fun acc -> function
                 | `Peeled _ as v -> Lwt.return (v :: acc)
                 | `Ref (refname, hash) when not Reference.(equal (of_string refname) reference) -> Lwt.return (`Ref (refname, hash) :: acc)
                 | _ -> Lwt.return acc)
              [] packed_refs
            >>= fun packed_refs' ->
            Packed_refs.write ~root:t.dotgit ~raw packed_refs' >>= function
            | Ok () -> Lwt.return (Ok ())
            | Error (#Packed_refs.error as err) -> Lwt.return (Error (err : error))

    let write_s t ?locks reference value =
      write_p t ?locks ~dtmp:t.buffer.de ~raw:t.buffer.io reference value

    let write = write_s

    let unpack_reference t ~dtmp ~raw ?locks reference =
      let open Lwt.Infix in

      let lock = match locks with
        | Some locks -> Some (Lock.make locks Path.(v "global"))[@warning "-44"]
        | None -> None
      in

      Lock.with_lock lock @@ fun () ->
      Packed_refs.read ~root:t.dotgit ~dtmp ~raw >>= function
      | Error _ -> Lwt.return (Ok ())
      | Ok packed_refs ->
        Lwt_list.exists_s (function
            | `Peeled _ -> Lwt.return false
            | `Ref (refname, _) -> Lwt.return Reference.(equal (of_string refname) reference))
          packed_refs >>= function
        | false -> Lwt.return (Ok ())
        | true ->
          Lwt_list.fold_left_s (fun (pi, acc) -> function
              | `Peeled hash -> Lwt.return (pi, `Peeled hash :: acc)
              | `Ref (refname, hash) when not Reference.(equal reference (of_string refname)) ->
                Lwt.return (pi, `Ref (refname, hash) :: acc)
              | `Ref (_, hash) -> Lwt.return (Some (reference, hash), acc))
            (None, []) packed_refs
          >>= function
          | None, _ -> assert false
          (* XXX(dinosaure): we prove than reference is in packed_refs, so it's
             a mandatory to return a [Some v]. *)
          | (Some (_, hash), packed_refs') -> Packed_refs.write ~root:t.dotgit ~raw packed_refs'
            >>= function
            | Error (#Packed_refs.error as err) -> Lwt.return (Error (err : error))
            | Ok () -> Reference.write ~root:t.dotgit ~raw reference (Reference.Hash hash) >|= function
              | Ok () -> Ok ()
              | Error (#Reference.error as err) -> Error (err : error)

    let test_and_set t ?locks reference ~test ~set =
      let open Lwt.Infix in

      let lock = match locks with
        | Some locks -> Some (Lock.make locks Path.(v "global"))[@warning "-44"]
        | None -> None
      in

      Lock.with_lock lock @@ fun () ->
      unpack_reference t ~dtmp:t.buffer.de ~raw:t.buffer.io reference >>= fun _ ->
      Reference.test_and_set ~root:t.dotgit reference ~test ~set >|= function
      | Error (#Reference.error as err) -> Error (err : error)
      | Ok _ as v -> v
  end

  let cache ?(indexes = 5) ?(packs = 5) ?(objects = 5) ?(values = 5) ?(revindexes = 5) () =
    { indexes    = CacheIndex.create indexes
    ; packs      = CachePack.create packs
    ; objects    = CacheObject.create objects
    ; values     = CacheValue.create values
    ; revindexes = CacheRevIndex.create revindexes }

  let buffer () =
    let raw = Cstruct.create (0x8000 * 2) in
    let buf = Bigarray.Array1.create Bigarray.Char Bigarray.c_layout (2 * 0x8000) in

    { window = Inflate.window ()
    ; zl = Cstruct.sub raw 0 0x8000
    ; de = Cstruct.of_bigarray ~off:0 ~len:0x8000 buf
    (* XXX(dinosaure): bon ici, c'est une note compliqué, j'ai mis 2
       jours à fixer le bug. Donc je l'explique en français, c'est
       plus simple.

       En gros, [Helper.MakeDecoder] utilise ce buffer comme buffer
       interne pour gérer les alterations. Ce qui ce passe, c'est que
       dans la fonction [refill], il s'agit de compléter à partir d'un
       [input] (typiquement [zl]) le buffer interne. C'est finalement
       un __mauvais__ jeu entre un [Cstruct.t] et un [Bigarray].

       Il s'agit de connaître la véritable taille du [Bigarray] et de
       rajouter avec [blit] le contenu de l'[input] si la taille du
       [Bigarray] (et pas du [Cstruct]) est suffisante.

       Avant, cette modification, [zl], [de] et [io] partagaient le
       même [Bigarray] découpé (avec [Cstruct]) en 3. Donc, dans le
       [MakeDecoder], [refill] considérait (pour des gros fichiers
       faisant plus de 0x8000 bytes) que après [de], nous avions
       encore de la place - et dans ce cas, nous avions [io].

       Ainsi, on [blit]ait [zl] dans [de+sizeof(de) == io], et
       finalement, on se retrouvait à essayer de décompresser ce que
       nous avions décompressé. (YOLO).

       Donc, on considère maintenant [de] comme un [Cstruct.t] et un
       [Bigarray] physiquement différent pour éviter ce problème.
       Cependant, il faudrait continuer à introspecter car j'ai
       l'intuition que pour un fichier plus gros que [2 * 0x8000], on
       devrait avoir un problème. Donc TODO. *)
    ; io = Cstruct.sub raw 0x8000 0x8000 }

  let sanitize_filesystem root dotgit =
    let ( >?= ) = Lwt_result.bind in

    FileSystem.Dir.create ~path:true root
    >?= fun _ -> FileSystem.Dir.create ~path:true dotgit
    >?= fun _ -> FileSystem.Dir.create ~path:true Path.(dotgit / "objects")[@warning "-44"]
    >?= fun _ -> FileSystem.Dir.create ~path:true Path.(dotgit / "objects" / "pack")[@warning "-44"]
    >?= fun _ -> FileSystem.Dir.create ~path:true Path.(dotgit / "objects" / "info")[@warning "-44"]
    >?= fun _ -> Lwt.return (Ok ())

  let create ?root ?dotgit ?(compression = 4) () =
    let open Lwt.Infix in

    let ( >>== ) v f = v >>= function
      | Ok v -> f v
      | Error _ as err -> Lwt.return err
    in

    (match root, dotgit with
     | None, _ | _, None ->
       (FileSystem.Dir.current ()
        >>= function
        | Ok current ->
          let root = Option.get ~default:current root in
          let[@warning "-44"] dotgit  = Option.get ~default:Path.(root / ".git") dotgit in

          sanitize_filesystem root dotgit
          >>== fun () -> indexes dotgit
          >>== fun engine ->
          Lwt.return (Ok { dotgit
                         ; root
                         ; compression
                         ; engine
                         ; cache = cache ()
                         ; buffer = buffer () })
        | Error sys_err -> Lwt.return (Error sys_err))
     | Some root, Some dotgit ->
       sanitize_filesystem root dotgit
       >>== fun () -> indexes dotgit
       >>== fun engine ->
       Lwt.return (Ok { dotgit
                      ; root
                      ; compression
                      ; engine
                      ; cache = cache ()
                      ; buffer = buffer () }))
    >>= function
    | Ok t -> Lwt.return (Ok t)
    | Error sys_err -> Lwt.return (Error (`SystemDirectory sys_err))

  let clear_caches ?locks t =
    let lock = match locks with
      | Some locks -> Some (Lock.make locks Path.(v "global"))[@warning "-44"]
      | None -> None
    in

    Lock.with_lock lock @@ fun () ->
    CacheIndex.drop_lru t.cache.indexes;
    CacheRevIndex.drop_lru t.cache.revindexes;
    CachePack.drop_lru t.cache.packs;
    CacheValue.drop_lru t.cache.values;
    CacheObject.drop_lru t.cache.objects;
    Lwt.return ()

  let reset ?locks t =
    let delete_files directory =
      let open Lwt_result in

      FileSystem.Dir.contents ~dotfiles:true ~rel:false directory
      >>= fun lst ->
      ok (Lwt_list.fold_left_s
            (fun acc path -> Lwt.Infix.(FileSystem.is_file path >|= function
               | Ok true -> path :: acc
               | _ -> acc))
            [] lst)
      >>= fun lst ->
      ok (Lwt_list.iter_p
            (fun path -> Lwt.Infix.(FileSystem.File.delete path >|= function
               | Ok () -> ()
               | Error _ -> ())) lst)
    in

    let lock = match locks with
      | Some locks -> Some (Lock.make locks Path.(v "global"))[@warning "-44"]
      | None -> None
    in

    let open Lwt_result in

    let ( >>! ) v f = bind_lwt_err v f in

    Lock.with_lock lock @@ fun () ->
    (FileSystem.Dir.delete ~recurse:true Path.(t.root / "objects")
     >>= fun _ -> FileSystem.Dir.create Path.(t.root / "objects")
     >>= fun _ -> FileSystem.Dir.create Path.(t.root / "objects" / "info")
     >>= fun _ -> FileSystem.Dir.create Path.(t.root / "objects" / "pack")
     >>= fun _ -> FileSystem.Dir.delete ~recurse:true Path.(t.root / "refs")
     >>= fun _ -> FileSystem.Dir.create Path.(t.root / "refs" / "heads")
     >>= fun _ -> FileSystem.Dir.create Path.(t.root / "refs" / "tags"))
    >>! (fun err -> Lwt.return (`SystemDirectory err))
    >>= fun _ -> (delete_files t.root >>! (fun err -> Lwt.return (`SystemDirectory err)))
    >>= fun _ -> Ref.write t Reference.head Reference.(Ref (of_string "refs/heads/master"))
  (* XXX(dinosaure): an empty git repository has HEAD which points
     to a non-existing refs/heads/master. *)

  let dotgit      { dotgit; _ }      = dotgit
  let root        { root; _ }        = root
  let compression { compression; _ } = compression

  let buffer_window { buffer; _ } = buffer.window
  let buffer_zl { buffer; _ } = buffer.zl
  let buffer_de { buffer; _ } = buffer.de
  let buffer_io { buffer; _ } = buffer.io
end

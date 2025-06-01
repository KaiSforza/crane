const ddhost = {
  scheme: "http",
  host: "localhost",
  port: 2375
}

export def filterRecord []: record -> record {
  transpose k v
  | where v != null
  | transpose -rid
}

export def dock [] {}

export def "dock get" [
  path: string
  params: record = {}
  --allow-errors (-e)
  --full (-f)
] {
  http get --allow-errors=$allow_errors --full=$full (
    $ddhost | merge {path: $path, params: $params} | url join
  )
}

export def "dock delete" [
  path: string
  params: record = {}
  --allow-errors (-e)
  --full (-f)
] {
  http delete --allow-errors=$allow_errors --full=$full (
    $ddhost | merge {path: $path, params: $params} | url join
  )
}

export def "dock head" [
  path: string
  params: record = {}
  #--allow-errors (-e)
  #--full (-f)
] {
  #http head --allow-errors=$allow_errors --full=$full (
  http head ($ddhost | merge {path: $path, params: $params} | url join)
}

export def "dock post" [
  path: string
  params: record = {}
  data: any = ""
  --allow-errors (-e)
  --full (-f)
  --conttype: string = "application/json"
] {
  http post --allow-errors=$allow_errors --full=$full --content-type $conttype (
    $ddhost | merge {path: $path, params: $params} | url join
  ) $data
}

export def "into safeDate" []: [
  int -> datetime
  string -> datetime
] {
  if ($in | describe) == int {
    [0 $in] | math max | into datetime
  } else {
    $in | into datetime
  }
}

export def parseImgJson [ij: any] {
  $ij
  | upsert Created {
    |s|
      if $s.Created >= 0 {
        $s.Created | into datetime --format '%s'
      } else {
        0 | into datetime
      }
    }
  | upsert Id {|s| $s.Id | split column ':' | get column2 | first}
  | into filesize SharedSize Size
  | insert UniqueSize {|s| $s.Size - $s.SharedSize}
}
export def parseContainerJson [cj] {
  $cj
  | into datetime --format '%s' Created
  | into filesize SizeRw SizeRootFs
}

export def parseVolumeJson [vj] {
  $vj
  | upsert CreatedAt { |s| $s.CreatedAt | into datetime }
}

export def parseBcacheJson [bcj] {
  $bcj
  | into filesize Size
  | into datetime CreatedAt LastUsedAt
}

export def splitBytes [
  n: int = 5 # Number of lines
  sep: string = (char newline) # What to split on
]: string -> string {
  split row $sep
  | last $n
  | each {|s| $s | str replace --regex $"^.(char nul){3}.{4}" ""}
  | str join $sep
}

export def "str shorten" [
  len: int
  cont: string = "…";
]: string -> string {
  match ($in | str length) {
    $x if $x >= $len => { ($in | str substring 0..($len - 1)) + $cont }
    _ => $in
  }
}

export def "into port" [
]: string -> record { {} }
export def "from port" [
]: record -> string {
  ""
}

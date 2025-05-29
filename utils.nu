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

use ../utils.nu *

export use info.nu
export use events.nu

export def version [] {
  let data = (
    http get ($ddhost | merge {path: "/version"} | url join)
    | into datetime BuildTime
    | reject Platform
  )
  $data
}

export def ping [] {
  http get ($ddhost | merge {path: "/_ping"} | url join)
}

export def df [
  --verbose (-v) # verbose output for parsing
] {
  let data = (
    http get ($ddhost | merge {path: "/system/df"} | url join)
    | into filesize LayersSize
    | upsert Images {
        |i| $i.Images | each {|r| parseImgJson $r}
      }
    | upsert Containers {
        |c| $c.Containers | each {|r| parseContainerJson $r}
      }
    | upsert Volumes {
        |v| $v.Volumes | each {|r| parseVolumeJson $r}
      }
    | upsert BuildCache {
        |b| $b.BuildCache | each {|r| parseBcacheJson $r}
      }
    | insert Totals {|s|
        {
          Images: ($s.Images.UniqueSize | math sum),
          Containers: ($s.Containers.SizeRw | math sum),
          Volumes : ($s.Volumes.UsageData.Size | math sum | into filesize),
          BuildCache: ($s.BuildCache.Size | math sum),
        }
      }
  )
  if $verbose {
    $data
  } else {
    $data | get Totals
  }
}

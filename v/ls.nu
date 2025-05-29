use ../utils.nu *

# List all volumes
export def main [
  --verbose (-v) # verbose output for parsing
]: nothing -> table {
  let params = {}
  let data = parseVolumeJson (
    http get ($ddhost | merge {path: "/volumes", params: $params} | url join)
    | get Volumes
  )
  if $verbose {
    return $data
  } else {
    return ($data
    | select Driver Name CreatedAt
    )
  }
}

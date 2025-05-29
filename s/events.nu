# Stream real-time events. Will block i/o until `until`.
export def main [
  --since: string = "5 minutes ago" # When to start the logs
  --until: string = "now" # Get events until this time
] {
  let utime = $until | date from-human
  let stime = $since | date from-human
  if $utime < $stime {
    error make {
      msg: $"($utime) is not after ($stime)."
    }
  }
  if $utime > (date now) {
    error make {msg: $"Refusing to block, set `--until` to a time in the past."}
  }
  let data = (
    http get --raw (
      $ddhost
      | merge {path: "/events", params: {
          since: ($stime | format date "%s")
          until: ($utime | format date "%s")
        }}
      | url join
    ) | from json -o
    | into datetime timeNano
    | upsert time {|s| $s.timeNano}
    | reject timeNano
    | move --first time from Type
  )
  $data
}

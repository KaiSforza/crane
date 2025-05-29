# Get docker info
export def main [
  #--short (-s) # Shorter response for humans
] {
  let data = (
    http get ($ddhost | merge {path: "/info"} | url join)
    | into datetime SystemTime
    | into filesize MemTotal
  )
  $data
}

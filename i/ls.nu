use ../utils.nu *

# Analogue to the docker image ls or docker images command
export def main [
  --all (-a) # List all images
  --verbose (-v) # verbose output for parsing
]: nothing -> table {
  let params = {
    all: $all,
    shared-size: true,
    digests: true,
    manifests: true
  }
  let images = parseImgJson (
    http get ($ddhost | merge {path: "/images/json", params: $params} | url join)
  )
  if $verbose {
    return $images
  } else {
    return ($images
    | upsert Id {|s| $s.Id | str substring 6..18 }
    | select RepoTags Id Created Size
    )
  }
}

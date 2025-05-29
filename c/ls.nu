use ../utils.nu *

# Analogue of `docker ps`
export def main [
  --all (-a) # List all images
  --verbose (-v) # verbose output for parsing
]: nothing -> table {
  let params = { all: $all, size: true}
  let containers = parseContainerJson (
    http get ($ddhost | merge {path: "/containers/json", params: $params} | url join)
  )
  if $verbose {
    return $containers
  } else {
    return ($containers
    | upsert Id {|s| $s.Id | str substring 0..12 }
    | upsert Names {
        |s| if ($s.Names | length) == 1 {
            $s.Names.0
        } else $s.Names
      }
    | select Id Image Command Created Status Ports Names)
  }
}

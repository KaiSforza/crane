use ../utils.nu *

# Analogue of `docker ps`
export def main [
  --all (-a) # List all images
  --verbose (-v) # verbose output for parsing
  --notrunc # Don't truncate the short output
]: nothing -> table {
  let params = { all: $all, size: true}
  let containers = parseContainerJson (
    http get ($ddhost | merge {path: "/containers/json", params: $params} | url join)
  )
  if $verbose {
    return $containers
  } else {
    return ($containers
    | upsert Id {|s| $s.Id | str substring 0..11 }
    | upsert Names {
        |s|
        let newNames = $s.Names | each {|| str trim -c '/' -l}
        if ($newNames | length) == 1 {
            $newNames.0
        } else $newNames
      }
    #| upsert Command {|s| if $notrunc {$s.Command} else {$s.Command | str shorten 16 }}
    | select Names Id Image Created State Ports Command)
  }
}

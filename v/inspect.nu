use ../utils.nu *

# Inspect an image by name or record
export def main [
  name: string | record # The image to inspect
] {
  # If we get a record, we want to just grab the 'Name' part.
  return (
    parseVolumeJson (http get ($ddhost | merge {path: $"/volumes/($name)"} | url join))
    #| upsert UsageData {|s| $s.UsageData | into filesize Size}
  )
}

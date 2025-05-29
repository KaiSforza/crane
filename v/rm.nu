use ../utils.nu *

# Delete a volume
export def main [
  name: string # The volume to delete
  --force (-f) # Force the deletion
] {
  let data = (
    http delete -e --full (
      $ddhost
      | merge {path: $"/volumes/($name)", params: {force: $force}}
      | url join
      )
    )
  match $data.status {
    404 => (error make {msg: $"Volume does not exist. Status: ($data.status)"})
    409 => (error make {msg: $"Volume is in use. Status: ($data.status)"})
    500 => (error make {msg: $"Server error. Status: ($data.status)"})
    _ => $name
  }
}

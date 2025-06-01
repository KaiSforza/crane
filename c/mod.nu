export use ls.nu
export use exec.nu
export use attach.nu
export use create.nu

use ../utils.nu *

export def main [] {
  "Check `help modules` for details."
}

def do_container [
  name: string
  query: record = {}
  --doing: string = start
]: [
nothing -> string
nothing -> table
] {
  let resp = dock post -e -f $"/containers/($name)/($doing)" $query
  match $resp.status {
    204 => $resp.body
    304 => "Nothing to do here."
    _ => (error make -u {msg: $resp.body.message})
  }
}

# Start containers
export def start [
  ...names: string # Containers to start
] { $names | par-each {|name| do_container --doing start $name } }

# Pause containers
export def pause [
  ...names: string # Containers to pause
] { $names | par-each {|name| do_container --doing pause $name } }

# Unpause a paused containers
export def unpause [
  ...names: string # Containers to unpause/resume
] { $names | par-each {|name| do_container --doing unpause $name } }

# Stop containers
export def stop [
  ...names: string # Containers to stop
  --time (-t): int # Seconds to wait before killing the container
  --signal (-s): string # What signal to send to stop the container
] {
  $names | par-each {|name|
    do_container --doing stop $name ({
      time: $time
      signal: $signal
    } | filterRecord)
  }
}

# Restart containers
export def restart [
  ...names: string # Containers to restart
  --time (-t): int # Seconds to wait before killing the containers
  --signal (-s): string # What signal to send to stop the containers
] {
  $names | par-each {|name|
    do_container --doing restart $name ({
      time: $time
      signal: $signal
    } | filterRecord)
  }
}

# Kill containers
export def kill [
  ...names: string # Containers to kill
  --signal (-s): string # What signal to send to kill the containers
] {
  $names | par-each {|name|
    do_container --doing kill $name ({
      signal: $signal
    } | filterRecord)
  }
}

# Rename containers using a record mapping
export def rename [
  ...names: record<id: string, name: string> # Record of old names to new names
] {
  $names | par-each {|_name|
    $_name
    do_container --doing rename $_name.id ({
      name: $_name.name
    } | filterRecord)
  }
}

# Wait for all listed containers to be in the specified condition
export def wait [
  ...names: string # Containers to wait for
  --condition: string = "not-running"
] {
  $names | par-each {|name|
    do_container --doing wait $name.id ({
      condition: $condition
    } | filterRecord)
  }
}

# Delete containers
export def delete [
  ...names: string
] {
  $names | par-each {|name|
    let resp = dock delete -e -f $"/containers/($name)"
    match $resp.status {
      204 => $resp.body
      304 => "Nothing to do here."
      _ => (error make -u {msg: $resp.body.message})
    }
  }
}

# Get information about paths on a container
export def ls-files [
  name: string # Container name
  ...files: string # Paths to inspect
] {
  def dock_mode [] {
    format number | get octal
  }
  $files | par-each {|file|
    try {
      dock head $"/containers/($name)/archive" {path: $file}
      | transpose -rid
      | get x-docker-container-path-stat
      | decode base64
      | decode
      | from json
      | insert path $file
      | into filesize size
      | into datetime mtime
      | upsert mode {|| dock_mode}
      | move --first path linkTarget
    }
  }
}

# Copy files to or from a container
export def copy [
  ...files: string # Files to copy
  --force (-f) # Force overwriting dirs with non-directory content
  --archive (-a) # Copy the file ownership
] {
  if ($files | length) < 2 {error make {msg: "Must have more than one file/destination listed."}}
  print $files

  if ($files | last | str contains ':') {
    # Copy to container
    let container = $files | last | split row ':'
    $files | drop | par-each {|file|
      let tarfile = (tar -cf - $file)
      tar -cf - $file
      | dock put -fe -t "application/x-tar" $"/containers/($container.0)/archive" {
        path: $container.1
        noOverwriteDirNonDir: (not $force)
        copyUIDGID: $archive
      } $in
    }
  } else {
    if ($files | last | path type) != dir {error make {msg: "Local path must be a directory."}}
    $files | drop | par-each {|file|
      let container = $file | split row ':'
      let tf = dock get -fe $"/containers/($container.0)/archive" {path: $container.1}
      match $tf.status {
        200 => ($tf.body | tar -C ($files | last) -xvf -)
        _ => (error make {msg: $tf.body})
      }
    }
  }
}


# Remove stopped images.
export def prune [
  --until: datetime # Delete containers created before this time
  --labels: list<string> # Delete containers with these labels
] {
  dock post "/containers/prune" {}
  | into filesize SpaceReclaimed
}

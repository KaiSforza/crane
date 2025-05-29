use ../utils.nu *

# Run commands on a container
export def main [
  --verbose (-v) # verbose output for parsing
  # Positional arguments
  container: string # Container name or id
  ...execCmd: string # Command to run

  # Params
  --stdin (-i) # attach stdin
  --detach (-d) # Detach from the container
  --tty (-t) # Allocate a tty
  --user (-u): string # User to run as <name|uid>[:<group|gid>]
  --envi (-e): record # Environment variables to set
  --workdir (-w): string
]: nothing -> any {
  let urlData = {
      AttachStdin: $stdin,
      AttachStdout: (not $detach),
      AttachStderr: (not $detach),
      DetachKeys: "ctrl-p,ctrl-q",
      Tty: $tty,
      Cmd: $execCmd
      Env: $envi
      WorkingDir: $workdir
    }
    | transpose k v
    | where {|i| $i.v != null}
    | transpose --ignore-titles -r -d
  let exec_instance = (
    http post --content-type application/json ($ddhost | merge {path: $"/containers/($container)/exec"} | url join) $urlData
  )

  let sData = {
    Detach: $detach,
    Tty: $tty
  }
  return (http post --raw --content-type application/json (
    $ddhost
    | merge {path: $"/exec/($exec_instance.Id)/start"}
    | url join
  ) $sData)
}

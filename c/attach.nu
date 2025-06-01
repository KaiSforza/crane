use ../utils.nu *

# Attach to the stdout of the container
#
# This does *not* allow for the user to send commands at the moment.
export def main [
  container: string # Container name or id
  #--stdin # Don't attach stdin
  --nostderr # Don't get the stderr
  --nostdout # Don't get the stdout
  #--detach-keys: string # String sequence to detach from the container
  --logs: int = 10 # Get previous logs
  #--stream # Don't stream more logs.
]: nothing -> any {
  let nttysep = $"[(char nul)-(0x[02] | decode)](char nul){3}.{4}"
  let sData = {
    stdin: false,
    stdout: (not $nostdout),
    stderr: (not $nostderr),
    logs: ($logs > 0),
    stream: false,
  }
  http post --raw (
    $ddhost
    | merge {
        path: $"/containers/($container | str trim --left --char '/')/attach",
        params: $sData,
      }
    | url join
  ) '' | splitBytes $logs (char newline)
}

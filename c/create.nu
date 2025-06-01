use ../utils.nu *

# Analogue of `docker container create`
export def main [
  image: string # Image to pull
  cmd: list = [] # Command to run on the container
  --name: string # Name of the container
  --host: string # Hostname for the container
  --domain: string = local # Domain name of the container
  --envs: list<string> # Environment variables to set
  --user: any # User/uid:[group/gid]
  --entrypoint: list<string> # Override the entrypoint
  --labels: record # Labels to apply to the container
  --volumes: record # Volumes to attach
  --workdir: string # Working directory on the container
  --nonetwork # Don't give the container any networking
  --macaddress: string # Mac address of the container
  --expose: record # Ports to expose
  --hostconfig: record # See docs for all of the settings available.
  --networkconfig: record # Configuration for the network (see docs)
]: nothing -> table {
  let params: record = ({
    Hostname: (if $host == null {$name} else $name)
    Domainname: $domain
    User: (if $user != null {$user | into string} else {null})
    AttachStdin: false
    AttachStdout: false
    AttachStderr: false
    Image: $image,
    Env: $envs
    Cmd: $cmd
    Entrypoint: $entrypoint
    Labels: $labels
    Volumes: $volumes
    WorkingDir: $workdir
    MacAddress: $macaddress
    ExposedPorts: $expose
    hostConfig: $hostconfig
    NetworkingConfig: $networkconfig
  } | filterRecord)
  let container = dock post -f -e "/containers/create" {
    name: $name
  } $params
  match $container.status {
    201 => $container.body
    _ => {error make -u {msg: $container.body.message}}
  }
}

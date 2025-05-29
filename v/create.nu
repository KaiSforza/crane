use ../utils.nu *

# Create a volume
export def main [
  name: string # The volume name
  driver: string = local # Which driver to use
  --driverOpts: record # A mapping of driver otps to use. Specific to the driver.
  --labels: record # Labels to give the volume
  --clusterVolSpec: record<Group: string, AccessMode: record> # Volume specification. See docs.
  --verbose (-v): # return more than just the volume name/id
] {
  let urlData = {
      Name: $name,
      Driver: $driver,
      DriverOpts: $driverOpts,
      Labels: $labels,
      ClusterVolumeSpec: $clusterVolSpec,
    }
    | transpose k v
    | where {|i| $i.v != null}
    | transpose --ignore-titles -r -d
  let data = http post --content-type application/json ($ddhost | merge {path: "/volumes/create"} | url join) $urlData
  if $verbose {
    return $data
  } else {
    return $data.Name
  }
}

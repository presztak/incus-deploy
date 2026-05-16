# Shared by all clusters, created once.
resource "incus_project" "this" {
  name        = "dev-incus-deploy"
  description = "Project used to test incus-deploy"
  config = {
    "features.images"          = false
    "features.networks"        = false
    "features.networks.zones"  = false
    "features.profiles"        = true
    "features.storage.buckets" = true
    "features.storage.volumes" = true
  }
}

resource "incus_network" "this" {
  project     = incus_project.this.name
  name        = "br-ovn-test"
  description = "Network used to test incus-deploy (OVN uplink)"

  config = {
    "ipv4.address" = var.ovn_uplink_ipv4_address
    "ipv4.nat"     = "true"
    "ipv6.address" = var.ovn_uplink_ipv6_address
    "ipv6.nat"     = "true"
  }
}

module "baremetal" {
  source   = "./baremetal-incus"
  for_each = var.clusters

  project_name   = incus_project.this.name
  cluster_name   = each.key
  instance_names = each.value
  image          = "images:${var.incus_image}"
  memory         = "4GiB"

  storage_pool   = var.incus_storage_pool
  network        = var.incus_network
  uplink_network = incus_network.this.name
}

resource "incus_profile" "this" {
  project     = var.project_name
  name        = var.cluster_name
  description = "Profile to be used by the cluster VMs"

  config = {
    "limits.cpu"          = "4"
    "limits.memory"       = var.memory
    "security.secureboot" = "false"
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      "pool" = var.storage_pool
      "path" = "/"
    }
  }

  device {
    type = "disk"
    name = "agent"

    properties = {
      "source" = "agent:config"
    }
  }

  device {
    type = "nic"
    name = "eth0"

    properties = {
      "network" = var.network
      "name"    = "eth0"
    }
  }

  device {
    type = "nic"
    name = "eth1"

    properties = {
      "network" = var.uplink_network
      "name"    = "eth1"
    }
  }

  device {
    type = "disk"
    name = "disk4"

    properties = {
      "pool"   = var.storage_pool
      "io.bus" = "nvme"
      "source" = incus_storage_volume.disk4.name
    }
  }
}

resource "incus_storage_volume" "disk3" {
  for_each = var.instance_names

  project      = var.project_name
  name         = "${each.value}-disk3"
  description  = "Local storage drive"
  pool         = var.storage_pool
  content_type = "block"
  config = {
    "size" = "50GiB"
  }
}

resource "incus_storage_volume" "disk4" {
  project      = var.project_name
  name         = "${var.cluster_name}-shared-disk"
  description  = "Shared block storage"
  pool         = var.storage_pool
  content_type = "block"
  config = {
    "size"            = "50GiB"
    "security.shared" = "true"
  }
}

resource "incus_instance" "instances" {
  for_each = var.instance_names

  project  = var.project_name
  name     = each.value
  type     = "virtual-machine"
  image    = var.image
  profiles = ["default", incus_profile.this.name]

  device {
    type = "disk"
    name = "disk3"

    properties = {
      "pool"   = var.storage_pool
      "io.bus" = "nvme"
      "source" = incus_storage_volume.disk3[each.key].name
    }
  }

  lifecycle {
    ignore_changes = [running]
  }
}

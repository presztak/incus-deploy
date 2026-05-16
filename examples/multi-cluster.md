# Multiple test clusters

Deploy one or more Incus test clusters (OVN + lvmcluster) as VMs on a local
Incus host, using the `Makefile` in the repository root.

All clusters share the Incus project `dev-incus-deploy` and the OVN uplink
network `br-ovn-test`. These are created with the first cluster and never
removed by the Makefile.

## Setup (once)

```sh
cd ansible
ansible-galaxy install -r ansible_requirements.yml
cp hosts.yaml.example.multicluster hosts.yaml
```

You also need `tofu` and `ansible` installed, and Incus running locally.

## Usage

```sh
make deploy                              # cluster1 (default)
make deploy CLUSTERS=cluster2            # cluster2
make deploy CLUSTERS="cluster1 cluster2" # both
make destroy CLUSTERS=cluster2           # remove cluster2 only
```

| Target      | What it does                                             |
|-------------|----------------------------------------------------------|
| `plan`      | Shows what `tofu` would change, changes nothing          |
| `infra`     | Creates the VMs and disks (`tofu apply`)                 |
| `configure` | Waits for the VMs, then runs `ansible-playbook deploy.yaml` |
| `deploy`    | `infra` followed by `configure`                          |
| `destroy`   | Deletes the selected clusters' VMs, disks and profile    |

`tofu` asks for confirmation before every apply and destroy. It also warns
that `-target` is not for routine use; that is expected here.

Run `configure` again to re-apply the Ansible configuration on a running cluster.

## Adding a cluster

Add it in two places, with the same name and VM names:

1. `terraform/variables.tf`, in `clusters`:
   ```hcl
   cluster3 = ["server21", "server22", "server23"]
   ```
2. `ansible/hosts.yaml`, as a new group with its own uplink range:
   ```yaml
   cluster3:
     vars:
       cluster_name: cluster3
       ovn_uplink_range: "172.31.254.90-172.31.254.129"
     hosts:
       server21:
       server22:
       server23:
   ```

Then run `make deploy CLUSTERS=cluster3`.

The `ovn_uplink_range` values must not overlap, because all clusters share the
`172.31.254.0/24` uplink.

## Notes

- Do not run plain `tofu destroy`: it removes every cluster plus the shared project
  and network. Plain `tofu apply` creates every cluster in `clusters`.
- OVN certificates and lvmcluster host IDs are kept per cluster in
  `ansible/data/ovn/<cluster>/` and `ansible/data/lvmcluster/<cluster>/`.
  Delete a cluster's folders only if you want fresh certificates after recreating it.

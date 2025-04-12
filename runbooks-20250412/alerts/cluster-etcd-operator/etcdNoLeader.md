# etcdNoLeader

## Meaning

This alert is triggered when etcd cluster does not have a leader for more than 1
minute.

## Impact

When there is no leader, Kubernetes and OpenShift APIs will not be able to work
as expected and cluster cannot process any writes or reads, and any write
requests are queued for processing until a new leader is elected. Operations
that preserve the health of the workloads cannot be performed.

## Diagnosis

### Control plane nodes issue

This can occur multiple control plane nodes are powered off or are unable to
connect each other via the network. Check that all control plane nodes are
powered and that network connections between each machine are functional.

### Slow disk issue

Another potential cause could be slow disk, inspect the `Disk Sync
Duration`dashboard, as well as the `Total Leader Elections Per Day` to get more
insight and help with diagnosis. Both dashboards are located in the OpenShift
console under `etcd` dashboard.

### Other

Check the logs of etcd containers to see any further information and to verify
that etcd does not have leader. Logs should contain something like `etcdserver:
no leader`. etcd containers are running in the `openshift-etcd`
namespace/project and in the `etcd` container.

## Mitigation

### Disaster and recovery

Follow the steps described in the [disaster and recovery docs][docs].


[docs]: https://docs.openshift.com/container-platform/latest/backup_and_restore/control_plane_backup_and_restore/disaster_recovery/about-disaster-recovery.html

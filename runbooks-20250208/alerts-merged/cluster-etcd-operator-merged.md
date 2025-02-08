Original Filename:  etcdDatabaseQuotaLowSpace.md

# etcdDatabaseQuotaLowSpace

## Meaning

This alert fires when the total existing DB size exceeds 95% of the maximum
DB quota. The consumed space is in Prometheus represented by the metric
`etcd_mvcc_db_total_size_in_bytes`, and the DB quota size is defined by
`etcd_server_quota_backend_bytes`.

## Impact

In case the DB size exceeds the DB quota, no writes can be performed anymore on
the etcd cluster. This further prevents any updates in the cluster, such as the
creation of pods.

## Diagnosis

The following two approaches can be used for the diagnosis.

### CLI Checks

To run `etcdctl` commands, we need to `rsh` into the `etcdctl` container of any
etcd pod.

```console
$ oc rsh -c etcdctl -n openshift-etcd $(oc get pod -l app=etcd -oname -n openshift-etcd | awk -F"/" 'NR==1{ print $2 }')
```

Validate that the `etcdctl` command is available:

```console
$ etcdctl version
```

`etcdctl` can be used to fetch the DB size of the etcd endpoints.

```console
$ etcdctl endpoint status -w table
```

### PromQL queries

Check the percentage consumption of etcd DB with the following query in the
metrics console:

```console
(etcd_mvcc_db_total_size_in_bytes / etcd_server_quota_backend_bytes) * 100
```

Check the DB size in MB that can be reduced after defragmentation:

```console
(etcd_mvcc_db_total_size_in_bytes - etcd_mvcc_db_total_size_in_use_in_bytes)/1024/1024
```

## Mitigation

### Capacity planning

If the `etcd_mvcc_db_total_size_in_bytes` shows that you are growing close to
the `etcd_server_quota_backend_bytes`, etcd almost reached max capacity and it's
start planning for new cluster.

In the meantime before migration happens, you can use defrag to gain some time.

### Defrag

When the etcd DB size increases, we can defragment existing etcd DB to optimize
DB consumption as described in [here][etcdDefragmentation]. Run the following
command in all etcd pods.

```console
$ etcdctl defrag
```

As validation, check the endpoint status of etcd members to know the reduced
size of etcd DB. Use for this purpose the same diagnostic approaches as listed
above. More space should be available now.

[etcdDefragmentation]: https://etcd.io/docs/v3.4.0/op-guide/maintenance/



------------------------------


Original Filename:  etcdGRPCRequestsSlow.md

# etcdGRPCRequestsSlow

## Meaning

This alert fires when the 99th percentile of etcd gRPC requests are too slow.

## Impact

When requests are too slow, they can lead to various scenarios like leader
election failure, slow reads and writes and general cluster instability.

## Diagnosis

This could be result of slow disk, network or CPU starvation/contention.

### Slow disk

One of the most common reasons for slow gRPC requests is disk. Checking disk
related metrics and dashboards should provide a more clear picture.

#### PromQL queries used to troubleshoot

Verify the value of how slow the etcd gRPC requests are by using the following
query in the metrics console:

```console
histogram_quantile(0.99, sum(rate(grpc_server_handling_seconds_bucket{job=~".*etcd.*", grpc_type="unary"}[5m])) without(grpc_type))
```
That result should give a rough timeline of when the issue started.

`etcd_disk_wal_fsync_duration_seconds_bucket` reports the etcd disk fsync
duration, `etcd_server_leader_changes_seen_total` reports the leader changes. To
rule out a slow disk and confirm that the disk is reasonably fast, 99th
percentile of the etcd_disk_wal_fsync_duration_seconds_bucket should be less
than 10ms. Query in metrics UI:

```console
histogram_quantile(0.99, sum by (instance, le) (irate(etcd_disk_wal_fsync_duration_seconds_bucket{job="etcd"}[5m])))
```

When txn calls are slow, another culprit can be the network roundtrip between
 the nodes. You can observe this with:

```console
histogram_quantile(0.99, sum by (instance, le) (irate(etcd_network_peer_round_trip_time_seconds_bucket{job="etcd"}[5m])))
```


You can find more performance troubleshooting tips in
 [OpenShift etcd Performance Metrics](https://github.com/openshift/cluster-etcd-operator/blob/master/docs/performance-metrics.md).

#### Console dashboards

In the OpenShift dashboard console under Observe section, select the etcd
dashboard. There are both RPC rate as well as Disk Sync Duration dashboards
which will assist with further issues.

### Resource exhaustion

It can happen that etcd responds slower due to CPU resource exhaustion.
This was seen in some cases when one application was requesting too much CPU
which led to this alert firing for multiple methods.

Often if this is the case, we also see
`etcd_disk_wal_fsync_duration_seconds_bucket` slower as well.

To confirm this is the cause of the slow requests either:

1. In OpenShift console on primary page under "Cluster utilization" view the
   requested CPU vs available.

2. PromQL query is the following to see top consumers of CPU:

```console
      topk(25, sort_desc(
        sum by (namespace) (
          (
            sum(avg_over_time(pod:container_cpu_usage:sum{container="",pod!=""}[5m])) BY (namespace, pod)
            *
            on(pod,namespace) group_left(node) (node_namespace_pod:kube_pod_info:)
          )
          *
          on(node) group_left(role) (max by (node) (kube_node_role{role=~".+"}))
        )
      ))
```

### Rogue Workloads

In some cases, we've seen non-OpenShift workload put a lot of stress on the
API server that eventually cascades into etcd. One specific instance was
listing all pods across namespaces exhausting CPU and memory on API server
and subsequently on etcd.

Please consult the audit log and see whether some service accounts make
suspicious calls, both in terms of generality (listings, many/all namespaces)
and frequency (eg listing all pods every 10s).


## Mitigation

Depending on what resource was determined to be exhausted,
you can try the following:

### CPU

Find the offending process that uses too much CPU, try to limit or
shutdown the process. If feasible on clouds,
adding more or faster CPUs may help to reduce the latency.


### Disk

Find the offending process that causes the disk performance to degrade,
this can also be a noisy neighbour process on the control plane node
(eg fluentd with logging, OVN) or etcd itself. If the culprit is determined
to etcd, try to reduce the load coming from the apiserver.
Most commonly this also happens when a cluster is scaled up with
many more nodes, so reducing the cluster scale again can help.

If feasible on clouds, upgrading your storage or instance type
can significantly increase your sequential IOPS and available bandwidth.


### Network

Ensure nothing is exhausting the network bandwidth as this causes package
loss and increases the latency. As with the previous two sections,
try to isolate the offending process and mitigate from there.
If etcd is the offender, try to reduce load/increase the available resources.




------------------------------


Original Filename:  etcdHighFsyncDurations.md

# etcdHighFsyncDurations

## Meaning

This alert fires when the 99th percentile of etcd disk fsync duration is too
high for 10 minutes.

## Impact

When this happens it can lead to various scenarios like leader election failure,
frequent leader elections, slow reads and writes.

## Diagnosis

This could be result of slow disk possibly due to fragmented state in etcd or
simply due to slow disk.

### Slow disk

Checking disk related metrics and dashboards should provide a more clear
picture.

#### PromQL queries used to troubleshoot

`etcd_disk_wal_fsync_duration_seconds_bucket` reports the etcd disk fsync
duration, `etcd_server_leader_changes_seen_total` reports the leader changes. To
rule out a slow disk and confirm that the disk is reasonably fast, 99th
percentile of the etcd_disk_wal_fsync_duration_seconds_bucket should be less
than 10ms. Query in metrics UI:

```console
histogram_quantile(0.99, sum by (instance, le) (irate(etcd_disk_wal_fsync_duration_seconds_bucket{job="etcd"}[5m])))
```

You can find more performance troubleshooting tips in
[OpenShift etcd Performance Metrics](https://github.com/openshift/cluster-etcd-operator/blob/master/docs/performance-metrics.md).

#### Console dashboards

In the OpenShift dashboard console under Observe section, select the etcd
dashboard. There are both leader elections as well as Disk Sync Duration
dashboards which will assit with further issues.

## Mitigation

### Fragmented state

In the case of slow fisk or when the etcd DB size increases, we can defragment
existing etcd DB to optimize DB consumption as described in
[here][etcdDefragmentation]. Run the following command in all etcd pods.

```console
$ etcdctl defrag
```

As validation, check the endpoint status of etcd members to know the reduced
size of etcd DB. Use for this purpose the same diagnostic approaches as listed
above. More space should be available now.

Further info on etcd best practices can be found in the [OpenShift docs
here][etcdPractices].

[etcdDefragmentation]: https://etcd.io/docs/v3.4.0/op-guide/maintenance/
[etcdPractices]: https://docs.openshift.com/container-platform/4.13/scalability_and_performance/recommended-performance-scale-practices/recommended-etcd-practices.html



------------------------------


Original Filename:  etcdHighNumberOfFailedGRPCRequests.md

# etcdHighNumberOfFailedGRPCRequests

## Meaning

This alert fires when at least 50% of etcd gRPC requests failed in the past 10
minutes and sends a warning at 10%.

## Impact

First establish which gRPC method is failing, this will be visible in the alert.
If it's not part of the alert, the following query will display method and etcd
instance that has failing requests:

```sh
(sum(rate(grpc_server_handled_total{job="etcd", grpc_code=~"Unknown|FailedPrecondition|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded"}[5m])) without (grpc_type, grpc_code)
    /
(sum(rate(grpc_server_handled_total{job="etcd"}[5m])) without (grpc_type, grpc_code)
    > 2 and on ()(sum(cluster_infrastructure_provider{type!~"ipi|BareMetal"} == bool 1)))) * 100 > 10
```

## Diagnosis

All the gRPC errors should also be logged in each respective etcd instance logs.
You can get the instance name from the alert that is firing or by running the
query detailed above. Those etcd instance logs should serve as further insight
into what is wrong.

To get logs of etcd containers either check the instance from the alert and
check logs directly or run the following:

```sh
oc logs -n openshift-etcd -lapp=etcd -c etcd
```

### Defrag method errors

If defrag method is failing, this could be due to defrag that is periodically
performed by cluster-etcd-operator pe starting from OpenShift v4.9 onwards. To
verify this check the logs of cluster-etcd-operator.

```sh
oc logs -l app=etcd-operator -n openshift-etcd-operator --tail=-1
```

If you have run defrag manually on older OpenShift versions check the errors of
those manual runs.

### MemberList method errors

Member list is most likely performed by cluster-etcd-operator, so it's also best
to check also logs of cluster-etcd-operator for any errors:

```sh
oc logs -l app=etcd-operator -n openshift-etcd-operator --tail=-1
```

## Mitigation

Depending on the above diagnosis, the issue will most likely be described in the
error log line of either etcd or openshift-etcd-operator. Most likely causes
tend to be networking issues.



------------------------------


Original Filename:  etcdInsufficientMembers.md

# etcdInsufficientMembers

## Meaning

This alert fires when there are fewer instances available than are needed by
etcd to be healthy.

## Impact

When etcd does not have a majority of instances available the Kubernetes and
OpenShift APIs will reject read and write requests and operations that preserve
the health of workloads cannot be performed.

## Diagnosis

This can occur multiple control plane nodes are powered off or are unable to
connect each other via the network. Check that all control plane nodes are
powered and that network connections between each machine are functional.

Check any other critical, warning or info alerts firing that can assist with the
diagnosis.

Login to the cluster. Check health of master nodes if any of them is in
`NotReady` state or not.

```console
$ oc get nodes -l node-role.kubernetes.io/master=
```

Check if an upgrade is in progress.

```console
$ oc adm upgrade
```

In case there is no upgrade going on, but there is a change in the
`machineconfig` for the master pool causing a rolling reboot of each master
node, this alert can be triggered as well. We can check if the
`machineconfiguration.openshift.io/state : Working` annotation is set for any of
the master nodes. This is the case when the [machine-config-operator
(MCO)](https://github.com/openshift/machine-config-operator) is working on it.

```console
$ oc get nodes -l node-role.kubernetes.io/master= -o template --template='{{range .items}}{{"===> node:> "}}{{.metadata.name}}{{"\n"}}{{range $k, $v := .metadata.annotations}}{{println $k ":" $v}}{{end}}{{"\n"}}{{end}}'
```

### General etcd health

To run `etcdctl` commands, we need to `rsh` into the `etcdctl` container of any
etcd pod.

```console
$ oc rsh -c etcdctl -n openshift-etcd $(oc get pod -l app=etcd -oname -n openshift-etcd | awk -F"/" 'NR==1{ print $2 }')
```

Validate that the `etcdctl` command is available:

```console
$ etcdctl version
```

Run the following command to get the health of etcd:

```console
$ etcdctl endpoint health -w table
```
## Mitigation

### Disaster and recovery

If an upgrade is in progress, the alert may automatically resolve in some time
when the master node comes up again. If MCO is not working on the master node,
check the cloud provider to verify if the master node instances are running or not.

In the case when you are running on AWS, the AWS instance retirement might need
a manual reboot of the master node.

As a last resort if none of the above fix the issue and the alert is still
firing, for etcd specific issues follow the steps described in the [disaster and
recovery docs][docs].

[docs]: https://docs.openshift.com/container-platform/latest/backup_and_restore/control_plane_backup_and_restore/disaster_recovery/about-disaster-recovery.html



------------------------------


Original Filename:  etcdMembersDown.md

# etcdMembersDown

## Meaning

This alert fires when one or more etcd member goes down and evaluates the
number of etcd members that are currently down. Often, this alert was observed
as part of a cluster upgrade when a master node is being upgraded and requires a
reboot.

## Impact

In etcd a majority of (n/2)+1 has to agree on membership changes or key-value
upgrade proposals. With this approach, a split-brain inconsistency can be
avoided. In the case that only one member is down in a 3-member cluster, it
still can make forward progress. Due to the fact that the quorum is 2 and 2
members are still alive. However, when more members are down, the cluster
becomes unrecoverable.

## Diagnosis

Login to the cluster. Check health of master nodes if any of them is in
`NotReady` state or not.

```console
$ oc get nodes -l node-role.kubernetes.io/master=
```

Check if an upgrade is in progress.

```console
$ oc adm upgrade
```

In case there is no upgrade going on, but there is a change in the
`machineconfig` for the master pool causing a rolling reboot of each master
node, this alert can be triggered as well. We can check if the
`machineconfiguration.openshift.io/state : Working` annotation is set for any of
the master nodes. This is the case when the [machine-config-operator
(MCO)](https://github.com/openshift/machine-config-operator) is working on it.

```console
$ oc get nodes -l node-role.kubernetes.io/master= -o template --template='{{range .items}}{{"===> node:> "}}{{.metadata.name}}{{"\n"}}{{range $k, $v := .metadata.annotations}}{{println $k ":" $v}}{{end}}{{"\n"}}{{end}}'
```

### General etcd health

To run `etcdctl` commands, we need to `rsh` into the `etcdctl` container of any
etcd pod.

```console
$ oc rsh -c etcdctl -n openshift-etcd $(oc get pod -l app=etcd -oname -n openshift-etcd | awk -F"/" 'NR==1{ print $2 }')
```

Validate that the `etcdctl` command is available:

```console
$ etcdctl version
```

Run the following command to get the health of etcd:

```console
$ etcdctl endpoint health -w table
```

## Mitigation

If an upgrade is in progress, the alert may automatically resolve in some time
when the master node comes up again. If MCO is not working on the master node,
check the cloud provider to verify if the master node instances are running or not.

In the case when you are running on AWS, the AWS instance retirement might need
a manual reboot of the master node.




------------------------------


Original Filename:  etcdNoLeader.md

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



------------------------------


Original Filename:  etcdSignerCAExpirationCritical.md

# etcdSignerCAExpirationCritical

## Meaning

This alert fires when the signer CA certificate of etcd (metrics or server)
is having one year left before expiration.

## Impact

When the etcd server signer certificate expires, your cluster will become
unavailable and very hard to recover.
If the metrics signer certificate expires, you will lose metrics and alerts
for etcd.

## Mitigation

Please follow the [OpenShift documentation here][manualRota] on how to manually
 rotate the signer certificates.

[manualRota]: https://docs.openshift.com/container-platform/4.16/security/certificate_types_descriptions/etcd-certificates.html




------------------------------



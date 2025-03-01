Original Filename:  CephClusterCriticallyFull.md

# CephClusterCriticallyFull

## Meaning

Storage cluster is critically full and needs immediate data deletion or cluster
expansion. The alert will be fired when storage cluster utilization has crossed
 80%

## Impact

Storage cluster will become read-only at 85%.

## Diagnosis

Using the Openshift console, go to Storage-Data Fountation-Storage systems.
A list of the available storage systems with basic information about raw
capacity and used capacity will be visible.
The command "ceph health" provides also information about cluster storage
capacity.

## Mitigation

Two options:

- Scale storage: Depending on the type of cluster it will be needed to add
storage devices and/or nodes. Review the Openshift Scaling storage
documentation.

- Delete information:
If not is possible to scale up the cluster it will be needed to delete
information in order to free space.



------------------------------


Original Filename:  CephClusterErrorState.md

# CephClusterErrorState

## Meaning

Storage cluster is in error state for more than 10m.
This alert reflects that the storage cluster is in *ERROR* state for an
unacceptable amount of time and this impacts the storage availability.
Check for other alerts that would have triggered prior to this one and
troubleshoot those alerts first.

## Impact

Cluster services not available.

## Diagnosis

See [general diagnosis document](helpers/diagnosis.md)

## Mitigation

### Check if it is a Network Issue

Check if it is a [network issue](helpers/networkConnectivity.md)

### Make changes to solve alert

General troubleshooting will be required in order to determine the cause of this
 alert. This alert will trigger along with other (usually many other) alerts.
Please view and troubleshoot the other alerts first.

### Review pods

[pod debug](helpers/podDebug.md)

If the basic health of the running pods, node affinity and resource availability
on the nodes have been verified, run Ceph tools for status of the storage
components.

#### Troubleshoot Ceph

[Troubleshoot_ceph_err](helpers/troubleshootCeph.md) and
[gather_logs](helpers/gatherLogs.md) to provide more information to support
teams.



------------------------------


Original Filename:  CephClusterNearFull.md

# CephClusterNearFull

## Meaning

Storage cluster utilization has crossed 75% and will become read-only at 85%.
Free up some space or expand the storage cluster.

## Impact

Storage cluster will become read-only at 85%.

## Diagnosis

Using the Openshift console, go to Storage-Data Fountation-Storage systems.
A list of the available storage systems with basic information about raw
capacity and used capacity will be visible.
The command "ceph health" provides also information about cluster storage
capacity.

## Mitigation

Two options:

- Scale storage: Depending on the type of cluster it will be needed to add
storage devices and/or nodes. Review the Openshift Scaling storage
documentation.

- Delete information:
If not is possible to scale up the cluster it will be needed to delete
information in order to free space.



------------------------------


Original Filename:  CephClusterReadOnly.md

# CephClusterReadOnly

## Meaning

Storage cluster utilization has crossed 85% and will become read-only now.

## Impact

Storage cluster is read-only now and needs immediate data deletion or
 cluster expansion.

Storage cluster will become read-only at 85%.

## Diagnosis

Using the Openshift console, go to Storage-Data Fountation-Storage systems.
A list of the available storage systems with basic information about raw
capacity and used capacity will be visible.
The command "ceph health" provides also information about cluster storage
capacity.

## Mitigation

Free up some space or expand the storage cluster immediately.

Two options:

- Scale storage: Depending on the type of cluster it will be needed to add
storage devices and/or nodes. Review the Openshift Scaling storage
documentation.

- Delete information:
If not is possible to scale up the cluster it will be needed to delete
information in order to free space.



------------------------------


Original Filename:  CephClusterWarningState.md

# CephClusterWarningState

## Meaning

Storage cluster is in warning state for more than 15m.

The Storage cluster has been in a warning state for an unacceptable amount of
time. While the storage operations will continue to function in this state, it
is recommended to fix errors so that the cluster does not get into error state
impacting operations. Check for other alerts that would have triggered prior
to this one and troubleshoot those alerts first.

## Impact

Cluster services not available. Errors in operations retrieving/putting
information in the cluster

## Diagnosis

See [general diagnosis document](helpers/diagnosis.md)

## Mitigation

### Check if it is a Network Issue

Check if it is a [network issue](helpers/networkConnectivity.md)

### Make changes to solve alert

General troubleshooting will be required in order to determine the cause of this
 alert. This alert will trigger along with other (usually many other) alerts.
Please view and troubleshoot the other alerts first.

### Review pods

[pod debug](helpers/podDebug.md)

If the basic health of the running pods, node affinity and resource availability
on the nodes have been verified, run Ceph tools for status of the storage
components.

#### Troubleshoot Ceph

[Troubleshoot_ceph_err](helpers/troubleshootCeph.md) and
[gather_logs](helpers/gatherLogs.md) to provide more information to support
teams.



------------------------------


Original Filename:  CephDataRecoveryTakingTooLong.md

# CephDataRecoveryTakingTooLong

## Meaning

Data recovery processes in Ceph are taking an extended amount of time,
indicating potential issues with the recovery speed.

## Impact

**Severity:** Warning
**Potential Customer Impact:** High

This alert indicates that the ongoing data recovery in Ceph is progressing
slower than expected, which may have a significant impact on system performance.

## Diagnosis

The alert is triggered when the data recovery process in Ceph is identified as
taking too long. It is recommended to check the status of all OSDs to ensure
they are up and running, as slow recovery may be related to OSD issues.

**Prerequisites:** [Prerequisites](helpers/diagnosis.md)

## Mitigation

### Recommended Actions

1. **Check for Network Issues:**
   Verify if the extended data recovery time is due to network issues by
   following the steps in the provided Standard Operating Procedure (SOP) -
   [Check Ceph Network Connectivity SOP](helpers/networkConnectivity.md).

2. **Generic Debugging:**
   Follow the general pod debug workflow outlined below to identify and
   address potential issues.

   - [Pod Debug Workflow](helpers/podDebug.md)
   - [Gather Logs](helpers/gatherLogs.md)

3. **Investigate Disk Utilization:** Check for high disk utilization (near 100%)
   during rebalancing or client I/O using tools like dstat. Assess if IOPS
   limitations on disks contribute to slow recovery.

4. **Object Count Impact:** Due to a higher object count (310 million),
   replication efforts are extensive, impacting recovery time. Consider
   adjusting parameters like "osd max push objects" to potentially accelerate
   the process.

**Additional Resources:**

- [Troubleshooting](helpers/troubleshootCeph.md)



------------------------------


Original Filename:  CephMdsCPUUsageHighNeedsHorizontalScaling.md

# MDSCpuUsageHighNeedsHorizontalScaling

## Meaning

Ceph MDS CPU usage for the MDS daemon has exceeded the threshold for adequate
performance.

## Impact

MDS serves filesystem metadata. The MDS is crucial for any file creation,
rename, deletion and update operations.
MDS is by default is allocated 2 or 3 CPUS.
It is okay as long as metadata operations are not too many.
As metadata server get loaded due to high number of requests to the server,
the metadata operation load increases and eventually triggers this alert.
It means we need to scale horizontally by adding more metadata servers.
This will help parallely serve the client requests much efficiently without
overwhelming any single MDS pod.

## Diagnosis

To diagnose the alert, click on the workloads->pods and select the
corresponding MDS pod and click on the metrics tab.
You should be able to see the allocated and used CPU. By default,
the alert is fired if the used CPU is 67% of allocated CPU and there
is high rate of mds requests for past 6 hours.
If this is the case take the steps mentioned in mitigation.

## Mitigation

In this case, we need to add more active metadata servers. The below
command describes how to add multiple active MDS servers,

```bash
oc patch -n openshift-storage storagecluster ocs-storagecluster\
    --type merge \
    --patch '{"spec": {"managedResources": {"cephFilesystems":{"activeMetadataServers": 2}}}}'
```
PS: Make sure we have enough CPU provisioned for MDS depending on the load.

Always increase the `activeMetadataServers` by 1 and analyze the load.
The scaling of activeMetadataServers work only if you have more than one PV.
If there is only one PV that is causing CPU load, look at increasing the
CPU resource as described in
[VerticalScaling](CephMdsCPUUsageHighNeedsVerticalScaling.md) file



------------------------------


Original Filename:  CephMdsCPUUsageHighNeedsVerticalScaling.md

# MDSCpuUsageHighNeedsVerticalScaling

## Meaning

Ceph MDS CPU usage for the MDS daemon has exceeded the threshold for adequate
performance.

## Impact

MDS serves filesystem metadata. The MDS is crucial for any file creation,
rename, deletion and update operations.
MDS is by default is allocated 2 or 3 CPUS.
It is okay as long as metadata operations are not too many.
When the metadata operation load increases enough to trigger this alert,
it means the default CPU allocation is unable to cope with load.
We need to do a vertical scaling by increasing the number of CPU allocation
on the same pod.

## Diagnosis

To diagnose the alert, click on the workloads->pods and select the
corresponding MDS pod and click on the metrics tab.
You should be able to see the allocated and used CPU. By default,
the alert is fired if the used CPU is 67% of allocated CPU for 6 hours.
If this is the case take the steps mentioned in mitigation.

## Mitigation

We need to increase the number of CPUs allocated. The below command
describes how to set the number of allocated CPU for MDS server.

```bash
oc patch -n openshift-storage storagecluster ocs-storagecluster \
    --type merge \
    --patch '{"spec": {"resources": {"mds": {"limits": {"cpu": "8"},
    "requests": {"cpu": "8"}}}}}'
```
Above is a sample patch command, user need to see their current CPU
configurations and increase accordingly
PS: It is always adviced to add another MDS pod (that is to scale
Horizontally) once we have reached the max resource limit. Please see
[HorizontalScaling](CephMdsCPUUsageHighNeedsHorizontalScaling.md)
documentation for more details.




------------------------------


Original Filename:  CephMdsCacheUsageHigh.md

# MDSCacheUsageHigh

## Meaning

Ceph MDS cache usage for the MDS daemon has exceeded above 95% of the `mds_cache_memory_limit`.

## Impact

If the MDS cannot keep its cache usage under the target threshold, that is,
`mds_health_cache_threshold` (150%) of the cache limit, that is,
`mds_cache_memory_limit`, the MDS will send a health alert to the Monitors
indicating the cache is too large.

As a result the MDS related operations, like, caps revocation, will become slow.

## Diagnosis

Check the usage of `ceph_mds_mem_rss` metric and ensure that it is under 95% of the
cache limit set in `mds_cache_memory_limit`.

The MDS tries to stay under a reservation of the `mds_cache_memory_limit` by
trimming unused metadata in its cache and recalling cached items in the client
caches. It is possible for the MDS to exceed this limit due to slow recall from
clients as result of multiple clients accesing the files.

Read more about ceph MDS cache configuration [here](https://docs.ceph.com/en/latest/cephfs/cache-configuration/?highlight=mds%20cache%20configuration#mds-cache-configuration)

## Mitigation

Make sure we have enough memory provisioned for MDS cache.

Memory resources for the MDS pods should be updated in the ocs-storageCluster in
order to increase the `mds_cache_memory_limit`. For example, run the following command
to set the memory of MDS pods to 8GB

```bash
oc patch -n openshift-storage storagecluster ocs-storagecluster \
    --type merge \
    --patch '{"spec": {"resources": {"mds": {"limits": {"memory": "8Gi"},"requests": {"memory": "8Gi"}}}}}' 
```

**Note**: ODF sets `mds_cache_memory_limit` to half of the MDS pod memory request/limit.
So if the memory is set to 8GB using above command, then the operator will set the
mds cache memory limit to 4GB



------------------------------


Original Filename:  CephMdsCpuUsageHigh.md

# MDSCpuUsageHigh

## Meaning

Ceph MDS cpu usage for the MDS daemon has exceeded the threshold for adequate
performance.

## Impact

MDS serves filesystem metadata. The MDS is crucial for any file creation,
rename, deletion and update operations.
MDS is by default is allocated 2 or 3 CPUS.
It is okay as long as metadata operations are not too many.
When the metadata operation load increases enough to trigger this alert,
it means the default CPU allocation is unable to cope with load and we need to
increase the CPU allocation or run multiple active metadata servers.

## Diagnosis

To diagnose the alert, click on the workloads->pods and select the
corresponding MDS pod and click on the metrics tab.
You should be able to see the allocated and used CPU. By default,
the alert is fired if the used CPU is 67% of allocated CPU for 6 hours.
If this is the case take the steps mentioned in mitigation.

## Mitigation

We need to either increase the allocated CPU or run multiple active MDS. The
below command describes how to set the number of allocated CPU for MDS server.

```bash
oc patch -n openshift-storage storagecluster ocs-storagecluster \
    --type merge \
    --patch '{"spec": {"resources": {"mds": {"limits": {"cpu": "8"},
    "requests": {"cpu": "8"}}}}}'
```

In order to run multiple active MDS servers, use below command

```bash
oc patch -n openshift-storage storagecluster ocs-storagecluster\
    --type merge \
    --patch '{"spec": {"managedResources": {"cephFilesystems":{"activeMetadataServers": 2}}}}'

Make sure we have enough CPU provisioned for MDS depending on the load.
```

Always increase the `activeMetadataServers` by 1.
The scaling of activeMetadataServers works only if you have more than one PV.
If there is only one PV that is causing CPU load,
look at increasing the cpu resource as described above.



------------------------------


Original Filename:  CephMdsMissingReplicas.md

# CephMdsMissingReplicas

## Meaning

Minimum required replicas for the storage metadata service (MDS) are not available.
This might affect the working of storage cluster.

## Impact

MDS is responsible for file metadata. Degradation of the MDS service can affect the
working of the storage cluster (related to cephfs storage class) and should be fixed
as soon as possible.

## Diagnosis

Make sure we have enough RAM provisioned for MDS Cache. Default is 4GB, but recomended
is minimum 8GB.

## Mitigation

It is highly recomended to distribute MDS daemons across at least two nodes in
the cluster. Otherwise, a hardware failure on a single node may result in the
file system becoming unavailable.




------------------------------


Original Filename:  CephMgrIsAbsent.md

# CephMgrIsAbsent

## Meaning

Ceph Manager cannot be found or accessed from Prometheus target discovery.

## Impact

Storage metrics collector won't be available and users won't be able to see
the storage metrics anymore. Not having a Ceph manager running impacts the
monitoring of the cluster, PVC creation and deletion requests and should be
resolved as soon as possible. Impact is critical here.

## Diagnosis

### Check if it is a network issue
Check the [network connectivity](helpers/networkConnectivity.md).
We cannot do much about the possible causes of network issues
e.g. misconfigured AWS security group.
Therefore, if it is a network issue, escalate to the ODF team by following
the steps [here](helpers/sre-to-engineering-escalation.md#procedure).

## Mitigation

Verify the rook-ceph-mgr pod is failing and restart if necessary.
If the ceph mgr pod restart fails, use general basic pod troubleshooting to resolve.

Verify the ceph mgr pod is failing:

    oc get pods -n openshift-storage | grep mgr

Describe the ceph mgr pod for more detail:

    oc describe -n openshift-storage pods/<rook-ceph-mgr pod name from previous step>

Analyze errors (i.e. resource issues?)

Try deleting the pod and watch for a successful restart:

    oc get pods -n openshift-storage | grep mgr

If above fails, follow general pod troubleshooting procedures.

[pod debug](helpers/podDebug.md) [gather_logs](helpers/gatherLogs.md)




------------------------------


Original Filename:  CephMgrIsMissingReplicas.md

# CephMgrIsMissingReplicas

## Meaning

Ceph Manager is missing replicas. That means Storage metrics collector
service doesn't have required no of replicas.

## Impact

This impacts the health status reporting and will cause some of the information
reported by `ceph status` to be missing or stale. In addition, the ceph manager
is responsible for a Manager framework aimed at expanding the Ceph existing capabilities.

## Diagnosis

To resolve this alert, you will need to determine the cause of the disappearance
of the Ceph Manager through the logs and restart if necessary.

## Mitigation

Check the manager pod's logs. Verify the rook-ceph-mgr pod is failing and restart
if necessary. If the ceph mgr pod restart fails, use general basic pod troubleshooting
to resolve.

[pod debug](helpers/podDebug.md) [gather_logs](helpers/gatherLogs.md)




------------------------------


Original Filename:  CephMonHighNumberOfLeaderChanges.md

# CephMonHighNumberOfLeaderChanges

## Meaning

In a Ceph cluster there is a redundant set of monitors that store critical
information about the storage cluster. Monitors synchronize periodically to
obtain information about the storage cluster. The first monitor to get the
most updated information become leader and other monitors will start their
synchronization process asking the leader.

This alert indicates a high frequent Ceph Monitor leader change per minute.

## Impact

An unusual change of leader is usually produced by problems in network
connection, or another kind of problem in one or more monitor pods.
This situation can affect negatively to the storage cluster performance.

## Diagnosis

The alert should indicate the monitor pod with the problem:

    Ceph Monitor <rook-ceph-mon-X... pod> on host <hostX> has seen <X> leader
    changes per minute recently.

Check the affected monitor's logs. More information on the cause can be seen
from these logs.

## Mitigation

[pod debug](helpers/podDebug.md) [gather_logs](helpers/gatherLogs.md)




------------------------------


Original Filename:  CephMonLowNumber.md

# CephMonLowNumber

## Meaning

The number of ceph monitors in the cluster can be adjusted to improve cluster
resiliency.
Typically the number of failure zones in the cluster is 5 or more, and there
are only 3 monitors.

## Impact

This a "info" level alert, and therefore just a suggestion.
The alert is just suggesting to increase the number of ceph monitors, to be
more resistent to failures.
It can be silenced without any impact in the cluster functionality or
performance.
If the number of monitors is increased to 5, the cluster will be more robust.

## Diagnosis

Check the number of Ceph Monitors:

```bash
    oc get pods -l app=rook-ceph-mon --no-headers=true -n openshift-storage | wc -l
```

Check the number of failure zones available:

```bash
    oc get storagecluster -o jsonpath='{.items[*].status.failureDomainValues}' -n openshift-storage | tr ',' '\n' | sort -u | wc -l
```

It the number of available failure zones is greater or equal to 5, and there
are only 3 monitors, the alert will be raised.

## Mitigation

If increasing the number of monitors to 5 is not a right option (for any cause),
the alert can be silenced.

If to increase the number of monitors is an acceptable proposal, then execute
the following command to do that:

```bash
    oc patch storageclusters.ocs.openshift.io ocs-storagecluster -n openshift-storage --type merge --patch '{"spec": {"managedResources": {"cephCluster": {"monCount" : 5}}}}'
```

After scaling the deployment, monitor the creation and readiness of new monitor
 pods using:

```bash
    oc get pods -n openshift-storage -l app=rook-ceph-mon
```



------------------------------


Original Filename:  CephMonQuorumAtRisk.md

# CephMonQuorumAtRisk

## Meaning

Storage cluster quorum is low.
Multiple mons work together to provide redundancy by each keeping a copy
of the metadata. Cluster is deployed with 3 or 5 mons, and require 2 or more mons
to be up and running for quorum and for the storage operations to run.

## Impact

If quorum is lost, access to data is at risk.

## Diagnosis

Run following command for each Monitor in the cluster.
`ceph tell mon.ID mon_status`

For more on this command’s output, see [Understanding mon_status](https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-mon/#rados-troubleshoting-troubleshooting-mon-understanding-mon-status).

## Mitigation

[Restore Ceph Mon Quorum Lost](https://access.redhat.com/solutions/5898541)
[Troubleshooting Monitor](https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-mon/)




------------------------------


Original Filename:  CephMonQuorumLost.md

# CephMonQuorumLost

## Meaning

The number of monitors in the storage cluster are not enough.
Multiple mons work together to provide redundancy by each keeping a copy
of the metadata. Cluster is deployed with 3 or 5 mons, and require 2 or more mons
to be up and running for quorum and for the storage operations to run.

This alert indicates that there is only 1 monitor pod running or even none.

## Impact

If quorum is lost and it is beyond recovery now. Any data lose is permanent
at this point.

## Diagnosis

Set logging to files true,
`# ceph config set global log_to_file true`
`# ceph config set global mon_cluster_log_to_file true`
Then check the corresponding Ceph Monitor logs in /var/log/ceph/<cluster-id> location

## Mitigation

[Restore Ceph Mon Quorum Lost](https://access.redhat.com/solutions/5898541)
[Troubleshooting Monitor](https://docs.ceph.com/en/latest/rados/troubleshooting/troubleshooting-mon/)





------------------------------


Original Filename:  CephMonVersionMismatch.md

# CephMonVersionMismatch

## Meaning

There are different versions of Ceph Mon components running.. Typically this
alert is triggered during an upgrade that is taking a long time.

## Impact

It will impact cluster availability if the number of monitors are not enough
 to get quorum. Cluster operations will be blocked until quorum will be
 established again

## Diagnosis

Verify Ceph version in Mon Pods:

```console
    oc describe pods -n openshift-storage --selector app=rook-ceph-mon | grep CONTAINER_IMAGE
```

All the pods must have the same image

## Mitigation

Usually the problem is solved (all Monitor daemons running same Ceph version)
when the upgrade has finished.

If the alert persists after upgrade:

Verify the connectivity between monitors is working properly, verifying
[network connectivity](helpers/networkConnectivity.md)

Verify the ODF operator events and logs in order to find an error and an
explanation about the problem updating the OSD daemon with different version.

```bash
    ocs_operator=$(oc describe deployment -n openshift-storage ocs-operator | grep OPERATOR_CONDITION_NAME: | awk '{ print $2 }')
    oc get events --field-selector involvedObject.name=$ocs_operator --namespace openshift-storage
```

```bash
    oc logs -n openshift-storage --selector name=ocs-operator -c ocs-operator
```

If nothing found, verify the
[ODF operator state](helpers/checkOperator.md)

If the ODF operator does not present any problem,
see [general diagnosis document](helpers/diagnosis.md)

If no issues found, [gather_logs](helpers/gatherLogs.md) to provide more
information to support teams.



------------------------------


Original Filename:  CephNodeDown.md

# CephNodeDown

## Meaning

This alert indicates that one of the Ceph storage node went down.

## Impact

A node running Ceph pods is down. While storage operations will continue to
function as Ceph is designed to deal with a node failure, it is recommended
to resolve the issue to minimise risk of another node going down and affecting
storage functions.

## Diagnosis

The alert message will clearly indicate which node is down

    Storage node <nod-name> went down. Please check the node immediately.

## Mitigation

Document the current OCS pods (running and failing):

    oc -n openshift-storage get pods

The OCS resource requirements must be met in order for the osd pods to be
scheduled on the new node. This may take a few minutes as the ceph cluster
recovers data for the failing but now recovering osd.

To watch this recovery in action ensure the osd pods were actually placed on the
new worker node.

Check if the previous failing osd pods are now running:

    oc -n openshift-storage get pods

If the previously failing osd pods have not been scheduled, use describe and
check events for reasons the pods were not rescheduled.

Describe events for failing osd pod:

    oc -n openshift-storage get pods | grep osd

Find a failing osd pod(s):

    oc -n openshift-storage describe pods/<osd podname from previous step>

In the event section look for failure reasons, such as resources not being met.

In addition, you may use the rook-ceph-toolbox to watch the recovery. This step
is optional but can be helpful for large Ceph clusters.

**Determine failed OCS Node** [determine_failed_ocs_node](helpers/determineFailedOcsNode.md)

[access toolbox](helpers/accessToolbox.md)

From the rsh command prompt, run the following and watch for "recovery" under
the io section:

    ceph status

[gather logs](helpers/gatherLogs.md)




------------------------------


Original Filename:  CephOSDCriticallyFull.md

# CephOSDCriticallyFull

## Meaning

Utilization of back-end storage device (OSD) has crossed 80%.
Immediately free up some space or expand the storage cluster or contact support.

## Impact

One of the OSD Storage size has crossed 80% of the total capacity. Expand the
cluster immediately.

## Diagnosis

Alert message will have enough information about the underlying failure.
It should show the name of 'ceph-daemon', 'device-class' and the 'host-name'.

A sample alert message is provided below,

    Utilization of storage device <ceph-daemon-name> of device_class type
<device-class-name> has crossed 80% on host <host-name>. Immediately free up
some space or add capacity of type <device-class>.

## Mitigation

### Delete data

The customer may delete data and the cluster will resolve the alert through self
healing processes.

### Expand the storage capacity

Customer may assess their ability to expand. Here are some points,

**Current Storage Size < 1TB**:  
The customer may increase capacity via the addon and the cluster will resolve
the alert through self healing processes.

**Current Size itself is 1TB**:
Please contact your dedicated customer care support.

[gather_logs](helpers/gatherLogs.md)




------------------------------


Original Filename:  CephOSDDiskNotResponding.md

# CephOSDDiskNotResponding

## Meaning

A disk device on one of the hosts is not responding, potentially impacting the
performance and availability of the OSD.

## Impact

**Severity:** Error
**Potential Customer Impact:** Medium

This alert signals that a disk device is not responding on a host, and it may
affect the proper functioning of the associated OSD (Object Storage Daemon).

## Diagnosis

The alert is raised when a disk device is identified as not responding. To
diagnose the issue, check whether all OSDs are up and running.

**Prerequisites:** [Prerequisites](helpers/diagnosis.md)

## Mitigation

### Recommended Actions

1. **Check for Network Issues:** Verify if the unresponsive disk issue is
   related to a network problem by following the steps in the provided Standard
   Operating Procedure (SOP) -
   [Check Ceph Network Connectivity SOP](helpers/networkConnectivity.md).
   Escalate to the ODF team if it is a network issue.

2. **Generic Debugging:** Follow the general pod debug workflow outlined below
   to identify and address potential issues.
   - [Pod Debug Workflow](helpers/podDebug.md)
   - [Gather Logs](helpers/gatherLogs.md)

**Additional Resources:**

- [Troubleshooting](helpers/troubleshootCeph.md)



------------------------------


Original Filename:  CephOSDDiskUnavailable.md

# CephOSDDiskUnavailable

## Meaning

A disk device on one of the hosts is inaccessible, leading to the corresponding
OSD being marked out by the Ceph cluster.

## Impact

**Severity:** Error
**Potential Customer Impact:** High

This alert indicates that a disk device is not accessible on one of the hosts,
resulting in the Ceph cluster marking the corresponding OSD as out. The alert is
triggered when a Ceph node fails to recover within 10 minutes.

## Diagnosis

The alert is raised when a disk device becomes inaccessible on a host, causing
the associated OSD to be marked out by the Ceph cluster. To determine which node
has failures, follow the procedure outlined in
[Determine Failed OCS Node](helpers/determineFailedOcsNode.md).

**Prerequisites:** [Prerequisites](helpers/diagnosis.md)

## Mitigation

### Recommended Actions

1. **Determine Failed OCS Node:** Follow the procedure in
   [Determine Failed OCS Node](helpers/determineFailedOcsNode.md) to identify
   the node with failures.

2. **Gather Logs:** Collect logs using the [Gather Logs](helpers/gatherLogs.md)
   procedure for further analysis.

3. **Check for Network Issues:** Verify if the issue is related to a network
   problem by following the steps in the provided Standard Operating Procedure
   (SOP) -
   [Check Ceph Network Connectivity SOP](helpers/networkConnectivity.md).
   Escalate to the ODF team if it is a network issue.



------------------------------


Original Filename:  CephOSDDown.md

# CephOSDDown

## Meaning

CephOSDDown indicates that one or more ceph-osd daemons are not running as expected.

## Impact

Ceph detects that the OSDs are down and automatically starts the recovery
process by moving the data to other available OSDs. But if the OSDs having
the copies of the data also fail during this recovery, then there is a
chance of permanent data loss.

## Diagnosis

The alert is triggered when Ceph OSD(s) is/are down,
please check the ceph-osd daemons and take corrective measures.

## Mitigation

### Recommended Actions

1. In an LSO cluster, if the disk failed, the OSD may need to be replaced.
Please ref:
[Instructions for safely replacing operational or failed devices]:
  https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.17/html-single/replacing_devices/index

2. Investigate why one or more OSDs are marked down. The ceph-osd daemon(s)
or their host(s) may have crashed or been stopped, or peer OSDs might be
unable to reach the OSD over the public or private network. Common causes
include a stopped or crashed daemon, a “down” host, or a network failure.

Verify that the host is healthy, if not switch to the node/host where the
failed OSDs are running and check the logs at
(/var/lib/rook/openshift-storage/*) may contain troubleshooting information.

Unable to resolve the failed OSDs, please connect with Red Hat Support.



------------------------------


Original Filename:  CephOSDFlapping.md

# CephOSDFlapping

## Meaning

Ceph storage OSD is flapping, indicating that a daemon has restarted 10 times \
in the last 5 minutes.

## Impact

This may affect Ceph storage stability and reliability.

## Diagnosis

Check pod events or Ceph status to identify the cause of OSD flapping.

## Mitigating

### Recommended Network Configuration

The upstream Ceph community traditionally suggests having separate public
(front-end) and private (cluster/back-end/replication) networks, offering the
following benefits:

1. **Segregation of Traffic:**
   - Heartbeat traffic and replication/recovery traffic (private) are separated
     from traffic between clients and OSDs/monitors (public).
   - Prevents one stream of traffic from DoS-ing the other, avoiding cascading failures.

2. **Additional Throughput:**
   - Enhances throughput for both public and private traffic

### Halting Flapping

If OSDs repeatedly flap (marked down and then up again), force monitors to halt
the flapping by temporarily freezing their states:

```bash
ceph osd set noup      # prevent OSDs from getting marked up
ceph osd set nodown    # prevent OSDs from getting marked down
```

These flags are recorded in the osdmap:

```bash
ceph osd dump | grep flags
```

Two other flags, noin and noout, prevent booting OSDs from being marked in or
out, respectively. Clear these flags with:

```bash
ceph osd unset noup
ceph osd unset nodown
```

Two additional flags, noin and noout, prevent booting OSDs from being marked in
or protect OSDs from eventually being marked out, regardless of the current
value of mon_osd_down_out_interval.

> Note: noup, noout, and nodown are temporary; after clearing the flags, the
> blocked action becomes possible shortly thereafter. However, the noin flag
> prevents OSDs from being marked in on boot, and daemons that started while the
> flag was set will remain that way.
---
> Note: Causes and effects of flapping can be mitigated to some extent by making
> careful adjustments to mon_osd_down_out_subtree_limit,
> mon_osd_reporter_subtree_level, and mon_osd_min_down_reporters. The optimal
> settings depend on cluster size, topology, and the Ceph release in use. The
> interaction of all these factors is subtle and beyond the scope of this
> document.



------------------------------


Original Filename:  CephOSDNearFull.md

# CephOSDNearFull

## Meaning

Utilization of the back-end storage device OSD has crossed 75% on host
`<hostname>`. Free up some space or expand the storage cluster or contact
support.

## Impact

- **Severity:** Warning
- **Potential Customer Impact:** High

The OSD storage devices nearing full capacity can impact the overall performance
and availability of the Ceph storage system.

## Diagnosis

The alert is triggered when the utilization of the back-end storage device OSD
exceeds 75%. Detailed diagnosis involves checking whether all OSDs are up and
running.

### Prerequisites

1. Verify cluster access:
   - Check the output to ensure you are in the correct context for the cluster
     mentioned in the alert.
   - List clusters you have permission to access:

     ```bash
     ocm list clusters
     ```

   - From the list, find the cluster ID of the mentioned cluster.

2. Check Alerts:
   - Get the route to this cluster’s alert manager:

     ```bash
     MYALERTMANAGER=$(oc -n openshift-monitoring get routes/alertmanager-main
     --no-headers | awk '{print $2}')
     ```

   - Check all alerts:

     ```bash
     curl -k -H "Authorization: Bearer $(oc -n openshift-monitoring sa get-token
     prometheus-k8s)" https://${MYALERTMANAGER}/api/v1/alerts | jq '.data[] |
     select( .labels.alertname) | { ALERT: .labels.alertname, STATE:
     .status.state}'
     ```

3. (Optional) Document OCS Ceph Cluster Health:
   - You may check OCS Ceph Cluster health using the rook-ceph toolbox:
     - Check and document ceph cluster health:

       ```bash
       TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
       oc rsh -n openshift-storage $TOOLS_POD
       ceph status
       ceph osd status
       exit
       ```

## Mitigation

### 1. Delete Data

The following instructions only apply
to OCS clusters that are near or full but NOT in readonly mode. Readonly mode
would prevent any changes including deleting data (i.e. PVC/PV deletions).

Delete some data, and the cluster will resolve the alert through
self-healing processes.

### 2. Current size < 1 TB, Expand to 4 TB

The user may increase capacity via the addon, and the cluster will resolve
the alert through self-healing processes.

### 3. Current size = 4TB

Please contact Dedicated Support.

Document Ceph Cluster health check:
[gather_logs](helpers/gatherLogs.md)

```bash
oc adm must-gather --image=<must-gather-image-name>
```



------------------------------


Original Filename:  CephOSDSlowOps.md

# CephOSDSlowOps

## Meaning

OSD (Object Storage Daemon) requests are taking an extended amount of time to
process, indicating potential performance issues.

## Impact

**Severity:** Warning
**Potential Customer Impact:** Medium

This alert suggests that OSDs are experiencing delays in processing requests,
potentially affecting the overall performance of the Ceph storage system.

## Diagnosis

The alert is triggered when OSD requests take longer to process than the time
defined by the `osd_op_complaint_time` parameter, which is set to 30 seconds by
default. To gather more information about the slow requests, access the OSD pod
terminal and issue the following commands:

```bash
ceph daemon osd.<id> ops
ceph daemon osd.<id> dump_historic_ops
```

Note: Replace `<id>` with the OSD number, which can be found in the pod name
(e.g., `rook-ceph-osd-0-5d86d4d8d4-zlqkx`, where `<0>` is the OSD ID).*

## Mitigation

### Recommended Actions

1. **Check Hardware/Infrastructure:** Investigate problems with the underlying
   hardware/infrastructure, such as disk drives, hosts, racks, or network
   switches. Use the Openshift monitoring console to find alerts/errors about
   cluster resources.

2. **Check Network Issues:** Verify if the slow OSD operations are related to
   network problems. Follow the steps in the provided Standard Operating
   Procedure (SOP) -
   [Check Ceph Network Connectivity SOP](helpers/networkConnectivity.md).
   Escalate to the ODF team if it is a network issue.

3. **Review System Load:** Use the Openshift console to review metrics of the
   OSD pod and the Node running the OSD. If needed, add/assign more resources to
   address system load issues.



------------------------------


Original Filename:  CephOSDVersionMismatch.md

# CephOSDVersionMismatch

## Meaning

There are different versions of Ceph OSD components running. Typically this
alert triggers during an upgrade that is taking a long time.

## Impact

It will impact cluster performance.

## Diagnosis

Verify Ceph version in OSD Pods:

```bash
    oc describe pods -n openshift-storage --selector app=rook-ceph-osd | grep CONTAINER_IMAGE
```

All the pods must have the same image

## Mitigation

Usually the problem is solved (all OSDs daemons running same Ceph version) when
 the upgrade has finished.

If the alert persists after upgrade:

Verify the ODF operator events and logs in order to find an error and an
explanation about the problem updating the OSD daemon with different version.

```bash
    ocs_operator=$(oc describe deployment -n openshift-storage ocs-operator | grep OPERATOR_CONDITION_NAME: | awk '{ print $2 }')
    oc get events --field-selector involvedObject.name=$ocs_operator --namespace openshift-storage
```

```bash
    oc logs -n openshift-storage --selector name=ocs-operator -c ocs-operator
```

If nothing found, verify the
[ODF operator state](helpers/checkOperator.md)

If the ODF operator does not present any problem,
see [general diagnosis document](helpers/diagnosis.md)

If no issues found, [gather_logs](helpers/gatherLogs.md) to provide more
information to support teams.



------------------------------


Original Filename:  CephPgRepairTakingTooLong.md

# CephPGRepairTakingTooLong

## Meaning

Self-healing operations within the Ceph storage system are taking an extended
amount of time, indicating potential issues with the repair process.

## Impact

**Severity:** Warning
**Potential Customer Impact:** High

This alert signals that self-healing operations in Ceph, specifically related to
placement groups, are taking longer than expected.

## Diagnosis

The alert is triggered when self-healing processes within Ceph are identified as
taking too long. The suggested approach is to check for inconsistent placement
groups and perform repairs using the provided Knowledgebase Article (KCS) -
[KCS with PGRepair details](https://access.redhat.com/solutions/1589113).

## Mitigation

### Recommended Actions

1. **Repair Placement Groups:** Execute the steps outlined in the KCS with
   PGRepair details to identify and repair inconsistent placement groups.

   [KCS with PGRepair details](https://access.redhat.com/solutions/1589113)

**Additional Resources:**

- [Gather Logs](helpers/gatherLogs.md)



------------------------------


Original Filename:  CephPoolQuotaBytesCriticallyExhausted.md

# CephPoolQuotaBytesCriticallyExhausted

## Meaning

Storage pool quota usage has crossed 90%. One or more pools is approaching a
configured fullness threshold.
One threshold that can trigger this warning condition is the
`mon_pool_quota_warn_threshold` configuration option.

## Impact

Due the quota configured the pool will become readonly when the quota will be
exhausted completelly

## Diagnosis

[Execute the following Ceph command](helpers/cephCLI.md) to have information
about pool status in the cluster:

```bash
    sh-5.1$ rados df
```

## Mitigation

Pool quotas can be adjusted up or down (or removed) with
[Ceph CLI](helpers/cephCLI.md)

```bash
    ceph osd pool set-quota <pool> max_bytes <bytes>
    ceph osd pool set-quota <pool> max_objects <objects>
```

Setting the quota value to 0 will disable the quota.



------------------------------


Original Filename:  CephPoolQuotaBytesNearExhaustion.md

# CephPoolQuotaBytesNearExhaustion

## Meaning

Storage pool quota usage has crossed 70%. One or more pools is approaching a
configured fullness threshold.
One threshold that can trigger this warning condition is the
`mon_pool_quota_warn_threshold` configuration option.

## Impact

Due the quota configured the pool will become readonly when the quota will be
exhausted completelly

## Diagnosis

[Execute the following Ceph command](helpers/cephCLI.md) to have information
about pool status in the cluster:

```bash
    sh-5.1$ rados df
```

## Mitigation

Pool quotas can be adjusted up or down (or removed) with
[Ceph CLI](helpers/cephCLI.md)

```bash
    ceph osd pool set-quota <pool> max_bytes <bytes>
    ceph osd pool set-quota <pool> max_objects <objects>
```

Setting the quota value to 0 will disable the quota.



------------------------------


Original Filename:  ClusterObjectStoreState.md

# ClusterObjectStoreState

## Meaning

RGW endpoint of the Ceph object store is in a failure state,
OR
One or more Rook Ceph RGW deployments have fewer ready replicas than required
for more than 15s.

## Impact

Cluster Object Store is in unhealthy state
OR
Number of ready replicas for Rook Ceph RGW deployments is less than the desired replicas.

## Diagnosis

Need to check whether the given RGW endpoints are accessible or not.
Make sure that the Ceph RGW deployments have required number of replicas.

## Mitigation

Please check the health of the Ceph cluster and the deployments and find the
root cause of the issue.




------------------------------


Original Filename:  KMSServerConnectionAlert.md

# KMSServerConnectionAlert

## Meaning

Storage Cluster KMS Server is in un-connected state for more than 5s.
Please check KMS config

## Impact

Critical.
Encryption in block and file storage will not be available.
Information cannot be retrieved or stored properly.

## Diagnosis

Connection with external key management service is not working.

## Mitigation

Review configuration values in the ´ocs-kms-connection-details´ confimap.

Verify the connectivity with the external KMS, verifying
[network connectivity](helpers/networkConnectivity.md)



------------------------------


Original Filename:  ODFPersistentVolumeMirrorStatus.md

# ODFPersistentVolumeMirrorStatus

## Meaning

The alert 'ODFPersistentVolumeMirrorStatus' indicates the mirroring status of
persistent volumes (PVs) in a Ceph pool. The two specific alert instances are
defined as follows:

1. **Critical Alert:**
   - The mirroring image(s) (PV) in a pool are not mirrored properly to the peer
     site for more than the specified alert time.
   - RBD image, CephBlockPool, and affected persistent volume details are
     provided in the alert message.

2. **Warning Alert:**
   - The status is unknown for the mirroring of persistent volumes (PVs) to the
     peer site for more than the specified alert time.
   - RBD image, CephBlockPool, and affected persistent volume details are
     included in the alert message.

## Impact

- **Critical Alert:**
  - Critical severity indicates that the mirroring of the PVs is not working
    correctly.
  - Disaster recovery may be affected, leading to potential data inconsistencies
    during failover.

- **Warning Alert:**
  - Warning severity implies an unknown status in mirroring, posing a potential
    risk to data consistency during failover.

## Diagnosis

Verify the mirroring status of the affected PVs using the
[Ceph CLI](helpers/cephCLI.md):

```bash
rbd mirror image status POOL_NAME/IMAGE_NAME
```

## Mitigation

Review [RBD mirrorpod](helpers/podDebug.md) to find out more information about
the problem.

[gather_logs](helpers/gatherLogs.md) to provide more information to support
teams.



------------------------------


Original Filename:  ODFRBDClientBlocked.md

# ODFRBDClientBlocked

## Meaning

This alert indicates that an RBD client might be blocked by Ceph on a specific
node within your Kubernetes cluster. The blocklisting occurs when the
`ocs_rbd_client_blocklisted metric` reports a value of 1 for the node.
Additionally, there are pods in a CreateContainerError state on the same node.
The blocklisting can potentially result in the filesystem for the Persistent
Volume Claims (PVCs) using RBD becoming read-only.
It is crucial to investigate this alert to prevent any disruption to your
storage cluster.

## Impact

High. It is crucial to investigate this alert to prevent any disruption to your
storage cluster.
This may cause the filesystem for the PVCs to be in a read-only state.

## Diagnosis

The blocklisting of an RBD client can occur due to several factors, such as
network or cluster slowness. In certain cases, the exclusive lock contention
among three contending clients (workload, mirror daemon, and manager/scheduler)
 can lead to the blocklist.

## Mitigation

Taint the blocklisted node: In Kubernetes, consider tainting the node that is
blocklisted to trigger the eviction of pods to another node. This approach
relies on the assumption that the unmounting/unmapping process progresses
gracefully. Once the pods have been successfully evicted, the blocklisted node
can be untainted, allowing the blocklist to be cleared. The pods can then be
moved back to the untainted node.

Reboot the blocklisted node: If tainting the node and evicting the pods do not
resolve the blocklisting issue, a reboot of the blocklisted node can be
attempted. This step may help alleviate any underlying issues causing the
blocklist and restore normal functionality.

Please note that investigating and resolving the blocklist issue promptly is
essential to avoid any further impact on the storage cluster.



------------------------------


Original Filename:  OSDCPULoadHigh.md

# OSDCpuLoadHigh

## Meaning

This alert indicates that the CPU usage in the OSD (Object Storage Daemon)
container on a specific pod has exceeded 80%, potentially affecting the
performance of the OSD.

## Impact

OSD is a critical component in Ceph storage, responsible for managing data
placement and recovery. High CPU usage in the OSD container suggests increased
processing demands, potentially leading to degraded storage performance.

## Diagnosis

To diagnose the alert, follow these steps:

1. Navigate to the Kubernetes dashboard or equivalent.
2. Access the "Workloads" section and select the relevant pod associated with
the OSD alert.
3. Click on the "Metrics" tab to view CPU metrics for the OSD container.
4. Verify that the CPU usage exceeds 80% over a significant period
(as specified in the alert configuration).

## Mitigation

If the OSD CPU usage is consistently high, consider taking the following steps:

1. Evaluate the overall storage cluster performance and identify the OSDs
contributing to high CPU usage.
2. Increase the number of OSDs in the cluster by adding more new storage
devices in the existing nodes or adding new nodes with new storage devices.
Review the Openshift Scaling storage documentation. This would help distribute
the load and improve overall system performance.



------------------------------


Original Filename:  ObcQuotaBytesAlert.md

# ObcQuotaBytesAlert

## Meaning

The 'ObcQuotaBytesAlert' is triggered when an ObjectBucketClaim (OBC) has
crossed 80% of its quota in bytes.

## Impact

The OBC has reached 80% of its quota, and it will become read-only on reaching
the quota limit. This may impact write operations to the ObjectBucketClaim.

## Diagnosis

Check the usage of the ObjectBucketClaim and its quota to determine the extent
of the breach:

```bash
ocs_objectbucketclaim_info * on (namespace, objectbucket) group_left() (ocs_objectbucket_used_bytes/ocs_objectbucket_max_bytes)
```

## Mitigation

- Review and Increase Quota: Update the quota options on the OBC using the
  following YAML configuration in the CRD:

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim  
metadata:  
  name: <obc name>  
  namespace: <namespace>  
spec:  
  bucketName:  <name of the backend bucket>  
  storageClassName: <name of storage class>  
  additionalConfig:   
    maxObjects: "1000" # sets limit on the number of objects this OBC can hold  
    maxSize: "2G" # sets the max limit for the size of data this OBC can hold
```



------------------------------


Original Filename:  ObcQuotaBytesExhausedAlert.md

# ObcQuotaBytesExhausedAlert

## Meaning

This is the next stage once we have reached [ObcQuotaObjectsAlert](ObcQuotaObjectsAlert.md).
ObjectBucketClaim has crossed the limit set by the quota(bytes) and will be
read-only now. Increase the quota in the OBC custom resource immediately.

## Impact

OBC has exhausted and reached it's limit.

## Diagnosis

Alert message will clearly indicate which OBC has reached the quota bytes limit.
Look at the deployments attached to the OBC and see what all apps are
using/filling-up the OBC.

## Mitigation

Need to increase the quota limit immediately for the ObjectBucketClaim
custom resource. We can set quota option on OBC by using the `maxObjects`
and `maxSize` options in the ObjectBucketClaim CRD

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: <obc_name>
  namespace: <namespace>
spec:
  bucketName: <name_of_the_backend_bucket>
  storageClassName: <name_of_storage_class>
  additionalConfig:
    maxObjects: "1000" # sets limit on no of objects this obc can hold
    maxSize: "2G" # sets max limit for the size of data this obc can hold
```




------------------------------


Original Filename:  ObcQuotaObjectsAlert.md

# ObcQuotaObjectsAlert

## Meaning

An ObjectBucketClaim object has crossed 80% of the size limit set by the quota(objects)
and will become read-only on reaching the quota limit.

## Impact

OBC has reached 80% of it's limit and soon will get exhausted once reaching
the quota limit.

## Diagnosis

Alert message will clearly indicate which OBC is being filled up fast.
Look at the deployments attached to the OBC and
see what all apps are using/filling-up the OBC.

## Mitigation

We can increase quota option on OBC by using the `maxObjects` and
`maxSize` options in the ObjectBucketClaim CRD

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: <obc_name>
  namespace: <namespace>
spec:
  bucketName: <name_of_the_backend_bucket>
  storageClassName: <name_of_storage_class>
  additionalConfig:
    maxObjects: "1000" # sets limit on no of objects this obc can hold
    maxSize: "2G" # sets max limit for the size of data this obc can hold
```



------------------------------


Original Filename:  ObcQuotaObjectsExhausedAlert.md

# ObcQuotaObjectsExhausedAlert

## Meaning

ObjectBucketClaim has crossed the limit set by the quota(objects) and
will be read-only now.

## Impact

Application won't be able to do any transaction through the OBC and will be stalled.

## Diagnosis

Alert message will indicate which OBC has reached the object quota limit.
Look at the deployments attached to the OBC and
see what all apps are using/filling-up the OBC.

## Mitigation

Immediately increase the quota for the OBC, specified in the alert details.
We can increase quota option on OBC by using the `maxObjects` and
`maxSize` options in the ObjectBucketClaim CRD

```yaml
apiVersion: objectbucket.io/v1alpha1
kind: ObjectBucketClaim
metadata:
  name: <obc_name>
  namespace: <namespace>
spec:
  bucketName: <name_of_the_backend_bucket>
  storageClassName: <name_of_storage_class>
  additionalConfig:
    maxObjects: "1000" # sets limit on no of objects this obc can hold
    maxSize: "2G" # sets max limit for the size of data this obc can hold
```




------------------------------


Original Filename:  OdfMirrorDaemonStatus.md

# OdfMirrorDaemonStatus

## Meaning

Mirror daemon is in unhealthy status for more than 1 minute. Mirroring on this
cluster is not working as expected. Disaster recovery is failing for the entire
cluster.

## Impact

Critical.

The mirroring operations are stopped. No images will be synced until RBD mirror
daemon will be started and running properly.
Disaster recovery functionality will not work properly until RBD mirror daemons
will be running an all images synced properly.

## Diagnosis

The RBD mirror pod in the Openshift storage namespace is in error state.

## Mitigation

Review [RBD mirrorpod](helpers/podDebug.md) to find out more information about
the problem.

[gather_logs](helpers/gatherLogs.md) to provide more information to support
teams.



------------------------------


Original Filename:  OdfPoolMirroringImageHealth.md

# OdfPoolMirroringImageHealth

## Meaning

Mirroring image(s) (PV) a pool are in Unknown state for more than 1 minute.
Mirroring might not work as expected.

## Impact

Critical.
Image duplication to the remote cluster is not working. Disaster recovery
cluster will be affected because in case of failover the information will not
be synced with the source cluster properly

## Diagnosis

Verify images status using the [Ceph CLI](helpers/cephCLI.md):

```bash
    rbd mirror image status POOL_NAME/IMAGE_NAME
```

## Mitigation

Review [RBD mirrorpod](helpers/podDebug.md) to find out more information about
the problem.

[gather_logs](helpers/gatherLogs.md) to provide more information to support
teams.



------------------------------


Original Filename:  PersistentVolumeUsageCritical.md

# PersistentVolumeUsageCritical

## Meaning

A PVC is nearing its full capacity and may lead to data loss if not attended to
timely. The alert will be fired when Persistent Volume Claim usage has exceeded
the final threshold limit of its capacity.
Please see the alert documentation text for an exact threshold limit.

## Impact

A PVC is about to be exhausted, any Write in PVS using this PVC will be blocked
when PVC will not have available space.

## Diagnosis

Using the Openshift console, go to Storage-PersistentVolumeClaims.
A list of the available PVCs with basic information about space used and
available will be shown.
Enter in the PVC affected to have more details.


## Mitigation

Expand the PVC size to increase the capacity.
In the list of PVCs (Storage-PersistentVolumeClaims), press the "three points"
button shown at the end of the affected PVC row. Select "Expand PVC" and
increase the size of the PVC.

![pvc-dropdown](helpers/screenshots/expand-pvc-dropdown.png)
![pvc-dialog](helpers/screenshots/expand-pvc-dialog.png)

Alternatively, you can also delete unnecessary data in PVs that may be taking
 up space




------------------------------


Original Filename:  PersistentVolumeUsageNearFull.md

# PersistentVolumeUsageNearFull

## Meaning

Persistent Volume Claim (PVC) usage is alarmingly very high,
indicating an imminent risk of reaching full capacity.
Please see the alert documentation text for an exact threshold limit.

## Impact

**Severity:** Warning
**Potential Customer Impact:** High

This alert signifies that a PVC is nearing its full capacity, potentially
leading to data loss if not addressed promptly.

## Diagnosis

The alert triggers when a Persistent Volume Claim (PVC) approaches or surpasses
very high capacity limit. It indicates the need to expand the PVC size to
accommodate more data or to remove unnecessary data to free up space.
Please see the alert documentation text for an exact threshold limit.

**Prerequisites:** [Prerequisites](helpers/diagnosis.md)

## Mitigation

### Recommended Actions

- **Expand the PVC Size:** Increase the capacity of the PVC to prevent data loss.
  ![Expand PVC Dropdown](helpers/screenshots/expand-pvc-dropdown.png)
  ![Expand PVC Dialog](helpers/screenshots/expand-pvc-dialog.png)
  
- **Delete Unnecessary Data:** Remove unnecessary data occupying space in the PVC.



------------------------------


Original Filename:  StorageClientHeartbeatMissed.md

# StorageClientHeartbeatMissed

## Meaning

StorageConsumer heartbeat isn't received from connected storage clients.

## Impact

Ceph monitor endpoints at storage client will have stale information. If
monitor endpoints are changed after loosing heartbeat, storage clients may not
be able to connect to ceph monitors.

## Diagnosis

Take a note of storageconsumer name from alert description and find the
connected client cluster by following
[connectedClient](helpers/connectedClient.md) document.

Login to the client cluster identified by the cluster id from above document.

Verify ODF Provider reachability from ODF Client by following
[verifyEndpoint](helpers/verifyEndpoint.md) document.

## Mitigation

### Intermittent nework connectivity

1. From diagnosis if you find endpoint is reachable, wait for at most 5 minutes
to have connection reestablished which should stop firing alert.
2. If the alert is still firing, check for any outage in your network which is
effecting ODF Provider and ODF Client connectivity, specifically the NodePort
on ODF Provider cluster referenced by storageclient resource.

### Wrong endpoint configured

1. Make sure the endpoint referenced by storageclient resource matches the
endpoint in storagecluster status
``` bash
 oc get -nopenshift-storage storagecluster ocs-storagecluster \
 -ojsonpath='{.status.storageProviderEndpoint}'
```



------------------------------


Original Filename:  StorageClientIncompatibleOperatorVersion.md

# StorageClientIncompatibleOperatorVersion

## Meaning

OCS Client operator version of connected ODF Client is not same as OCS
operator of ODF Provider

## Impact

At Warning level, ODF Client is lagging ODF Provider by one minor version. This
stops ODF Provider from getting upgraded to next minor/patch version.

At Critical level, ODF Client is ahead or lagging by two minor versions of ODF
Provider. This reduces the supportability of connected ODF Client.

## Diagnosis

From OCP Console on ODF Provider cluster:

1. Take note of ODF Version by following __Operators -> Installed Operators ->
Project: All Projects -> Search for "OpenShift Data Foundation"__
2. Take note of connected clients by following __Storage -> Storage Clients ->
Data Foundation version column corresponding to the storageconsumer from the
alert"__

Observe the difference in minor versions in info gathered from above process.

NOTE: You might want to run below command for enabling ODF Client console if
you don't see __Storage Clients__ UI

```bash
 oc patch console.v1.operator.openshift.io cluster --type=json \
 -p="[{'op': 'add', 'path': '/spec/plugins', 'value':[odf-client-console]}]"
```

## Mitigation

Update ocs-client-operator on ODF Client cluster to be on same major and minor
version as odf-operator on ODF Provider cluster.



------------------------------


Original Filename:  StorageQuotaUtilizationThresholdReached.md

# StorageQuotaUtilizationThresholdReached

## Meaning

Persistent Volume (PV) usage is alarmingly high and might reach the
allotted quota soon. Please see the alert documentation text for an
exact threshold limit.

## Impact

This alert signifies that the storage utilization on the ODF client is
close to reaching the configured storage quota, potentially leading to
blocking the creation of new PVs on the client's cluster.

## Diagnosis

The alert triggers when the storage utilization on a client's cluster
is approaching or surpassing the configured storage quota limits.
This indicates the need to either increase the configured storage quota
to accommodate more data or ask the client's cluster admin to delete
unused PVs to free up space.

## Mitigation

### Recommended Actions
- **Increase the Storage Quota:** Increase the capacity of the PVC
to prevent data loss.
  ![Storage -> Storage Client -> Edit](helpers/screenshots/storage-client-list.png)
  ![Increase Quota Dialog](helpers/screenshots/quota-increase.png)

- **Delete Unnecessary PVC:** Remove unnecessary PVC created in the
storage client cluster.



------------------------------


Original Filename:  accessToolbox.md

# Access the Toolbox

Run the following to rsh to the toolbox pod:

    TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
    oc rsh -n openshift-storage $TOOLS_POD



------------------------------


Original Filename:  cephCLI.md

# How to execute ceph commands from Openshift

Locate your rook-ceph-operator pod and connect into it

```bash
  oc rsh -n openshift-storage $(oc get pods -n openshift-storage -o name -l app=rook-ceph-operator)
```

Set your CEPH_ARGS environment variable

```bash
  sh-4.4$ export CEPH_ARGS='-c /var/lib/rook/openshift-storage/openshift-storage.config'
```

One can now run Ceph commands

```bash
  sh-5.1$ ceph -s
    cluster:
      id:     050dce42-7e96-4e9f-abff-74a14891376a
      health: HEALTH_OK

    services:
      mon: 3 daemons, quorum a,b,c (age 28m)
      mgr: a(active, since 27m)
      mds: 1/1 daemons up, 1 hot standby
      osd: 3 osds: 3 up (since 27m), 3 in (since 27m)

    data:
      volumes: 1/1 healthy
      pools:   4 pools, 113 pgs
      objects: 91 objects, 129 MiB
      usage:   285 MiB used, 6.0 TiB / 6 TiB avail
      pgs:     113 active+clean

    io:
      client:   853 B/s rd, 18 KiB/s wr, 1 op/s rd, 1 op/s wr
```



------------------------------


Original Filename:  checkOperator.md

# OCS Operator diagnosis

Checking on the OCS operator status involves checking the operator subscription
status and the operator pod health.

## OCS Operator Subscription Health

Check the ocs-operator subscription status

```bash
  oc get sub $(oc get pods -n openshift-storage | grep -v ocs-operator) -n openshift-storage  -o json | jq .status.conditions
```

Like all operators, the status conditions types are:

**CatalogSourcesUnhealthy, InstallPlanMissing, InstallPlanPending,
InstallPlanFailed**

The status for each type should be False. For example:

```bash
    [
      {
        "lastTransitionTime": "2021-01-26T19:21:37Z",
        "message": "all available catalogsources are healthy",
        "reason": "AllCatalogSourcesHealthy",
        "status": "False",
        "type": "CatalogSourcesUnhealthy"
      }
    ]
```

The output above shows a false status for type CatalogSourcesUnHealthly,
meaning the catalog sources are healthy.

## OCS Operator Pod Health

Check the OCS operator pod status to see if there is an OCS operator upgrading
in progress.

WIP: Find specific status for upgrade (pending?)

To find and view the status of the OCS operator:

```bash
  oc get pod -n openshift-storage | grep ocs-operator OCSOP=$(oc get pod -n openshift-storage -o custom-columns=POD:.metadata.name --no-headers | grep cs-operator)
  echo $OCSOP
  oc get pod/${OCSOP} -n openshift-storage
  oc describe pod/${OCSOP} -n openshift-storage
```

If you determine the OCS operator is in progress, please be patient,
wait 5 minutes and this alert should resolve itself.

If you have waited or see a different error status condition,
please continue troubleshooting.



------------------------------


Original Filename:  connectedClient.md

# Find connected ODF Client cluster

List all the storageconsumers that are onboarded onto the provider cluster
```bash
  oc get storageconsumer -nopenshift-storage
```

Extract the interested client cluster id from storageconsumer name
```bash
  CONSUMERNAME="storageconsumer-<ID>"
  CLIENTCLUSTERID=${CONSUMERNAME/storageconsumer-/}
  CONSUMERUID=$(oc get storageconsumer -nopenshift-storage ${CONSUMERNAME} \
    -ojsonpath='{.metadata.uid}')
```

Connected ODF Client cluster id will be stored in `CLIENTCLUSTERID` and UID in
`CONSUMERUID`



------------------------------


Original Filename:  determineFailedOcsNode.md

# Check node status

Run the following to get the list of worker nodes and check for the node status:

```bash
    oc get nodes --selector='node-role.kubernetes.io/worker','!node-role.kubernetes.io/infra'
```

Describe the node which is of NotReady status to get more information on the
failure:

```bash
    oc describe node <node_name>
```



------------------------------


Original Filename:  diagnosis.md

# Diagnosis cluster

## Verify cluster access

Check the output to ensure you are in the correct context for the cluster
mentioned in the alert. If not, please change context and proceed.

List clusters you have permission to access:

```bash
    ocm list clusters
```

From the list above, find the cluster id of the cluster named in the alert.
If you do not see the alerting cluster in the list above please refer
[Effective communication with SRE Platform](https://red.ht/srep-comms)

Create a tunnel through backplane by providing SSH key passphrase:

```bash
    ocm backplane tunnel <cluster_id>
```

In a new tab, login to target cluster using backplane by providing 2FA:

```bash
    ocm backplane login <cluster_id>
```

## Check Alerts

Set port-forwarding for alertmanager:

```bash
    oc port-forward alertmanager-managed-ocs-alertmanager-0 9093 -n
    openshift-storage
```

Check all alerts

```bash
    curl http://localhost:9093/api/v1/alerts | jq '.data[] | select( .labels.alertname) | { ALERT: .labels.alertname, STATE: .status.state}'
```

## Check OCS Ceph Cluster Health

You may directly check OCS Ceph Cluster health by using the rook-ceph toolbox.

Step 1: [Check and document ceph cluster health](cephCLI.md):

Step 2: From the bash command prompt, run the following and capture the output.

```bash
    ceph status
    ceph osd status
    exit
```

If `ceph status` is not in **HEALTH\_OK**, please look at the Troubleshooting
 section to resolve issue.

## Check Worker Node Status

If `ceph status` is not **HEALTH\_OK** and all unhealthy components are related
 to a particular node, then the following steps will help identify if the
 underlying infrastructure is at fault.

Step 1: Check Node Health:

```bash
    $ oc get nodes -o wide

    NAME                                         STATUS   ROLES          AGE   VERSION           INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                                                        KERNEL-VERSION                 CONTAINER-RUNTIME
    ip-10-0-128-234.eu-west-2.compute.internal   Ready    master         89m   v1.23.5+3afdacb   10.0.128.234   <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-129-200.eu-west-2.compute.internal   Ready    infra,worker   66m   v1.23.5+3afdacb   10.0.129.200   <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-133-54.eu-west-2.compute.internal    Ready    worker         84m   v1.23.5+3afdacb   10.0.133.54    <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-144-158.eu-west-2.compute.internal   Ready    master         89m   v1.23.5+3afdacb   10.0.144.158   <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-153-73.eu-west-2.compute.internal    Ready    infra,worker   66m   v1.23.5+3afdacb   10.0.153.73    <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-159-144.eu-west-2.compute.internal   Ready    worker         82m   v1.23.5+3afdacb   10.0.159.144   <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-168-106.eu-west-2.compute.internal   Ready    infra,worker   66m   v1.23.5+3afdacb   10.0.168.106   <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-173-205.eu-west-2.compute.internal   Ready    master         89m   v1.23.5+3afdacb   10.0.173.205   <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
    ip-10-0-175-99.eu-west-2.compute.internal    Ready    worker         83m   v1.23.5+3afdacb   10.0.175.99    <none>        Red Hat Enterprise Linux CoreOS 410.84.202206080346-0 (Ootpa)   4.18.0-305.49.1.el8_4.x86_64   cri-o://1.23.3-3.rhaos4.10.git5fe1720.el8
```

If any nodes are not ready/scheduable, then continue to Step 2.

Step 2: Inspect Node Events:

```bash
    oc get events -n default | grep NODE_NAME
```

Example:

```bash
    $ oc get events -n default | grep 10-0-159-144

    57m         Normal    ConfigDriftMonitorStopped                          node/ip-10-0-159-144.eu-west-2.compute.internal      Config Drift Monitor stopped
    57m         Normal    NodeNotSchedulable                                 node/ip-10-0-159-144.eu-west-2.compute.internal      Node ip-10-0-159-144.eu-west-2.compute.internal status is now: NodeNotSchedulable
    57m         Normal    Cordon                                             node/ip-10-0-159-144.eu-west-2.compute.internal      Cordoned node to apply update
    57m         Normal    Drain                                              node/ip-10-0-159-144.eu-west-2.compute.internal      Draining node to update config.
    11m         Normal    OSUpdateStarted                                    node/ip-10-0-159-144.eu-west-2.compute.internal
    11m         Normal    OSUpdateStaged                                     node/ip-10-0-159-144.eu-west-2.compute.internal      Changes to OS staged
    11m         Normal    PendingConfig                                      node/ip-10-0-159-144.eu-west-2.compute.internal      Written pending config rendered-worker-c8a49ffa8d6d6ee43a4e4ae5b5c7f60f
    11m         Normal    Reboot                                             node/ip-10-0-159-144.eu-west-2.compute.internal      Node will reboot into config rendered-worker-c8a49ffa8d6d6ee43a4e4ae5b5c7f60f
    10m         Normal    NodeNotReady                                       node/ip-10-0-159-144.eu-west-2.compute.internal      Node ip-10-0-159-144.eu-west-2.compute.internal status is now: NodeNotReady
    10m         Normal    Starting                                           node/ip-10-0-159-144.eu-west-2.compute.internal      Starting kubelet.
```

Look for any events similar to the above example which may indicate the node
is undergoing maintainence.

## Further info

### OpenShift Data Foundation Dedicated Architecture

Red Hat OpenShift Data Foundation Dedicated (ODF Dedicated) is deployed in
converged mode on OpenShift Dedicated Clusters by the OpenShift Cluster Manager
 add-on infrastructure.

Related Links

* [ODF Dedicated Converged Add-on Architecure](https://docs.google.com/document/d/1ISEY16OfsvEPmlJEjEwPvDvDs0KyNzgl369A-V6-GRA/edit#heading=h.mznotzn8pklp)

* [ODF Product Architecture](https://access.redhat.com/documentation/en-us/red_hat_openshift_container_storage/4.6/html/planning_your_deployment/ocs-architecture_rhocs)


Check the links to identify the errors.

1) [https://access.redhat.com/documentation/en-us/red\_hat\_ceph\_storage/4/html/troubleshooting\_guide/troubleshooting-ceph-osds#common-ceph-osd-error-messages-in-the-ceph-logs\_diag](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/troubleshooting_guide/troubleshooting-ceph-osds#common-ceph-osd-error-messages-in-the-ceph-logs_diag)

2) [https://access.redhat.com/documentation/en-us/red\_hat\_ceph\_storage/4/html/troubleshooting\_guide/troubleshooting-ceph-placement-groups#inconsistent-placement-groups\_diag](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/troubleshooting_guide/troubleshooting-ceph-placement-groups#inconsistent-placement-groups_diag)



------------------------------


Original Filename:  gatherLogs.md

# Optional log gathering

Document Ceph Cluster health check:

```bash
    oc adm must-gather --image=<ODF-MUST-GATHER-IMAGE>
```





------------------------------


Original Filename:  networkConnectivity.md

# Check Ceph Network Connectivity
## Check OCP Cluster Connectivity
### Option 1 (Preferred)

First, get the IP addresses and ports of the Ceph mons:

```bash
    oc get cm rook-ceph-mon-endpoints -ojson -n openshift-storage | jq -r '.data."data"'
```

Now, start a debug pod on any node in the cluster

```bash
    oc debug node/<any-node-name> -n openshift-storage
```

Node names can be found with `oc get nodes`.
Once you are in the debug container, start a `toolbox-root` container with the
RHEL support tools:

```bash
    sh-4.4# chroot /host
    sh-4.4# toolbox
```

Now you are able to use Netcat and can check the connectivity to the mons using:

```bash
    nc -vz <mon-ip> <mon-port>
```

If you cannot connect to the mons, that is an indication that there is a
network issue.

### Option 2
The first option is preferred, only use this option if you do not have
permission to create a debug pod.

First, count the number of Ceph mon pods:

```bash
    oc get pods -n openshift-storage | grep rook-ceph-mon
```

Next, get the ceph tools pod:

```bash
    oc get pods -n openshift-storage | grep rook-ceph-tools
```

Then, create a remote shell session in that pod:

```bash
    oc rsh -n openshift-storage <rook-ceph-tools pod name from previous step>
```

Finally, check the status of the Ceph cluster:

```bash
    ceph -s
```

It is an indication that there might be a network connectivity issue if you get
an output which has a cluster status of `HEALTH_WARN` and which does not have
all the mon daemons in the service section, e.g.

```bash
    $ oc rsh -n openshift-storage rook-ceph-tools-79ccc8ddc5-77brq
    sh-4.4$ ceph -s
        cluster:
        id:     70f6e8bf-3ee1-494e-b6a0-c89ac75582d1
        health: HEALTH_WARN
                1 MDSs report slow metadata IOs

        services:
        mon: 1 daemons, quorum a (age 116m)
        mgr: no daemons active
        mds: 1/1 daemons up
        osd: 0 osds: 0 up, 0 in

        data:
        volumes: 1/1 healthy
        pools:   0 pools, 0 pgs
        objects: 0 objects, 0 B
        usage:   0 B used, 0 B / 0 B avail
        pgs:
```

## Check Consumer to Provider Connectivity
To start, get the provider IP and port:

```bash
    oc get storagecluster -n openshift-storage -o json | grep storageProviderEndpoint
```

Now, create a debug pod in the `openshift-storage` namespace:

```bash
    oc debug -n openshift-storage
```

First, check that you can ping the provider:

```bash
    oc exec bash -- ping -c 5 <provider ip from first step>
```

Second, check that you can connect to the port:

```bash
    nc -vz <provider ip from first step> <provider port from first step>
```

## If it is a Network Issue
We cannot do much about the possible causes of network issues e.g. misconfigured
 AWS security group. Escalate to the ODF/openshift support.



------------------------------


Original Filename:  podDebug.md

# Pod debugging

pod status: pending → Check for resource issues, pending pvcs, node assignment,
kubelet problems.

```bash
    oc project openshift-storage
    oc get pod | grep {ceph-component}
```

Set MYPOD for convenience:

```bash
    # Examine the output for a {ceph-component} that is in the pending state, not running or not ready
    MYPOD=<pod identified as the problem pod>
```

Look for resource limitations or pending pvcs. Otherwise, check for node
assignment.

```bash
    oc get pod/${MYPOD} -o wide
```

pod status: NOT pending, running, but NOT ready → Check readiness probe.

```bash
    oc describe pod/${MYPOD}
```

pod status: NOT pending, but NOT running → Check for app or image issues.

```bash
    oc logs pod/${MYPOD}
```

If a node was assigned, check kubelet on the node.


------------------------------


Original Filename:  sre-to-engineering-escalation.md

# SRE-to-ODF-Engineering escalation path

## Purpose

This SOP describes how the SRE Team will escalate issues to the
ODF Engineering Team in case of incidents which would require help
from ODF engineering to resolve them.

## Scope

The scope of this escalation path is to cover the incidents which have
unavailability/data loss associated with the customer and none of the
existing SOPs help to resolve the respective incident at the same time.

## Prerequisites

* `MTSRE` Role permissions over OCM.

## Responsibilities

* SRE to only escalate the issue to engineering on an urgent basis when the
incident is associated with unavailability or data loss for the customer.
* ocm-cli version 0.1.63

## Procedure

### Determine whether the incident leads to unavailability / data loss for the customer

The best way to determine this is to see if the corresponding provider cluster
has any storageconsumers or not.

* Determine the cluster ID of the Provider cluster associated with the customer,
in case it's not directly available from PagerDuty incident: Happens when the
incident's source is an ocs-consumer.

* Backplane access into the provider cluster (Checkout [References](#references)
for the SOP to do so).

* See if there are any storageconsumers or not.

    oc get storageconsumers.ocs.openshift.io -n openshift-storage

If there are no storageconsumers, then wait until the next set of ODF's working
hours to escalate the issue to engineering.

### Escalation path when the incident urgently requires help from ODF Engineering

* Follow the steps in [link](<https://source.redhat.com/groups/public/openshiftplatformsre/wiki/how_to_sre_escalate_towards_engineering>),
starting with submitting the Google Form,
to get help from the ODF Engineering Team.

### If above steps do not work

Follow the manual steps to escalate to ODF Engineering Team

* Fetch certain details of the impacted cluster:
  * Cluster Details:

    ocm describe cluster <internal/external-id-of-cluster>

    For example

    ```bash
    ❯ ocm describe cluster 1s0q9mp65e2f370q9s7ip75g6sj0sifg

    ID:      1s0q9mp65e2f370q9s7ip75g6sj0sifg
    External ID:    7ca71103-f0d8-4e66-a586-35332eaa4b10
    Name:      e2e-ci-prov
    State:      ready
    API URL:    https://<management-domain-address>:6443
    API Listening:    external
    Console URL:    https://<url-address-through-which-we-access-cluster-console-ui>
    Masters:    3
    Infra:      2
    Computes:    3
    Product:    osd
    Provider:    aws
    Version:    4.10.11
    Region:      us-west-2
    Multi-az:    false
    CCS:      true
    Subnet IDs:    [subnet-06a34a7bb480707bf subnet-07b3053eb531c5e70]
    PrivateLink:    false
    STS:      false
    Existing VPC:    true
    Channel Group:    stable
    Cluster Admin:    true
    Organization:    Red Hat-Storage-OCS
    Creator:    <name>-storage-ocs
    Email:      <name>@domain.com
    AccountNumber: <acc-number>
    Created:    2022-05-05T15:53:01Z
    Expiration:    2022-06-16T14:09:19Z
    Shard:      https://domain-name.openshiftapps.com:6443
    ```

* Open a Jira ticket in the [RHOSDFP Jira board](<https://issues.redhat.com/projects/RHOSDFP>)
with the following details:

    ```bash
    Basic Details:

    Addon name:
    Addon version: <can be gotten via
                   `oc get csvs -n <addon-namespace>` on the affected cluster>
    OCP version:
    Business Impact:
    Description:

    Cluster and Customer Details:
        <output of the following command> `ocm describe cluster <internal-id>`

    Pagerduty Incident: <PD URL pointing to the incident>
    ```

    Additional Operators which came with the addon (including the core addon's
    operator): \<output of the following command from inside the affected cluster>
    `oc get csvs -n openshift-storage`

    (Example ticket mentioned in the [References](#references))

* Open a google chat thread in [ODF Managed Services Escalation](https://mail.google.com/chat/u/0/?zx=545uzcc7jlkp#chat/space/AAAAOdTnXXo)
  * @hey odf-cae-team I need engineering assistance with \<RHOSDFP ticket you created>
  * Then in the next message in the thread provide a short description of the issue.
* One of the Engineering escalation contacts is expected to ack the escalation
coming from SRE in under 15 minutes and involve the right set of engineering
team on the issue.
* Get in touch with the associated person of ODF Engineering and get on a bridge
call with them if need be to resolve the issue.
* If there is no acknowledgement by the engineering escalation contacts, a call
should be made to the engineering escalation contact as per [this table](<https://docs.google.com/document/d/1RKvxXnxoIaIPW-tbONnZ1t9Pmec5TH2qYgDzAKSKtO4/edit#bookmark=kix.x1bsgr3rpjx6>).

## References

* [OCM CLI Version 0.1.63](https://github.com/openshift-online/ocm-cli/releases/tag/v0.1.63)
* [RHSTOR Jira board](https://issues.redhat.com/projects/RHSTOR)
* [ODF Managed Services Escalation](https://mail.google.com/chat/u/0/?zx=545uzcc7jlkp#chat/space/AAAAOdTnXXo)
* [Example of RHSTOR ticket](https://issues.redhat.com/projects/RHSTOR/issues/RHSTOR-3329)
* [Steps to backplane access into a cluster](https://gitlab.cee.redhat.com/service/managed-tenants-sops/-/blob/main/MT-SRE/sops/addon-enable-backplane.md)
* [Interim SRE-to-ODF-Engineering escalation path](https://docs.google.com/document/d/1RKvxXnxoIaIPW-tbONnZ1t9Pmec5TH2qYgDzAKSKtO4/edit)
* [RHSTOR ticket tracking the RFE to allow fetching the Provider Cluster ID from any of its associated consumers](https://issues.redhat.com/browse/RHSTOR-3381)



------------------------------


Original Filename:  troubleshootCeph.md

# Troubleshooting Ceph

Ceph commands

Some common commands to troubleshoot a Ceph cluster:

* ceph status
* ceph osd status
* cepd osd df
* ceph osd utilization
* ceph osd pool stats
* ceph osd tree
* ceph pg stat

The first two status commands provide the overall cluster health.
The normal state for cluster operations is `HEALTH\_OK`, but will still function
 when the state is in a `HEALTH\_WARN` state. If you are in a `WARN` state, then
 the cluster is in a condition that it may enter the `HEALTH\_ERROR` state at
 which point all disk I/O operations are halted. If a `HEALTH\_WARN` state is
 observed, then one should take action to prevent the cluster from halting
 when it enters the `HEALTH\_ERROR` state.

Problem 1

Ceph status shows that the OSD is full .Example Ceph OSD-FULL error

```bash
  ceph status
    cluster:
      id:     62661e0d-417c-485e-b01f-562e9493f121
      health: HEALTH\_ERR
              3 full osd(s)
              3 pool(s) full

    services:
      mon: 3 daemons, quorum a,b,c (age 3h)
      mgr: a(active, since 3h)
      mds: ocs-storagecluster-cephfilesystem:1 {0=ocs-storagecluster-cephfilesystem-a=up:active} 1 up:standby-replay
      osd: 3 osds: 3 up (since 3h), 3 in (since 3h)

    data:
      pools:   3 pools, 192 pgs
      objects: 223.01k objects, 870 GiB
      usage:   2.6 TiB used, 460 GiB / 3 TiB avail
      pgs:     192 active+clean

    io:
      client:   853 B/s rd, 1 op/s rd, 0 op/s wr
```

1) Check the alert manager for readonly alert

```bash
  curl -k -H "Authorization: Bearer $(oc -n openshift-monitoring sa get-token prometheus-k8s)"  https://${MYALERTMANAGER}/api/v1/alerts | jq '.data[] | select( .labels.alertname) | { ALERT: .labels.alertname, STATE: .status.state}'
```

2) If CephClusterReadOnly alert is listed from the above curl command, then see :

    [CephClusterReadOnly alert](../CephClusterReadOnly.md)

Problem 2

Ceph status shows an issue with osd, as see in example below

Example Ceph OSD error

```bash
  cluster:
      id:     263935ae-deb3-47e0-9355-d4a5c935aaf5
      health: HEALTH\_ERR
              1 MDSs report slow metadata IOs
              2 osds down
              2 hosts (2 osds) down
              1 nearfull osd(s)
              3 pool(s) nearfull
              11/2142 objects unfound (0.514%)
              Reduced data availability: 237 pgs inactive, 237 pgs down
              Possible data damage: 8 pgs recovery\_unfound
              Degraded data redundancy: 833/6426 objects degraded (12.963%), 24 pgs degraded, 63 pgs undersized

    services:
      mon: 3 daemons, quorum a,b,c (age 115m)
      mgr: a(active, since 112m)
      mds: myfs:1 {0=myfs-b=up:active} 1 up:standby-replay
      osd: 3 osds: 1 up (since 2m), 3 in (since 113m)
```

Take a look to solving [common osd errors](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/troubleshooting_guide/troubleshooting-ceph-osds#most-common-ceph-osd-errors)

Problem 3

Issues seen with PG, example

Example Ceph PG error

```bash
  cluster:
      id: 0a1a6dcb-2146-42f7-9e6f-8b933614c45f
      health: HEALTH\_ERR Degraded data redundancy
              126/78009 objects degraded (0.162%)
              7 pgs degraded Degraded data redundancy (low space)
              1 pg backfill\_toofull

      data:
      pools:   10 pools, 80 pgs
      objects: 26.00k objects, 100 GiB
      usage:   306 GiB used, 5.7 TiB / 6.0 TiB avail
      pgs:     126/78009 objects degraded (0.162%)
              35510/78009 objects misplaced (45.520%)
              55 active+clean
              12 active+remapped+backfill\_wait
              4  active+recovery\_wait+undersized+degraded+remapped
              3  active+recovery\_wait+degraded
              2  active+recovery\_wait
              2  active+recovering+undersized+remapped
              1  active+recovering
              1  active+remapped+backfill\_toofull
```

Review [Solving pg error](https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/4/html/troubleshooting_guide/troubleshooting-ceph-placement-groups#most-common-ceph-placement-group-errors)





------------------------------


Original Filename:  verifyEndpoint.md

# Verify ODF Provider reachability from ODF Client

You should have the uid of storageconsumer on ODF Provider to which
storageclient on ODF Client established a connection.

Find the provider endpoint configured in ODF Client cluster
```bash
  oc get storageclient -A -ojsonpath='{.items[?(@.status.id==
  "<CONSUMERUID>")].spec.storageProviderEndpoint}'
```

Verify reachability of endpoint gathered from above command, usually
ocs-client-operator is installed in `openshift-storage-client` namespace.
```bash
  oc rsh -n<CLIENT_NAMESPACE> deploy/ocs-client-operator-controller-manager \
  curl <ENDPOINT>
```

Any response other than `Empty reply from server` indicates connection failure.



------------------------------



Original Filename:  NoOvnClusterManagerLeader.md

# NoOvnClusterManagerLeader

## Meaning

This alert is triggered when ovn-kubernetes cluster does not have a leader for
more than 10 minutes.

## Impact

When OVN-Kubernetes cluster manager is unable to elect a leader (via kubernetes
lease API), networking control plane is degraded. A subset of networking control
plane functionality is degraded. This includes, but not limited to the following
networking control plane functionality:
* Node resource allocation
* EgressIP assignment/re-assignment and health checks
* EgressService node allocation/re-allocation
* DNS name resolver functionality for EgressFirewall
* OVN secondary networks IPAM

## Diagnosis

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire: [Alert
hierarchy](./hierarchy/alerts-hierarchy.svg)

### OVN-kubernetes control-plane pods

Check that all pods of the `ovnkube-control-plane` deployment are READY:
```shell
oc get deploy -n openshift-ovn-kubernetes ovnkube-control-plane
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-control-plane
```

Check if there is a leader for the ovn-kubernetes cluster:
```shell
oc get lease -n openshift-ovn-kubernetes

NAME                    HOLDER                                   AGE
ovn-kubernetes-master   ovnkube-control-plane-85f4486946-jx95r   32m
```

`HOLDER` shown above is the leader pod.

Check the logs of the of the `ovnkube-control-plane` deployment pods to see if
leader election happened or if an error occurred:
```shell
oc logs <podname> -n openshift-ovn-kubernetes --all-containers | grep elect
```

## Mitigation

### If the control plane nodes are not running

Follow the steps described in the [disaster and recovery documentation][dr_doc].

### If the cluster network operator is reporting error

Follow the condition reported in the operator to fix the operator managed
services.

### If one of the ovnkube-control-plane pods is not running

The ovnkube-cluster-manager container in the ovn kubernetes control-plane pod
should run the leader election if the old leader is down, you may need to check
the other running ovnkube-control-plane pods' logs for more information about
why the election failed.

### If all the ovnkube-control-plane pods are not running

Check the status of the ovnkube-control-plane pods, and follow the [Pod
lifecycle][Pod lifecycle] to see what is blocking the pods to be running.

### If all the ovnkube-control-plane pods are running

Follow the steps above: [OVN-Kubernetes control plane
pods](#ovn-kubernetes-control-plane-pods)

[Pod lifecycle]:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
[dr_doc]:
    https://docs.openshift.com/container-platform/latest/backup_and_restore/control_plane_backup_and_restore/disaster_recovery/about-disaster-recovery.html



------------------------------


Original Filename:  NoOvnMasterLeader.md

# NoOvnMasterLeader

## Meaning

This alert is triggered when ovn-kubernetes cluster does not have a
leader for more than 10 minute.

> NOTE: This alert only applies and its only fired in OCP 4.13 or previous
> releases.

## Impact

When ovnkube-master is unable to elect a leader (via kubernetes lease
API), networking control plane is degraded.
Networking configuration updates applied to the cluster will not be
implemented while there is no OVN Kubernetes leader.
Existing workloads should continue to have connectivity.
OVN-Kubernetes control plane is not functional.

## Diagnosis

### Fix alerts before continuing

Check to ensure the following alerts are not firing and resolved before
continuing as they may cause this alert to fire:

[Alert hierarchy](./hierarchy/alerts-hierarchy.svg)

### OVN-kubernetes master pods

Check if all the ovn-kube masters are running:

    oc get ds -n openshift-ovn-kubernetes ovnkube-master
    oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-master

Check if there is a leader for the ovn-kubernetes cluster:

    oc get lease -n openshift-ovn-kubernetes

    acquireTime: "2023-01-30T18:19:17.620449Z"
    holderIdentity: ovn-control-plane
    leaseDurationSeconds: 60
    leaseTransitions: 0
    renewTime: "2023-02-08T10:38:51.940040Z"

`holderIdentity` shown above, contains the node name where the leader pod
resides.
Check the logs for any of the running ovnkube-master to see if there is
leader election happened and if there is an error occurred.

    oc logs -n openshift-ovn-kubernetes ovnkube-master-xxxxx --all-containers | grep elect

## Mitigation

### If the control plane nodes are not running

Follow the steps described in the [disaster and recovery documentation][dr_doc].

### If the cluster network operator is reporting error

Follow the condition reported in the operator to fix the operator managed services.

### If one of the ovnkube-master pods is not running

The ovnkube-master container in the ovn kubernetes master pod should run the
leader election if the old leader is down, you may need to check the other
running ovnkube-master pods' logs for more information about why the election
failed.

### If all the ovnkube-master pods are not running

Check the status of the ovnkube-master pods, and follow the
[Pod lifecycle][Pod lifecycle] to see what is blocking the pods to be running.

### If all the ovnkube-master pods are running

Follow the steps above: [OVN-Kubernetes master pods](#ovn-kubernetes-master-pods)

[Pod lifecycle]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
[dr_doc]: https://docs.openshift.com/container-platform/latest/backup_and_restore/control_plane_backup_and_restore/disaster_recovery/about-disaster-recovery.html



------------------------------


Original Filename:  NoRunningOvnControlPlane.md

# NoRunningOvnControlPlane

## Meaning

This alert is triggered when there are no OVN-Kubernetes control plane pods
[Running][PodRunning] for `5m`.

## Impact

When OVN-Kubernetes control plane is not running, networking control plane is
degraded. A subset of networking control plane functionality is degraded. This
includes, but not limited to the following networking control plane
functionality:
* Node resource allocation
* EgressIP assignment/re-assignment and health checks
* EgressService node allocation/re-allocation
* DNS name resolver functionality for EgressFirewall
* OVN secondary networks IPAM

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire: [Alert
hierarchy](./hierarchy/alerts-hierarchy.svg)

## Diagnosis

### Control plane issue

This can occur when multiple control plane nodes are powered off or are unable
to connect with each other via the network. Check that all control plane nodes
are powered on and that network connections between each machine are functional:
```shell
oc get node -l node-role.kubernetes.io/control-plane=""
```

### Cluster network operator

Cluster network operator (CNO) manages the CRUD operations for OVN-Kubernetes
daemonset. Verify the CNO is running:
```shell
oc -n openshift-network-operator get pods -l name=network-operator
```

Verify the [CNO](https://github.com/openshift/cluster-network-operator/) is
functioning without error by checking the operator Status:
```shell
oc get co network
```

If the network is degraded, you can see the full error message by describing the
object. Pay attention to any error message reported by Status Conditions of type
Degraded:
```shell
oc describe co network
```

A successful reconcile for this daemonset looks like this in the CNO logs:
```shell
I0611 11:13:35.048771       1 log.go:245] Apply / Create of (apps/v1, Kind=Deployment) openshift-ovn-kubernetes/ovnkube-control-plane was successful
```

### OVN-Kubernetes control-plane pod

Check that all pods of the `ovnkube-control-plane` deployment are READY:
```shell
oc get deploy -n openshift-ovn-kubernetes ovnkube-control-plane
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-control-plane
```

If one of the `ovnkube-control-plane` pods is not READY, check the overall
status of the pod and that of specific containers:
```shell
oc describe pod/<podname> -n openshift-ovn-kubernetes
```

After understanding which container is not starting successfully, gather the
runtime logs from that container:
```shell
oc logs <podname> -n openshift-ovn-kubernetes -c <container>
```
You may need to use `--previous` command with `oc logs` command to get the logs
of the previous execution run of a container. Pay close attention to any log
output starting with "E" for Error.

## Mitigation

The appropriate mitigation will be very different depending on the cause of the
error discovered in the diagnosis. Investigate the issue using the steps
outlined in diagnosis and contact the incident response team in your
organisation if fixing the issue is not apparent.

[PodRunning]:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase



------------------------------


Original Filename:  NoRunningOvnMaster.md

# NoRunningOvnMaster

## Meaning

This [alert][NoRunningOvnMaster] is triggered when there are no
OVN-Kubernetes master control plane pods
[Running][PodRunning]
This is a critical-level alert if no OVN-Kubernetes master control plane pods
are not running for `10m`.

> NOTE: This alert only applies and its only fired in OCP 4.13 or previous
> releases.

## Impact
Networking control plane is not functional. Networking configuration updates
will not be applied to the cluster.
Without a functional networking control plane, existing workloads may continue
to be partially functional,
but new workloads will not be functional.
Updates required for functioning Kubernetes services will not be performed.

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire:
[Alert hierarchy](./hierarchy/alerts-hierarchy.svg)

## Diagnosis
### Control plane issue

This can occur multiple control plane nodes are powered off or are unable to
connect each other via the network. Check that all control plane nodes are
powered and that network connections between each machine are functional.

    oc get node -l node-role.kubernetes.io/master=""

### Cluster network operator
Cluster Network operator (CNO) manages the CRUD operations for OVN-Kubernetes
daemonset.
Verify the CNO is running:

    oc -n openshift-network-operator get pods -l name=network-operator

Verify the [CNO](https://github.com/openshift/cluster-network-operator/) is
functioning without error by checking the operator Status:

    oc get co network

If the network is degraded, you can see the full error message by describing the
object. Pay attention to any error message reported by Status Conditions of type
Degraded:

    oc describe co network

Check the CNO logs for when it is reconciling the daemonset for ovnkube-master.

    oc logs deployment/network-operator -n openshift-network-operator

A successful reconcile for this daemonset looks like this in the CNO logs:

    I0228 14:48:30.941130       1 log.go:184] reconciling (apps/v1, Kind=DaemonSet)
                                openshift-ovn-kubernetes/ovnkube-master
    I0228 14:48:30.960944       1 log.go:184] update was successful

### OVN-Kubernetes master pod
Verify the _DESIRED_ number of daemonsets is equal to the number of Kubernetes
control plane nodes:

    oc get ds -n openshift-ovn-kubernetes ovnkube-master
    oc get nodes -l node-role.kubernetes.io/master="" -o name | wc -l

If _READY_ count from the daemonset `ovnkube-master` is not equal to
_DESIRED_ then understand which container is failing in the OVN-Kubernetes
master pod by describing one of the failing pods with `oc describe pod ...`.
After understanding which container is not starting successfully, gather the
runtime logs from that container.
You may need to use `--previous` command with `oc logs` command to get the
logs of the previous execution run of a container.

Pay close attention to any log output starting with "E" for Error:

    oc -n openshift-ovn-kubernetes logs $OVNKUBE-MASTER-POD-NAME
    --all-containers=true | grep "^E"

## Mitigation

The appropriate mitigation will be very different depending on the cause of the
error discovered in the diagnosis.
Investigate the issue using the steps outlined in diagnosis and contact the
incident response team in your organisation if fixing the issue is not apparent.

[NoRunningOvnMaster]: https://github.com/openshift/cluster-network-operator/blob/master/bindata/network/ovn-kubernetes/self-hosted/alert-rules-control-plane.yaml
[PodRunning]: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase



------------------------------


Original Filename:  NodeWithoutOVNKubeNodePodRunning.md

# NodeWithoutOVNKubeNodePodRunning

## Meaning

The `NodeWithoutOVNKubeNodePodRunning` alert is triggered when one or more Linux
nodes do not have a running OVNkube-node pod for a period of time.

## Impact

This is a warning alert. Existing workloads on the node may continue to have
connectivity but any additional workloads will not be provisioned on the node.
Any network policy changes will not be implemented on existing workloads on the
node.

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire:
[Alert hierarchy](./hierarchy/alerts-hierarchy.svg)

## Diagnosis

Check the nodes which should have the ovnkube-node running.

    oc get node -l kubernetes.io/os!=windows

Check the expected running replicas of ovnkube-node.

    oc get daemonset ovnkube-node -n openshift-ovn-kubernetes

Check the ovnkube-node pods status on the nodes.

    oc get po -n openshift-ovn-kubernetes -l app=ovnkube-node -o wide

Describe the pod if there is non-running ovnkube-node pod.

    oc describe po -n openshift-ovn-kubernetes <ovnkube-node-name>

Check the pod logs for the failing ovnkube-node pods

    oc logs <ovnkube-node-name> -n openshift-ovn-kubernetes --all-containers

## Mitigation

Mitigation for this alert is not possible to understand in advance.

If you are seeing that any of the ovnkube-node pods is not in Running status,
you can try to delete the pod and let it being recreated by the daemonset
controller.

    oc delete po <ovnkube-node> -n openshift-ovn-kubernetes

If the issue cannot be fixed by recreating the pod, reboot of the affected node
might be an option to refresh the full stack (include OVS on the node).



------------------------------


Original Filename:  NorthboundStaleAlert.md

# NorthboundStale

## Meaning

This alert is triggered when ovnkube-controller or northbound database processes
in a specific availability domain are not functioning correctly or if
connectivity between them is broken. For OCP clusters at versions 4.13 or
earlier, the availability domain is the entire cluster. For OCP clusters at
versions 4.14 or later, the availability domain is a cluster node.

## Impact

Existing workloads may continue to have connectivity but any additional
workloads will not be provisioned. Any network policy changes will not be
implemented on existing workloads. For OCP clusters at versions 4.13 or earlier
the affected domain is the entire cluster. For OCP clusters at versions 4.14 or
later, the affected domain is only the specific node for which the alert was
fired.

## Fix alerts before continuing

Resolve any alerts that may cause this alert to fire: [Alert
hierarchy](./hierarchy/alerts-hierarchy.svg)

## Diagnosis

Investigate the health of the affected ovnkube-controller or northbound database
processes that run in the `ovnkube-controller` and `nbdb` containers
repectively.

For OCP clusters at versions 4.13 or earlier, the containers run in
ovnkube-master pods:
```shell
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-master
```

For OCP clusters at versions 4.14 or later, the containers run in the
ovnkube-node pod of the affected node, one of:
```shell
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-node -o wide
```

Check the overall status of the affected pods and of its containers:
```shell
oc describe pod/<podname> -n openshift-ovn-kubernetes
```

Check the logs of a specific container:
```shell
oc logs <podname> -n openshift-ovn-kubernetes -c <container>
```
You may need to use `--previous` command with `oc logs` command to get the logs
of the previous execution run of a container. Pay close attention to any log
output starting with "E" for Error.

> NOTE: The checks below only apply for OCP clusters at versions 4.13 or earlier
> where ovnkube-controller remotely connects to a northbound database leader.

Ensure there is an northbound database Leader. To find the database leader, you
can run this script:
```shell
LEADER="not found"; for MASTER_POD in $(oc -n openshift-ovn-kubernetes get pods -l app=ovnkube-master -o=jsonpath='{.items[*].metadata.name}'); do RAFT_ROLE=$(oc exec -n openshift-ovn-kubernetes "${MASTER_POD}" -c nbdb -- bash -c "ovn-appctl -t /var/run/ovn/ovnnb_db.ctl cluster/status OVN_Northbound 2>&1 | grep \"^Role\""); if echo "${RAFT_ROLE}" | grep -q -i leader; then LEADER=$MASTER_POD; break; fi; done; echo "nbdb leader ${LEADER}"
```

If this does not work, exec into each nbdb container on the master pods:
```shell
oc exec -n openshift-ovn-kubernetes -it <podname> -c nbdb --bash
```
and then run:
```shell
ovs-appctl -t /var/run/ovn/ovnnb_db.ctl cluster/status OVN_Northbound
```
You should see a role that will either say leader or follower.

A common cause of database leader issues is that one of the database servers is
unable to participate with the other raft peers due to mismatching cluster ids.
Due to this, they will be unable to elect a database leader.

Check to make sure that the connectivity between ovnkube-master leader and OVN
northbound database leader is healthy.

To determine what node the ovnkube-master leader is on, check the value of
`holderIdentity`:
```shell
oc get lease -n ovn-kubernetes ovn-kubernetes-master -o yaml
```

Then get the logs of the ovnkube-master container on the ovnkube-master pod on
that node:
```shell
oc logs <podname> -n <namespace> -c ovnkube-master
```

You should see a message along the lines of:
```shell
    "msg"="trying to connect" "database"="OVN_Northbound" "endpoint"="tcp:172.18.0.4:6641"
```
This message indicates that the master cannot connect to the database. A
successful connection message will appear in the logs if the master has
connected to the database.

## Mitigation

Mitigation will depend on what was found in the diagnosis section. As a general
fix, you can try restarting the affected pods. Contact the incident response
team in your organisation if fixing the issue is not apparent.



------------------------------


Original Filename:  OVNKubernetesControllerDisconnectedSouthboundDatabase.md

# OVNKubernetesControllerDisconnectedSouthboundDatabase

## Meaning

The `OVNKubernetesControllerDisconnectedSouthboundDatabase` alert is triggered
when the OVN controller is not connected to OVN southbound database
for more than 5 minutes.

## Impact

Networking control plane is degraded on the node. Existing workloads
on the node may continue to have connectivity but any networking configuration
update will not be applied.

## Diagnosis

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire:
[Alert hierarchy](./hierarchy/alerts-hierarchy.svg)

### OVN-kubernetes master pods

> NOTE: This section only applies to OCP 4.13 or earlier releases where the OVN
> southbound database runs in the OVN-kubernetes master pods.

Find ovnkube-master pods.

```shell
pods=($(oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-master \
  -o jsonpath={..metadata.name}))
```

Check the container statuses in ovnkube-master pods.

```shell
for pod in ${pods}
do
  echo "${pod}:\n"
  oc describe pods -n openshift-ovn-kubernetes ${pod}
done
```

Check the sbdb container logs in ovnkube-master pods.

```shell
for pod in ${pods}
do
  echo "${pod}:\n"
  oc logs -n openshift-ovn-kubernetes ${pod} sbdb
done
```

### OVN-kubernetes node pod

Find the ovnkube-node pod running on the affected node.

```shell
pod=$(oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-node \
  -o jsonpath={..metadata.name} --field-selector spec.nodeName=<node>)
```

Check the container statuses in the ovnkube-node pod.

```shell
oc describe po -n openshift-ovn-kubernetes ${pod}
```

Check the southbound database connection status.

```shell
oc exec -n openshift-ovn-kubernetes ${pod} -c ovn-controller -- ovn-appctl connection-status
```

Check the logs of the ovnkube-node container looking for OVN controller error logs.

```shell
oc logs -n openshift-ovn-kubernetes ${pod} -c ovnkube-node
```

Check the logs of the ovn-controller container.

```shell
oc logs -n openshift-ovn-kubernetes ${pod} -c ovn-controller
```

Using tcpdump on the affected node verify the traffic flow to southbound database.

```shell
oc debug node/<node> -- tcpdump -i <primary_interface> tcp and port 9642
```

> NOTE: The previous check only applies for OCP 4.13 or earlier releases where
> the OVN southbound database runs in the OVN-kubernetes master pods.

Check the logs of the sbdb container.

```shell
oc logs -n openshift-ovn-kubernetes ${pod} -c sbdb
```

> NOTE: The previous check only applies for OCP 4.14 or later releases where
> southbound database runs in OVN-kubernetes node pods.

## Mitigation

Mitigation will depend on what was found in the diagnosis section.

If there is no traffic flowing between southbound database and the ovn-controller
it can mean that there are underlying issues in the infrastructure.


------------------------------


Original Filename:  OVNKubernetesNorthdInactive.md

# OVNKubernetesNorthdInactive

## Meaning

This alert fires when there are is no active instance of OVN northd within a
specific availability domain. For OCP clusters at versions 4.13 or earlier, the
availability domain is the entire cluster. For OCP clusters at versions 4.14 or
later, the availability domain is a cluster node.

## Impact

ovn-northd is a daemon that translates the logical network flows from the OVN
Northbound Database into the physical datapath flows in the OVN Southbound
database. If there are no active instances of ovn-northd, then this action will
not occur, which will cause a degraded network. Existing workloads may continue
to have connectivity but any additional workloads will not be provisioned. Any
network policy changes will not be implemented on existing workloads. For OCP
clusters at versions 4.13 or earlier the affected domain is the entire cluster.
For OCP clusters at versions 4.14 or later, the affected domain is only the
specific node for which the alert was fired.

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire: [Alert
hierarchy](./hierarchy/alerts-hierarchy.svg)

## Diagnosis

Investigate the health of the affected ovn-northd processes.

For OCP clusters at versions 4.13 or earlier, the affected ovn-northd processes
run in the northd container of ovnkube-master pods. Find out what those pods are
and exec into them:
```shell
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-master
oc exec -it <ovnkube-master-podname> -c northd -- bash
```

For OCP clusters at versions 4.14 or later, the affected ovn-northd process runs
in the northd container of the ovnkube-node pod for the affected node. Find out
what pod is that and exec into it:
```shell
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-node -o wide
oc exec -it <ovnkube-node-podname> -c northd -- bash
```

Then run:
```shell
curl 127.0.0.1:29105/metrics | grep northd
```
This will show you the cluster metrics associated with northd

Next, check if the northd instance is active:
```shell
ovn-appctl -t ovn-northd status
```
The result should be Status:active


## Mitigation

Mitigation will depend on what was found in the diagnosis section.

As a general fix, you can try exiting the affected ovn-northd procesess with
```shell
ovn-appctl -t ovn-northd exit
```
which should cause the container running northd to restart. If this does not
work you can try restarting the pods where the affected ovn-northd procesess are
running.

Contact the incident response team in your organisation if fixing the issue is
not apparent.



------------------------------


Original Filename:  SouthboundStaleAlert.md

# SouthboundStale

## Meaning

This alert is triggered when northd or southbound database processes in a
specific availability domain are not functioning correctly or if connectivity
between them is broken. For OCP clusters at versions 4.13 or earlier, the
availability domain is the entire cluster. For OCP clusters at versions 4.14 or
later, the availability domain is a cluster node.

## Impact

Existing workloads may continue to have connectivity but any additional
workloads will not be provisioned. Any network policy changes will not be
implemented on existing workloads. For OCP clusters at versions 4.13 or earlier
the affected domain is the entire cluster. For OCP clusters at versions 4.14 or
later, the affected domain is only the specific node for which the alert was
fired.

### Fix alerts before continuing

Resolve any alerts that may cause this alert to fire: [Alert
hierarchy](./hierarchy/alerts-hierarchy.svg)

## Diagnosis

Investigate the health of the affected northd or southbound database processes
that run in the `northd` and `sbdb` containers repectively.

For OCP clusters at versions 4.13 or earlier, the containers run in
ovnkube-master pods:
```shell
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-master
```

For OCP clusters at versions 4.14 or later, the containers run in the
ovnkube-node pod of the affected node, one of:
```shell
oc get pod -n openshift-ovn-kubernetes -l app=ovnkube-node -o wide
```

Check the overall status of the affected pods and of its containers:
```shell
oc describe pod/<podname> -n openshift-ovn-kubernetes
```

Check the logs of a specific container:
```shell
oc logs <podname> -n openshift-ovn-kubernetes -c <container>
```
You may need to use `--previous` command with `oc logs` command to get the logs
of the previous execution run of a container. Pay close attention to any log
output starting with "E" for Error.

If northd is overloaded, there will be logs in the `northd` container along the
lines of `dropped x number of log messages due to excessive rate` or a message
that contains `(99% CPU usage)` or some other high percentage CPU usage.

You can also check the cpu usage of the container by logging into your openshift
cluster console. In the Observe section on the sidebar, click metrics, then
run this query `container_cpu_usage_seconds_total{pod="$PODNAME",
container="$CONTAINERNAME"}`

> NOTE: The checks below only apply for OCP clusters at versions 4.13 or earlier
> where ovn-northd remotely connects to a southbound database leader.

Ensure there is an sourthbound database Leader. To find the database leader, you
can run this script:
```shell
LEADER="not found"; for MASTER_POD in $(oc -n openshift-ovn-kubernetes get pods -l app=ovnkube-master -o=jsonpath='{.items[*].metadata.name}'); do RAFT_ROLE=$(oc exec -n openshift-ovn-kubernetes "${MASTER_POD}" -c sbdb -- bash -c "ovn-appctl -t /var/run/ovn/ovnsb_db.ctl cluster/status OVN_Southbound 2>&1 | grep \"^Role\""); if echo "${RAFT_ROLE}" | grep -q -i leader; then LEADER=$MASTER_POD; break; fi; done; echo "sbdb leader ${LEADER}"
```

If this does not work, exec into each sbdb container on the master pods:
```shell
oc exec -n openshift-ovn-kubernetes -it <podname> -c sbdb -- bash
```
and then run:
```shell
ovs-appctl -t /var/run/ovn/ovnsb_db.ctl cluster/status OVN_Southbound
```
You should see a role that will either say leader or follower.

A common cause of database leader issues is that one of the database servers is
unable to participate with the other raft peers due to mismatching cluster ids.
Due to this, they will be unable to elect a database leader.

## Mitigation

Mitigation will depend on what was found in the diagnosis section. As a general
fix, you can try restarting the affected pods. Contact the incident response
team in your organisation if fixing the issue is not apparent.



------------------------------


Original Filename:  V4SubnetAllocationThresholdExceeded.md

# V4SubnetAllocationThresholdExceeded

## Meaning

The `V4SubnetAllocationThresholdExceeded` alert is triggered when more than
80% of subnets for nodes are allocated.

## Impact

This is a warning alert. No immediate impact to the cluster will be observed if
this alert fires and it is a warning to be mindful of your remaining node
subnet allocation. If your remaining subnets are exhausted, then no
further nodes can be added to your cluster.

## Diagnosis

Check the network configuration on the cluster.

    oc get networks.config.openshift.io/cluster -o jsonpath='{.spec.clusterNetwork}'

    [{"cidr":"10.128.0.0/14","hostPrefix":23}]

Calculate the IPv4 subnets capability.

    subnet_capability = 2^[(32 - clusternetwork_netmask) - (32 - hostPrefix)]

It will be 512 if the CIDR netmask is `/14` and hostPrefix is `23`, that means
the cluster can have at most 512 nodes.

Count the number of nodes to compare.

    oc get node --no-headers | wc -l

## Mitigation

We do not support adding additional cluster networks for ovn-kubernetes.

User will have to create a new cluster for more worker nodes.

Choosing a larger cluster network CIDR which can hold more subnets could prevent
this happening.



------------------------------



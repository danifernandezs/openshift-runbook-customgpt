Original Filename:  GarbageCollectorSyncFailed.md

# GarbageCollectorSyncFailed

## Meaning

[This alert][GarbageCollectorSyncFailed] is fired when some resources couldn't
be reached for a garbage collector informer cache. This usually happens due to
the failing conversion webhook of an installed `CustomResourceDefinition` (CRD)
or because of failing API Discovery, unreachable API server or problems with a
network.

## Impact

Garbage collection and orphaning of objects stops working. Normal deletion
works fine, but deletion of objects via owner references does not.
Deletion of an object with `--cascade=orphan` option also does not work.

This can lead to resource exhaustion or/and etcd pollution
when objects are not garbage collected.

For example:
- deletion of replica set will not delete its pods and the pods will keep
  running
- cron job with history limit that create new jobs will delete old jobs,
  but it will lead to leaving completed pods behind

In extreme cases this can lead to cluster failure.


## Diagnosis

Analyze logs of `kube-controller-manager` pods in
`openshift-kube-controller-manager` namespace.

```console
$ oc get pods -n openshift-kube-controller-manager
$ oc logs -n openshift-kube-controller-manager $POD
```

Look for lines with `garbagecollector` or `garbage` words.
You should see something similar to this.

```text
shared_informer.go:258] unable to sync caches for garbage collector
garbagecollector.go:245] timed out waiting for dependency graph builder sync during GC sync (attempt 26)
garbagecollector.go:215] syncing garbage collector with updated resources from discovery (attempt 27): added: [example.com/v1, Resource=myresource], removed: []
```

If you cannot identify the failing resource,
increase the log level to get more information.

```console
$ oc patch kubecontrollermanagers.operator/cluster --type=json -p '[{"op": "replace", "path": "/spec/logLevel", "value": "LOGLEVEL" }]'
```

After the kube-controller-manager pods restart,
you should find following messages in logs.

```console
graph_builder.go:279] garbage controller monitor not yet synced: example.com/v1, Resource=myresource
```


## Mitigation

Debug your CRD (in this example `myresource.example.com`) to see what is wrong.
Fix or disable the conversion webhooks of your CRD to get garbage collector
back to functioning state. You can also remove the CRD in case you are not
using it. Usually this is caused by improper CRD installation or upgrade.
For more details see [Versions in CRDs][VersionsCustomResourceDefinitions].

You might also see network errors in kube-controller-manager logs.
In that case there is probably an issue with your infrastructure.

[GarbageCollectorSyncFailed]: https://github.com/openshift/cluster-kube-controller-manager-operator/blob/20179ecfa3b8c5e766a21c98107f45b84196b914/manifests/0000_90_kube-controller-manager-operator_05_alerts.yaml#L42-L50
[VersionsCustomResourceDefinitions]: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/


------------------------------


Original Filename:  KubeControllerManagerDown.md

# KubeControllerManagerDown

## Meaning

[This alert][KubeControllerManagerDown] is fired when KubeControllerManager
has disappeared from Prometheus target discovery.
This means there is no running or properly functioning
instance of [kube-controller-manager][kube-controller-manager].

## Impact

Many features stop working when kube-controller-manager is down.

This includes:
- workload controllers (Deployment, ReplicaSet, DaemonSet, ...)
- resource quotas
- pod disruption budgets
- garbage collection
- certificate signing requests
- service accounts, tokens
- storage
- nodes' statuses and taints
- SCCs
- and more...


## Diagnosis

To see an operator status of kube-controller-manager.

```console
$ oc get clusteroperators.config.openshift.io kube-controller-manager
```

Take a look at `KubeControllerManager`'s `.status.conditions` and
also see what is the current state of each instance of kube-controller-manager
on each node in `.status.nodeStatuses`.

```console
$ oc get -o yaml kubecontrollermanagers.operator.openshift.io cluster
```

See operator events.

```console
$ oc get events -n openshift-kube-controller-manager-operator
```

Look at the operator pod and inspect its logs.

```console
$ oc get pods -n openshift-kube-controller-manager-operator
$ oc logs -n openshift-kube-controller-manager-operator $POD_NAME
```

You can do the same with kube-controller-manager.

See kube-controller-manager events.

```console
$ oc get events -n openshift-kube-controller-manager
```

Look at kube-controller-manager pods and inspect their logs.

```console
$ oc get pods -n openshift-kube-controller-manager
$ oc logs -n openshift-kube-controller-manager $POD_NAME
```


## Mitigation

The resolution depends on the particular issue reported in the statuses,
events and logs.


[KubeControllerManagerDown]: https://github.com/openshift/cluster-kube-controller-manager-operator/blob/20179ecfa3b8c5e766a21c98107f45b84196b914/manifests/0000_90_kube-controller-manager-operator_05_alerts.yaml#L14-L23
[kube-controller-manager]: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/


------------------------------


Original Filename:  PodDisruptionBudgetAtLimit.md

# PodDisruptionBudgetAtLimit

## Meaning

[This alert][PodDisruptionBudgetAtLimit] is fired when the pod disruption
budget is at the minimum disruptions allowed level.
This level is defined by `.spec.minAvailable` or `.spec.maxUnavailable` in
the `PodDisruptionBudget` object.
The number of current healthy pods is equal to the desired healthy pods.

It does not fire when the number of expected pods is 0.


## Impact

the application protected by the pod disruption budget has a sufficient amount
of pods, but is at risk of getting disrupted.

Standard workloads should have at least one pod more than is desired to support
[API-initiated eviction][APIEviction]. Workloads that are at the minimum
disruption allowed level violate this and could block node drain.
This is important for node maintenance and cluster upgrades.

## Diagnosis

Discover the pod disruption budgets that are triggering the alert.

```console
max by(namespace, poddisruptionbudget) (
    kube_poddisruptionbudget_status_current_healthy == kube_poddisruptionbudget_status_desired_healthy
      and on (namespace, poddisruptionbudget) kube_poddisruptionbudget_status_expected_pods > 0
)
```

Look at the [pod disruption budget][SpecifyingPDB] detail.

```console
$ oc get poddisruptionbudgets -o yaml -n $NS $PDB_NAME
```

Look at events for reasons why your extra pods might not be healthy.

```console
$ oc get events -n $NS
```


## Mitigation

Get the selector from the pod disruption budget YAML and see if there are
any extra pods of this application that are not healthy.
You can debug these pods to find a reason why.

```console
$ oc get pods -n $NS --selector="app=myapp"
```

In general ensure you have enough resource for running your pods.
You can also take a look at potential reasons
for [pod disruptions][PodDisruptions].

Finally, take a look at the owner references of these pods to either change
the pod YAML or number of replicas in the parent workload resource to fix
the issue.


[PodDisruptionBudgetAtLimit]: https://github.com/openshift/cluster-kube-controller-manager-operator/blob/20179ecfa3b8c5e766a21c98107f45b84196b914/manifests/0000_90_kube-controller-manager-operator_05_alerts.yaml#L24-L32
[PodDisruptions]: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
[SpecifyingPDB]: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
[APIEviction]: https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/



------------------------------


Original Filename:  PodDisruptionBudgetLimit.md

# PodDisruptionBudgetLimit

## Meaning

[This alert][PodDisruptionBudgetLimit] is fired when the pod disruption budget
is below the minimum disruptions allowed level and is not satisfied.
This level is defined by `.spec.minAvailable` or `.spec.maxUnavailable` in
the `PodDisruptionBudget` object.
The number of current healthy pods is less than the desired healthy pods.


## Impact

The application protected by the pod disruption budget has an insufficient
amount of pods.
This means the application is either not running at all or running with
suboptimal number of pods.
This can have various impact depending on the type and importance of such
application.

Standard workloads should have at least one pod more than is desired to support
[API-initiated eviction][APIEviction]. Workloads that are below the minimum
disruption allowed level violate this and could block node drain.
This is important for node maintenance and cluster upgrades.


## Diagnosis

Discover the pod disruption budgets that are triggering the alert.

```console
max by(namespace, poddisruptionbudget) (
    kube_poddisruptionbudget_status_current_healthy < kube_poddisruptionbudget_status_desired_healthy
)
```

Look at the [pod disruption budget][SpecifyingPDB] detail to see how many pods
are healthy and how many are desired.

```console
$ oc get poddisruptionbudgets -o yaml -n $NS $PDB_NAME
```

Look at events for reasons why your pods are not healthy.

```console
$ oc get events -n $NS
```


## Mitigation

Get the selector from the pod disruption budget YAML and debug the pods
of the application to find a reason why they are not healthy.

```console
$ oc get pods -n $NS --selector="app=myapp"
```

In general ensure you have enough resource for running your pods.
You can also take a look at potential reasons
for [pod disruptions][PodDisruptions].

Finally, take a look at the owner references of these pods to either change
the pod YAML or number of replicas in the parent workload resource to fix
the issue.


[PodDisruptionBudgetLimit]: https://github.com/openshift/cluster-kube-controller-manager-operator/blob/20179ecfa3b8c5e766a21c98107f45b84196b914/manifests/0000_90_kube-controller-manager-operator_05_alerts.yaml#L33-L41
[PodDisruptions]: https://kubernetes.io/docs/concepts/workloads/pods/disruptions/
[SpecifyingPDB]: https://kubernetes.io/docs/tasks/run-application/configure-pdb/
[APIEviction]: https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/



------------------------------



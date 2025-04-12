# OrphanedVirtualMachineInstances

## Meaning

This alert fires when a virtual machine instance (VMI), or `virt-launcher` pod,
runs on a node that does not have a running `virt-handler` pod. Such a VMI is
called _orphaned_.

## Impact

Orphaned VMIs cannot be managed.

## Diagnosis

1. Set the `NAMESPACE` environment variable:

   ```bash
   $ export NAMESPACE="$(oc get kubevirt -A -o jsonpath='{.items[].metadata.namespace}')"
   ```

2. Check the status of the `virt-handler` pods to view the nodes on which they
are running:

   ```bash
   $ oc get pods -n $NAMESPACE -o wide -l kubevirt.io=virt-handler
   ```

3. Check the status of the VMIs to identify VMIs running on nodes that do not
have a running `virt-handler` pod:

   ```bash
   $ oc get vmis -n $NAMESPACE
   ```

4. Check the status of the `virt-handler` daemonset:

   ```bash
   $ oc get daemonsets -n $NAMESPACE -l kubevirt.io=virt-handler
   ```

   Example output:

   ```text
   NAME                  DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
   virt-handler          2         2         2       2            2           kubernetes.io/os=linux   4h
   ```

   The daemon set is considered healthy if the `Desired`, `Ready`, and
   `Available` columns contain the same value.

5. If the `virt-handler` daemon set is not healthy, check the `virt-handler`
daemon set for pod deployment issues:

   ```bash
   $ oc get daemonsets -n $NAMESPACE -o json | jq '.items[] | select(.metadata.name=="virt-handler") | .status'
   ```

6. Check the nodes for issues such as a `NotReady` status:

   ```bash
   $ oc get nodes
   ```

7. Check the `spec.workloads` stanza of the `KubeVirt` custom resource (CR) for
a workloads placement policy:

   ```bash
   $ oc get kubevirt -n $NAMESPACE -o yaml
   ```

## Mitigation

If a workloads placement policy is configured, add the node with the VMI to the
policy.

Possible causes for the removal of a `virt-handler` pod from a node include
changes to the node's taints and tolerations or to a pod's scheduling rules.

Try to identify the root cause and resolve the issue.

If you cannot resolve the issue, log in to the
[Customer Portal](https://access.redhat.com) and open a support case,
attaching the artifacts gathered during the diagnosis procedure.
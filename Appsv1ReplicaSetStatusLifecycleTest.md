# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining ReplicaSet endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%ReplicaSetStatus'
      order by kind, endpoint desc
      limit 10;
```

```example
                  endpoint                 |                              path                              |    kind
  -----------------------------------------+----------------------------------------------------------------+------------
   replaceAppsV1NamespacedReplicaSetStatus | /apis/apps/v1/namespaces/{namespace}/replicasets/{name}/status | ReplicaSet
   readAppsV1NamespacedReplicaSetStatus    | /apis/apps/v1/namespaces/{namespace}/replicasets/{name}/status | ReplicaSet
   patchAppsV1NamespacedReplicaSetStatus   | /apis/apps/v1/namespaces/{namespace}/replicasets/{name}/status | ReplicaSet
  (3 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Workload Resources / ReplicaSet](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/replica-set-v1/)
-   [client-go - ReplicaSet](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/replicaset.go)


# The mock test


## Test outline

1.  Create a watch to track replica set events

2.  Create a replica set with a static label. Confirm that the pods are running.

3.  Get the replica set status. Parse the response and confirm that the replica set status conditions can be listed.

4.  Update the replica set status. Confirm via the watch that the status has been updated.

5.  Patch the replica set status. Confirm via the watch that the status has been patched.


## Test the functionality in Go

Using an existing [status lifecycle test](https://github.com/ii/kubernetes/blob/ca3aa6f5af1b545b116b52c717b866e43c79079b/test/e2e/apps/daemon_set.go#L812-L947) as a template for a new [ginkgo test](https://github.com/ii/kubernetes/blob/replicaset-status-test/test/e2e/apps/replica_set.go#L513-L642) for daemon set lifecycle test. Due to a test flake with patching the replica set status conditions the final &ldquo;watch/validation&rdquo; check is still be written.


## Test Flake


### Patching the replica set causes test failure

    [It] should validate Replicaset Status endpoints
      /home/ii/go/src/k8s.io/kubernetes/test/e2e/apps/replica_set.go:155
    Apr  6 15:16:30.093: INFO: labels: name=sample-pod,pod=httpd
    STEP: Create a ReplicaSet
    STEP: Verify that the required pods have come up.
    Apr  6 15:16:30.099: INFO: Pod name sample-pod: Found 0 pods out of 1
    Apr  6 15:16:35.108: INFO: Pod name sample-pod: Found 1 pods out of 1
    STEP: ensuring each pod is running
    STEP: Getting /status
    Apr  6 15:16:35.136: INFO: ReplicaSet test-rs has Conditions: []
    Apr  6 15:16:35.136: INFO: ReplicaSet test-rs Status.Replicas: 1
    Apr  6 15:16:35.136: INFO: ReplicaSet test-rs Status.ReadyReplicas: 1
    Apr  6 15:16:35.136: INFO: ReplicaSet test-rs Status.AvailableReplicas: 1
    STEP: updating the ReplicaSet Status
    Apr  6 15:16:35.147: INFO: updatedStatus.Conditions: []v1.ReplicaSetCondition{v1.ReplicaSetCondition{Type:"StatusUpdate", Status:"True", LastTransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:0, loc:(*time.Location)(nil)}}, Reason:"E2E", Message:"Set from e2e test"}}
    STEP: watching for the daemon set status to be updated
    Apr  6 15:16:35.149: INFO: Observed event: ADDED
    Apr  6 15:16:35.149: INFO: Observed event: MODIFIED
    Apr  6 15:16:35.149: INFO: Observed event: MODIFIED
    Apr  6 15:16:35.149: INFO: Observed event: MODIFIED
    Apr  6 15:16:35.149: INFO: Found replica set test-rs in namespace replicaset-2037 with labels: map[name:sample-pod pod:httpd] annotations: map[] & Conditions: [{StatusUpdate True 0001-01-01 00:00:00 +0000 UTC E2E Set from e2e test}]
    Apr  6 15:16:35.149: INFO: Replica set test-rs has an updated status
    STEP: get ReplicaSet state
    Apr  6 15:16:35.152: INFO: rs1.Conditions: []v1.ReplicaSetCondition{v1.ReplicaSetCondition{Type:"StatusUpdate", Status:"True", LastTransitionTime:v1.Time{Time:time.Time{wall:0x0, ext:0, loc:(*time.Location)(nil)}}, Reason:"E2E", Message:"Set from e2e test"}}
    Apr  6 15:16:35.152: INFO: ReplicaSet test-rs Status.FullyLabeledReplicas: 1
    Apr  6 15:16:35.152: INFO: ReplicaSet test-rs Status.Replicas: 1
    Apr  6 15:16:35.152: INFO: ReplicaSet test-rs Status.ReadyReplicas: 1
    Apr  6 15:16:35.152: INFO: ReplicaSet test-rs Status.AvailableReplicas: 1
    STEP: patching the ReplicaSet Status
    Apr  6 15:16:35.158: FAIL: Failed to patch replica set status. ReplicaSet.apps "test-rs" is invalid: [status.fullyLabeledReplicas: Invalid value: 1: cannot be greater than status.replicas, status.readyReplicas: Invalid value: 1: cannot be greater than status.replicas, status.availableReplicas: Invalid value: 1: cannot be greater than status.replicas]


### Full Stack Trace

    Unexpected error:
        <*errors.StatusError | 0xc00024d4a0>: {
            ErrStatus: {
                TypeMeta: {Kind: "", APIVersion: ""},
                ListMeta: {
                    SelfLink: "",
                    ResourceVersion: "",
                    Continue: "",
                    RemainingItemCount: nil,
                },
                Status: "Failure",
                Message: "ReplicaSet.apps \"test-rs\" is invalid: [status.fullyLabeledReplicas: Invalid value: 1: cannot be greater than status.replicas, status.readyReplicas: Invalid value: 1: cannot be greater than status.replicas, status.availableReplicas: Invalid value: 1: cannot be greater than status.replicas]",
                Reason: "Invalid",
                Details: {
                    Name: "test-rs",
                    Group: "apps",
                    Kind: "ReplicaSet",
                    UID: "",
                    Causes: [
                        {
                            Type: "FieldValueInvalid",
                            Message: "Invalid value: 1: cannot be greater than status.replicas",
                            Field: "status.fullyLabeledReplicas",
                        },
                        {
                            Type: "FieldValueInvalid",
                            Message: "Invalid value: 1: cannot be greater than status.replicas",
                            Field: "status.readyReplicas",
                        },
                        {
                            Type: "FieldValueInvalid",
                            Message: "Invalid value: 1: cannot be greater than status.replicas",
                            Field: "status.availableReplicas",
                        },
                    ],
                    RetryAfterSeconds: 0,
                },
                Code: 422,
            },
        }
        ReplicaSet.apps "test-rs" is invalid: [status.fullyLabeledReplicas: Invalid value: 1: cannot be greater than status.replicas, status.readyReplicas: Invalid value: 1: cannot be greater than status.replicas, status.availableReplicas: Invalid value: 1: cannot be greater than status.replicas]
    occurred

The error looks to be part of the [validation code for replica sets](https://github.com/kubernetes/kubernetes/blob/b0abe89ae259d5e891887414cb0e5f81c969c697/pkg/apis/apps/validation/validation.go#L629-L651). Looking for suggestions on whats likely to be happening and how to best resolve the flake would be appreciated.


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,65) AS useragent
from testing.audit_event
where endpoint ilike '%ReplicaSetStatus%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%'
order by endpoint
limit 10;
```

```example
                endpoint                 |                             useragent
-----------------------------------------+-------------------------------------------------------------------
 patchAppsV1NamespacedReplicaSetStatus   | [sig-apps] ReplicaSet should validate Replicaset Status endpoints
 readAppsV1NamespacedReplicaSetStatus    | [sig-apps] ReplicaSet should validate Replicaset Status endpoints
 replaceAppsV1NamespacedReplicaSetStatus | [sig-apps] ReplicaSet should validate Replicaset Status endpoints
(3 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

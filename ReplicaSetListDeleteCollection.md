# Progress <code>[2/6]</code>

-   APISnoop org-flow :
-   test approval issue : #
-   [X] test pr : #
-   [ ] two weeks soak start date :
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes #

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining ReplicaSet endpoints which are untested.

```sql-mode
SELECT
  endpoint,
  -- k8s_action,
  -- path,
  -- description,
  kind
  FROM testing.untested_stable_endpoint
  where eligible is true
    and endpoint like '%ReplicaSet%'
    and endpoint not like '%Status%'
  order by kind, endpoint desc
  limit 25;
```

```example
                  endpoint                  |    kind
--------------------------------------------|------------
 listAppsV1ReplicaSetForAllNamespaces       | ReplicaSet
 deleteAppsV1CollectionNamespacedReplicaSet | ReplicaSet
(2 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Client-go - ReplicaSet](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/replicaset.go)
-   [workloads-resources/replica-set-v1](https://kubernetes.io/docs/reference/kubernetes-api/workloads-resources/replica-set-v1/)

# The mock test

## Test outline

1.  Create a ReplicaSet
2.  List all Replicasets
3.  DeleteCollection of ReplicaSets
4.  Varify the ReplicaSets have been deleted

## Test the functionality in Go

Using an existing conformance test as a template for a [new ginkgo test](https://github.com/ii/kubernetes/blob/Riaankl-replicaset-list-deletecollection/test/e2e/apps/replica_set.go#L505-L545) which validates that two new endpoints are hit.

# Verifying increase in coverage with APISnoop

### Test to see is new endpoint was hit by the test

```sql-mode
select distinct  endpoint, useragent
from testing.audit_event
where endpoint ilike '%ReplicaSet%'
and useragent like '%ReplicaSet%'
order by endpoint
limit 100;

```

```example
                  endpoint                  |                                                          useragent
--------------------------------------------|------------------------------------------------------------------------------------------------------------------------------
 createAppsV1NamespacedReplicaSet           | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet should list and delete a collection of ReplicaSets
 deleteAppsV1CollectionNamespacedReplicaSet | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet should list and delete a collection of ReplicaSets
 listAppsV1ReplicaSetForAllNamespaces       | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet should list and delete a collection of ReplicaSets
 readAppsV1NamespacedReplicaSet             | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet should list and delete a collection of ReplicaSets
(4 rows)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by 2 points****

This test is also created with the goal of conformance promotion.

---

/sig apps /sig testing /sig architecture /area conformance

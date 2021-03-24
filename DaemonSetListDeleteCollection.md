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
    and endpoint like '%DaemonSet%'
    and endpoint not like '%Status%'
  order by kind, endpoint desc
  limit 25;
```

```example
                 endpoint                  |   kind
-------------------------------------------|-----------
 listAppsV1DaemonSetForAllNamespaces       | DaemonSet
 deleteAppsV1CollectionNamespacedDaemonSet | DaemonSet
(2 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Client-go - DaemonSet](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/daemonset.go)
-   [Workloads-resources/daemon-set-v1](https://kubernetes.io/docs/reference/kubernetes-api/workloads-resources/daemon-set-v1/)

# The mock test

## Test outline

1.  Create a Daemonset
2.  List all DaemonSets
3.  DeleteCollection of DaemonSetss
4.  Varify the DaemonSets have been deleted

## Test the functionality in Go

Using an existing conformance test as a template for a [new ginkgo test](https://github.com/ii/kubernetes/commit/b03858dbc1ba7e57cbe91bdb6c9f9e5c3c07972e) which validates that two new endpoints are hit.

# Verifying increase in coverage with APISnoop

### Test to see is new endpoint was hit by the test

```sql-mode
select distinct  endpoint, useragent
from testing.audit_event
where endpoint ilike '%DaemonSet%'
and useragent like '%DaemonSet%'
order by endpoint
limit 100;

```

```example
                 endpoint                  |                                                              useragent
-------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------
 createAppsV1NamespacedDaemonSet           | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Daemon set [Serial] should list and delete a collection of DaemonSets
 deleteAppsV1CollectionNamespacedDaemonSet | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Daemon set [Serial] should list and delete a collection of DaemonSets
 listAppsV1DaemonSetForAllNamespaces       | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Daemon set [Serial] should list and delete a collection of DaemonSets
 listAppsV1NamespacedDaemonSet             | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Daemon set [Serial] should list and delete a collection of DaemonSets
 readAppsV1NamespacedDaemonSet             | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Daemon set [Serial] should list and delete a collection of DaemonSets
(5 rows)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by 2 points****

This test is also created with the goal of conformance promotion.

---

/sig apps /sig testing /sig architecture /area conformance

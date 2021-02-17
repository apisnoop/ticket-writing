# Progress <code>[2/5]</code>

-   [X] APISnoop org-flow : [ReplicaSetScaleTest.org](https://github.com/cncf/apisnoop/blob/master/tickets/k8s/)
-   [X] test approval issue : [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/)
-   [ ] test pr : kuberenetes/kubernetes#
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#?

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining RESOURCENAME endpoints which are untested.

with this query you can filter untested endpoints by their category and eligiblity for conformance. e.g below shows a query to find all conformance eligible untested,stable,core endpoints

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
  --and category = 'core'
  order by kind, endpoint desc
  limit 25;
```

```example
                  endpoint                  |    kind
--------------------------------------------|------------
 patchAppsV1NamespacedReplicaSet            | ReplicaSet
 listAppsV1ReplicaSetForAllNamespaces       | ReplicaSet
 deleteAppsV1CollectionNamespacedReplicaSet | ReplicaSet
(3 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#-strong-write-operations-replicaset-v1-apps-strong-)
-   [client-go - ReplicaSet](https://pkg.go.dev/k8s.io/kubernetes/test/e2e/framework/replicaset)

# The mock test

## Test outline

1.  Create a ReplicaSet with a static label

2.  Read the ReplicaSet

3.  Scale the ReplicaSet to 2

4.  Patch the ReplicaSetScale

5.  Read the replicaSet to ensure it is Patch

6.  Delete the Namespace and ReplicaSet

### Test the function in Go

Due to the complexity of setting up the resources for APIService we have used the current e2e test as template. It has been extended in a [new ginkgo test](https://github.com/ii/kubernetes/commit/4c95e25f7acfe0e755d535c65fa2d10e852a1cd0) for review.

# Verifying increase coverage with APISnoop

```sql-mode
select distinct  endpoint, useragent
                 -- to_char(to_timestamp(release_date::bigint), ' HH:MI') as time
from testing.audit_event
where endpoint ilike '%ReplicaSet%'
and useragent ilike '%ReplicaSet lifecycle tests%'
-- and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
-- and useragent like 'kubectl%'
order by endpoint
limit 100;

```

```example
             endpoint              |                                              useragent
-----------------------------------|------------------------------------------------------------------------------------------------------
 createAppsV1NamespacedReplicaSet  | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet ReplicaSet lifecycle tests
 patchAppsV1NamespacedReplicaSet   | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet ReplicaSet lifecycle tests
 readAppsV1NamespacedReplicaSet    | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet ReplicaSet lifecycle tests
 replaceAppsV1NamespacedReplicaSet | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] ReplicaSet ReplicaSet lifecycle tests
(4 rows)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by 2 points****

This test is also created with the goal of conformance promotion.

---

/sig testing /sig architecture /sig apps /area conformance

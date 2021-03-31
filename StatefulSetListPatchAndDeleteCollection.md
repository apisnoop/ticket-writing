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
  and endpoint like '%StatefulSet%'
    and endpoint not like '%Status%'
  --and category = 'core'
  order by kind, endpoint desc
  limit 25;
```

```example
                  endpoint                   |    kind
---------------------------------------------|-------------
 patchAppsV1NamespacedStatefulSet            | StatefulSet
 listAppsV1StatefulSetForAllNamespaces       | StatefulSet
 deleteAppsV1CollectionNamespacedStatefulSet | StatefulSet
(3 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#statefulset-v1-apps)
-   [Client-go - StatefulSet](https://github.com/kubernetes/kubernetes/blob/master/staging/src/k8s.io/client-go/kubernetes/typed/apps/v1/statefulset.go)

# The mock test

## Test outline

1.  Create a StatefulSet
2.  Patch the StatefulSet
3.  List all StatefulSet in the namespace
4.  Delete the collection if StatefulSets in the namespace
5.  Verify that all StatefulSet was deleted

### Test the functionality in Go

Due to the complexity of setting up the resources for APIService we have used the current e2e test as template. It has been extended in a [New ginkgo test](https://github.com/ii/kubernetes/commit/95f29fd7fdff91853beb7bae88d3389f257ee02e) for review.

# Verifying increase in coverage with APISnoop

```sql-mode
select distinct  endpoint, useragent
                 -- to_char(to_timestamp(release_date::bigint), ' HH:MI') as time
from testing.audit_event
where endpoint ilike '%StatefulSet%'
and useragent ilike '%StatefulSet%'
-- and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
-- and useragent like 'kubectl%'
order by endpoint
limit 100;

```

```example
                  endpoint                   |                                                                                        useragent
---------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 createAppsV1NamespacedStatefulSet           | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] StatefulSet Basic StatefulSet functionality [StatefulSetBasic] should list, patch and delete a collection of StatefulSets
 deleteAppsV1CollectionNamespacedStatefulSet | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] StatefulSet Basic StatefulSet functionality [StatefulSetBasic] should list, patch and delete a collection of StatefulSets
 listAppsV1NamespacedStatefulSet             | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] StatefulSet Basic StatefulSet functionality [StatefulSetBasic] should list, patch and delete a collection of StatefulSets
 listAppsV1StatefulSetForAllNamespaces       | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] StatefulSet Basic StatefulSet functionality [StatefulSetBasic] should list, patch and delete a collection of StatefulSets
 patchAppsV1NamespacedStatefulSet            | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] StatefulSet Basic StatefulSet functionality [StatefulSetBasic] should list, patch and delete a collection of StatefulSets
 readAppsV1NamespacedStatefulSet             | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] StatefulSet Basic StatefulSet functionality [StatefulSetBasic] should list, patch and delete a collection of StatefulSets
 replaceAppsV1NamespacedStatefulSetStatus    | kube-controller-manager/v1.20.4 (linux/amd64) kubernetes/e87da0b/system:serviceaccount:kube-system:statefulset-controller
(7 rows)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by N points****

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

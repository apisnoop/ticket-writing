# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining DaemonSet endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%DaemonSetStatus'
      order by kind, endpoint desc
      limit 10;
```

```example
                  endpoint                |                             path                              |   kind
  ----------------------------------------+---------------------------------------------------------------+-----------
   replaceAppsV1NamespacedDaemonSetStatus | /apis/apps/v1/namespaces/{namespace}/daemonsets/{name}/status | DaemonSet
   readAppsV1NamespacedDaemonSetStatus    | /apis/apps/v1/namespaces/{namespace}/daemonsets/{name}/status | DaemonSet
   patchAppsV1NamespacedDaemonSetStatus   | /apis/apps/v1/namespaces/{namespace}/daemonsets/{name}/status | DaemonSet
  (3 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Workload Resources / DaemonSet](https://kubernetes.io/docs/reference/kubernetes-api/workloads-resources/daemon-set-v1/)
-   [client-go - DaemonSet](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/daemonset.go)


# The mock test


## Test outline

1.  Create a watch to track daemon set events that DaemonSet with a static label

2.  Create a daemon set with a static label. Confirm that the pods are running.

3.  Get the daemon set status. Parse the response and confirm that the daemon set status conditions can be listed.

4.  Update the daemon set status. Confirm via the watch that the status has been updated.

5.  Patch the daemon set status. Confirm via the watch that the status has been patched.


## Test the functionality in Go

Using an existing [conformance test](https://github.com/kubernetes/kubernetes/blob/cf3374e43491c594071548f68d4357fc9ed537ea/test/e2e/apps/daemon_set.go#L155-L175) as a template for a new [ginkgo test](https://github.com/ii/kubernetes/blob/ca3aa6f5af1b545b116b52c717b866e43c79079b/test/e2e/apps/daemon_set.go#L812-L947) which validates that three new endpoints are hit.


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,75) AS useragent
from testing.audit_event
where endpoint ilike '%DaemonSetStatus%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%'
order by endpoint
limit 10;
```

```example
                endpoint                |                                  useragent
----------------------------------------+-----------------------------------------------------------------------------
 patchAppsV1NamespacedDaemonSetStatus   | [sig-apps] Daemon set [Serial] should verify changes to a daemon set status
 readAppsV1NamespacedDaemonSetStatus    | [sig-apps] Daemon set [Serial] should verify changes to a daemon set status
 replaceAppsV1NamespacedDaemonSetStatus | [sig-apps] Daemon set [Serial] should verify changes to a daemon set status
(3 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

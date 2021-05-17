# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow: [Appsv1DeploymentStatusLifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/Appsv1DeploymentStatusLifecycleTest.org)
-   [ ] Test approval issue: [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/#)
-   [ ] Test PR: kuberenetes/kubernetes#
-   [ ] Two weeks soak start date: testgrid-link
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: kubernetes/kubernetes#?


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining StatefulSet endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%DeploymentStatus'
      order by kind, endpoint desc
      limit 10;
```

```example
                  endpoint                 |                              path                              |    kind
  -----------------------------------------+----------------------------------------------------------------+------------
   replaceAppsV1NamespacedDeploymentStatus | /apis/apps/v1/namespaces/{namespace}/deployments/{name}/status | Deployment
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Workload Resources / Deployment](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)
-   [client-go - Deployment](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/apps/v1/deployment.go)


# The mock test


## Test outline

1.  Create a watch to track deployment events.

2.  Create a deployment with a static label. Confirm that the pods are running.

3.  Get the deployment status. Parse the response and confirm that the deployment status conditions can be listed.

4.  Update the deployment status. Confirm via the watch that the status has been updated.

5.  Patch the deployment status. Confirm via the watch that the status has been patched.


## Test the functionality in Go

Using an existing [status lifecycle test](https://github.com/ii/kubernetes/blob/ca3aa6f5af1b545b116b52c717b866e43c79079b/test/e2e/apps/daemon_set.go#L812-L947) as a template for a new [ginkgo test](https://github.com/ii/kubernetes/blob/deployment-status-test/test/e2e/apps/deployment.go#L487-L621) for deployment lifecycle test.


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,65) AS useragent
from testing.audit_event
where endpoint ilike '%DeploymentStatus%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                endpoint                 |                             useragent
-----------------------------------------+-------------------------------------------------------------------
 patchAppsV1NamespacedDeploymentStatus   | [sig-apps] Deployment should validate Deployment Status endpoints
 readAppsV1NamespacedDeploymentStatus    | [sig-apps] Deployment should validate Deployment Status endpoints
 replaceAppsV1NamespacedDeploymentStatus | [sig-apps] Deployment should validate Deployment Status endpoints
(3 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

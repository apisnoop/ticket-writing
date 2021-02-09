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
  and endpoint like '%DeploymentScale%'
  --and category = 'core'
  order by kind, endpoint desc
  limit 25;
```

```example
                endpoint                | kind
----------------------------------------|-------
 replaceAppsV1NamespacedDeploymentScale | Scale
 readAppsV1NamespacedDeploymentScale    | Scale
 patchAppsV1NamespacedDeploymentScale   | Scale
(3 rows)

```

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#read-scale-deployment-v1-apps)
-   [client-go - Deployment](https://pkg.go.dev/k8s.io/kubernetes/test/e2e/framework/deployment)

# The mock test

## Test outline

1.  Create a Deployment with a static label

2.  Read the Deployment

3.  Update the DeploymentScale

4.  Get the DeploymentScale to ensure it is updated

5.  Patch the DeploymentScale

6.  Read the DeploymentScale to ensure it is Patch

7.  Delete the Namespace and Deployment

### Test the functionality in Go

Due to the complexity of setting up the resources for APIService we have used the current e2e test as template. It has been extended in a [new ginkgo test](https://github.com/ii/kubernetes/blob/7e0d468f06cbee234bbafba3e40c18618b0fccfb/test/e2e/apps/deployment.go#L1484-L1554) for review.

# Verifying increase in coverage with APISnoop

```sql-mode
select distinct  endpoint, useragent
                 -- to_char(to_timestamp(release_date::bigint), ' HH:MI') as time
from testing.audit_event
where endpoint ilike '%DeploymentScale%'
  -- and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
-- and useragent like 'kubectl%'
order by endpoint
limit 100;

```

```example
                endpoint                |                                                          useragent
----------------------------------------|------------------------------------------------------------------------------------------------------------------------------
 patchAppsV1NamespacedDeploymentScale   | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Deployment Deployment should have a working scale subresource
 readAppsV1NamespacedDeploymentScale    | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Deployment Deployment should have a working scale subresource
 replaceAppsV1NamespacedDeploymentScale | e2e.test/v0.0.0 (linux/amd64) kubernetes/$Format -- [sig-apps] Deployment Deployment should have a working scale subresource
(3 rows)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by N points****

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

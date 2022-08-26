# Progress <code>[3/6]</code>

-   [X] APISnoop org-flow: [CoreV1ResourceQuotaStatusTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1ResourceQuotaStatusTest.org)
-   [X] Test approval issue: [#111956](https://issues.k8s.io/111956)
-   [X] Test PR: [#111957](https://pr.k8s.io/111957)
-   [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still three remaining ResourceQuota status endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%ResourceQuota%'
      order by kind, endpoint desc
      limit 10;
```

```example
                    endpoint                  |                            path                             |     kind
  --------------------------------------------+-------------------------------------------------------------+---------------
   replaceCoreV1NamespacedResourceQuotaStatus | /api/v1/namespaces/{namespace}/resourcequotas/{name}/status | ResourceQuota
   readCoreV1NamespacedResourceQuotaStatus    | /api/v1/namespaces/{namespace}/resourcequotas/{name}/status | ResourceQuota
   patchCoreV1NamespacedResourceQuotaStatus   | /api/v1/namespaces/{namespace}/resourcequotas/{name}/status | ResourceQuota
  (3 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Policy Resource / ResourceQuota](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/resource-quota-v1/)
-   [client-go - ResourceQuota](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/resourcequota.go)


# Test outline

```
Feature: Test patch, replace and read ResoureQuota Status api endpoints
```

-   patchCoreV1NamespacedResourceQuotaStatus

```
Scenario: the test patches a ResourceQuota Status
  Given the e2e test has created a resource quota with a set of confirmed hard limits (cpu & memory)
  And a patched status with an updated cpu hard limit
  When the test patches the Resource Quota Status
  Then the requested action is accepted without any error
  And the newly applied status hard limit for cpu is found
```

-   replaceCoreV1NamespacedResourceQuotaStatus

```
Scenario: confirm that the replace action will apply changes to a ResourceQuota Status
  Given the e2e test has a ResourceQuota after the "patch" scenario
  And a new set of hard limits for cpu and memory have been generated
  When the test updates the ResourceQuota
  Then the requested action is accepted without any error
  And the newly applied status hard limits are both found
```

-   readCoreV1NamespacedResourceQuotaStatus

```
Scenario: the test reads a ResourceQuota Status
  Given the e2e test has a ResourceQuota after the "replace" scenario
  When the test reads the ResourceQuota Status
  Then the requested action is accepted without any error
  And the status hard limits are confirmed as unchanged
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-resourcequota-status-test/test/e2e/apimachinery/resource_quota.go#L990-L1075) has been created for 3 ResourceQuota Status endpoints. The e2e logs for this test are listed below.

```
[It] should apply changes to a resourcequota status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/resource_quota.go:990
STEP: Creating a ResourceQuota 08/22/22 14:33:27.541
Aug 22 14:33:27.548: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard cpu limit of 500m
Aug 22 14:33:27.548: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard memory limit of 500Mi
STEP: patching /status 08/22/22 14:33:27.548
Aug 22 14:33:27.554: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard cpu status of 750m
STEP: updating /status 08/22/22 14:33:27.554
Aug 22 14:33:27.561: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard cpu status of 1500m
Aug 22 14:33:27.561: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard memory status of 1000Mi
STEP: get /status 08/22/22 14:33:27.561
Aug 22 14:33:27.565: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard cpu status of 1500m
Aug 22 14:33:27.565: INFO: Resource quota "e2e-quotastatus-44qxm" reports a hard memory status of 1000Mi
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows which Resource Status endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  endpoint, right(useragent,46) AS useragent
from testing.audit_event
where endpoint ilike '%ResourceQuotaStatus'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                  endpoint                  |                   useragent
--------------------------------------------+------------------------------------------------
 patchCoreV1NamespacedResourceQuotaStatus   | should apply changes to a resourcequota status
 readCoreV1NamespacedResourceQuotaStatus    | should apply changes to a resourcequota status
 replaceCoreV1NamespacedResourceQuotaStatus | should apply changes to a resourcequota status
(3 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [CoreV1ResourceQuotaTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1ResourceQuotaTest.org)
- [ ] test approval issue : [#](https://issues.k8s.io/)
- [ ] test pr : [!](https://pr.k8s.io/)
- [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] two weeks soak end date : xxxx-xx-xx
- [ ] test promotion pr : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there is still some remaining ResourceQuota endpoints which are untested.

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
                     endpoint                    |                            path                             |     kind
  -----------------------------------------------+-------------------------------------------------------------+---------------
   replaceCoreV1NamespacedResourceQuotaStatus    | /api/v1/namespaces/{namespace}/resourcequotas/{name}/status | ResourceQuota
   readCoreV1NamespacedResourceQuotaStatus       | /api/v1/namespaces/{namespace}/resourcequotas/{name}/status | ResourceQuota
   patchCoreV1NamespacedResourceQuotaStatus      | /api/v1/namespaces/{namespace}/resourcequotas/{name}/status | ResourceQuota
   patchCoreV1NamespacedResourceQuota            | /api/v1/namespaces/{namespace}/resourcequotas/{name}        | ResourceQuota
   listCoreV1ResourceQuotaForAllNamespaces       | /api/v1/resourcequotas                                      | ResourceQuota
   deleteCoreV1CollectionNamespacedResourceQuota | /api/v1/namespaces/{namespace}/resourcequotas               | ResourceQuota
  (6 rows)

```

The Status endpoints will be addressed in another test.

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API / Policy Resource / ResourceQuota](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/resource-quota-v1/)
- [client-go - ResourceQuota](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/resourcequota.go)

# Test Outline

```
Feature: Test deleteCollection, list(All Namespaces) and patch ResourceQuota api endpoints
```

- listCoreV1ResourceQuotaForAllNamespaces

```
Scenario: the test lists a ResourceQuota
  Given the e2e test has created a ResourceQuota with a label
  When the test lists all ResourceQuotas with a label selector
  Then the requested action is accepted without any error
  And one ResourceQuota is found
```

- patchCoreV1NamespacedResourceQuota

```
Scenario: the test patches a ResourceQuota
  Given the e2e test has a ResourceQuota
  And a payload is created with a new label
  When the test patches the ResourceQuota
  Then the requested action is accepted without any error
  And the newly applied label is found
```

- deleteCoreV1CollectionNamespacedResourceQuota

```
Scenario: the test deletes a ResourceQuota
  Given the e2e test has a ResourceQuota with a label
  When the test deletes the ResourceQuota via deleteCollection with a label selector
  Then the requested action is accepted without any error
  And the ResourceQuota is not found
```

# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-resourcequota-test/test/e2e/apimachinery/resource_quota.go#L922-L971) has been created for pod templates. The e2e logs for this test are listed below.

```
[It] should manage the lifecycle of a ResourceQuota
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/resource_quota.go:922
STEP: Creating a ResourceQuota
STEP: Getting a ResourceQuotaSTEP: Listing all ResourceQuotas with LabelSelector
STEP: Patching the ResourceQuotaSTEP: Deleting a Collection of ResourceQuotas
STEP: Verifying the deleted ResourceQuota
```

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,46) AS useragent
from testing.audit_event
where endpoint ilike '%ResourceQuota%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                   endpoint                    |                   useragent
-----------------------------------------------+------------------------------------------------
 createCoreV1NamespacedResourceQuota           | should manage the lifecycle of a ResourceQuota
 deleteCoreV1CollectionNamespacedResourceQuota | should manage the lifecycle of a ResourceQuota
 listCoreV1ResourceQuotaForAllNamespaces       | should manage the lifecycle of a ResourceQuota
 patchCoreV1NamespacedResourceQuota            | should manage the lifecycle of a ResourceQuota
 readCoreV1NamespacedResourceQuota             | should manage the lifecycle of a ResourceQuota
(5 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

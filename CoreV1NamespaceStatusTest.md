# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [CoreV1NamespaceStatusTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1NamespacedStatusTest.org)
- [ ] test approval issue : [#](https://issues.k8s.io/)
- [ ] test pr : [!](https://pr.k8s.io/)
- [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] two weeks soak end date : xxxx-xx-xx
- [ ] test promotion pr : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there is still some remaining NamespaceStatus endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%NamespaceStatus'
      order by kind, endpoint desc
      limit 10;
```

```example
             endpoint           |               path               |   kind
  ------------------------------+----------------------------------+-----------
   replaceCoreV1NamespaceStatus | /api/v1/namespaces/{name}/status | Namespace
   readCoreV1NamespaceStatus    | /api/v1/namespaces/{name}/status | Namespace
   patchCoreV1NamespaceStatus   | /api/v1/namespaces/{name}/status | Namespace
  (3 rows)

```

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API / Cluster Resources / Namespace](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/namespace-v1/)
- [client-go - Namespace](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/namespace.go)

# Test Outline

```
Feature: Test read and patch NamespaceStatus api endpoints
```

- readCoreV1NamespaceStatus

```
Scenario: the test reads a NamespaceStatus
  Given the e2e test has created a namespace
  When the test reads the NamespaceStatus
  Then the requested action is accepted without any error
  And the NamespaceStatus phase is active
```

- patchCoreV1NamespaceStatus

```
Scenario: the test patches a NamespaceStatus
  Given the e2e test has a namespace
  And a patched status condition is created
  When the test patches the NamespaceStatus
  Then the requested action is accepted without any error
  And the newly applied status condition is found
```

# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-namespace-status-test/test/e2e/apimachinery/namespace.go#L285-L328) has been created for 2 namespace status endpoints. The e2e logs for this test are listed below.

```
[It] should apply changes to a namespace status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/namespace.go:285
STEP: Read namespace status
May  3 09:59:50.308: INFO: status: v1.NamespaceStatus{Phase:"Active", Conditions:[]v1.NamespaceCondition(nil)}
STEP: Patch namespace status
May  3 09:59:50.313: INFO: Status.Condition: v1.NamespaceCondition{Type:"StatusUpdate", Status:"True", LastTransitionTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), Reason:"E2E", Message:"Set from an e2e test"}
```

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,42) AS useragent
from testing.audit_event
where endpoint ilike '%NamespaceStatus'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
          endpoint          |                 useragent
----------------------------+--------------------------------------------
 patchCoreV1NamespaceStatus | should apply changes to a namespace status
 readCoreV1NamespaceStatus  | should apply changes to a namespace status
(2 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow: [ReplicationControllerScaleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1ReplicationControllerScaleTest.org)
-   [ ] Test approval issue: [#](https://issues.k8s.io/)
-   [ ] Test PR: [#](https://pr.k8s.io/)
-   [ ] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/)
-   [ ] Two weeks soak end date:
-   [ ] Test promotion PR: [#](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still two remaining ReplicationControllerScale endpoints which are untested for conformance.

```sql-mode
    select distinct
      endpoint,
      test_hit AS "e2e Test",
      conf_test_hit AS "Conformance Test"
    from public.audit_event
    where endpoint ilike '%Scale'
    and useragent like '%e2e%'
    and not conf_test_hit
    order by endpoint
    limit 10;
```

```example
                       endpoint                      | e2e Test | Conformance Test
  ---------------------------------------------------+----------+------------------
   readCoreV1NamespacedReplicationControllerScale    | t        | f
   replaceCoreV1NamespacedReplicationControllerScale | t        | f
  (2 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Workload Resources / ReplicationController](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/replication-controller-v1/)
-   [client-go - ReplicationController](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/replicationcontroller.go)


# Test outline

```
Feature: Test get and update ReplicationController scale api endpoints
```

-   readCoreV1NamespacedReplicationControllerScale

```
Scenario: confirm the read action for ReplicationControllerScale
  Given the e2e test has created a ReplicationController
  When the test reads the ReplicationControllerScale
  Then the requested action is accepted without any error
  And one replica is found
```

-   replaceCoreV1NamespacedReplicationControllerScale

```
Scenario: confirm that the update action will apply the changes to a ReplicationControllerScale
  Given the e2e test has a ReplicationController after the "read" scenario
  And a new spec.replicas is set
  When the test updates the ReplicationControllerScale
  Then the requested action is accepted without any error
  And the new replicas are found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-replication-controller-scale-test/test/e2e/apps/rc.go#L395-L420) has been created for two ReplicationControllerScale endpoints. The e2e logs for this test are listed below.

```
[It] should get and update a ReplicationController scale
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apps/rc.go:395
STEP: Creating ReplicationController "e2e-rc-nzxj7" 09/20/22 10:58:09.572
Sep 20 10:58:09.587: INFO: Get Replication Controller "e2e-rc-nzxj7" to confirm replicas
Sep 20 10:58:10.590: INFO: Get Replication Controller "e2e-rc-nzxj7" to confirm replicas
Sep 20 10:58:10.598: INFO: Found 1 replicas for "e2e-rc-nzxj7" replication controller
STEP: Getting scale subresource for ReplicationController "e2e-rc-nzxj7" 09/20/22 10:58:10.598
STEP: Updating a scale subresource 09/20/22 10:58:10.602
STEP: Verifying replicas where modified for replication controller "e2e-rc-nzxj7" 09/20/22 10:58:10.618
Sep 20 10:58:10.618: INFO: Get Replication Controller "e2e-rc-nzxj7" to confirm replicas
Sep 20 10:58:11.636: INFO: Get Replication Controller "e2e-rc-nzxj7" to confirm replicas
Sep 20 10:58:11.642: INFO: Found 2 replicas for "e2e-rc-nzxj7" replication controller
```


# Verifying increase in coverage with APISnoop

This query shows which scale endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,51) AS useragent
from testing.audit_event
where endpoint ilike '%Scale%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                     endpoint                      |                      useragent
---------------------------------------------------+-----------------------------------------------------
 readCoreV1NamespacedReplicationControllerScale    | should get and update a ReplicationController scale
 replaceCoreV1NamespacedReplicationControllerScale | should get and update a ReplicationController scale
(2 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

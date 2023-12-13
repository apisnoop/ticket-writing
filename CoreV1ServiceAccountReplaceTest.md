# Progress <code>[6/6]</code>

-   [X] APISnoop org-flow: [CoreV1ServiceAccountReplaceTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1ServiceAccountReplaceTest.org)
-   [X] Test approval issue: [Write e2e test for replaceCoreV1NamespacedServiceAccount - +1 Endpoint #112822](https://issues.k8s.io/112822)
-   [X] Test PR: [Write e2e test for replaceCoreV1NamespacedServiceAccount - +1 Endpoint #112823](https://pr.k8s.io/112823)
-   [X] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should%20update%20a%20ServiceAccount) 5 Oct 2022
-   [X] Two weeks soak end date: 19 Oct 2022
-   [X] Test promotion PR: [Promote replaceCoreV1NamespacedServiceAccount test to Conformance - +1 Endpoint #113061](https://pr.k8s.io/113061)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still three remaining LimitRange endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%ServiceAccount%'
      order by kind, endpoint desc
      limit 10;
```

```example
                 endpoint                |                         path                          |      kind
  ---------------------------------------+-------------------------------------------------------+----------------
   replaceCoreV1NamespacedServiceAccount | /api/v1/namespaces/{namespace}/serviceaccounts/{name} | ServiceAccount
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Authentication Resources / ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
-   [client-go - ServiceAccount](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/serviceaccount.go)


# Test outline

```
Feature: Test replace ServiceAccount api endpoint
```

-   replaceCoreV1NamespacedServiceAccount

```
Scenario: confirm that the replace action will apply to a ServiceAccount
  Given the e2e test has created a ServiceAccount
  And AutomountServiceAccountToken setting is updated to true from false
  When the test updates the ServiceAccount
  Then the requested action is accepted without any error
  And the AutomountServiceAccountToken is found to be true
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-service-account-replace-test/test/e2e/auth/service_accounts.go#L803-L833) has been created for one ServiceAccount endpoint. The e2e logs for this test are listed below.

```
[It] should update a ServiceAccount
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/auth/service_accounts.go:803
STEP: Creating ServiceAccount "e2e-sa-kdl2c"  10/03/22 12:36:45.522
Oct  3 12:36:45.527: INFO: AutomountServiceAccountToken: false
STEP: Updating ServiceAccount "e2e-sa-kdl2c"  10/03/22 12:36:45.527
Oct  3 12:36:45.533: INFO: AutomountServiceAccountToken: true
```


# Verifying increase in coverage with APISnoop

This query shows which ServiceAccount endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,30) AS useragent
from testing.audit_event
where endpoint ilike '%ServiceAccount%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
               endpoint                |           useragent
---------------------------------------+--------------------------------
 createCoreV1NamespacedServiceAccount  | should update a ServiceAccount
 listCoreV1NamespacedServiceAccount    | should update a ServiceAccount
 readCoreV1NamespacedServiceAccount    | should update a ServiceAccount
 replaceCoreV1NamespacedServiceAccount | should update a ServiceAccount
(4 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

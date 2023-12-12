# Progress <code>[6/6]</code>

-   [X] APISnoop org-flow: [CoreV1LimitRangeTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1LimitRangeTest.org)
-   [X] Test approval issue: [112429](https://issues.k8s.io/112429)
-   [X] Test PR: [#112430](https://pr.k8s.io/112430)
-   [X] Two weeks soak start date: [testgrid-link](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.list,.patch.and.delete.a.LimitRange.by.collection) 4 Oct 2022
-   [X] Two weeks soak end date: 18 Oct 2022
-   [X] Test promotion PR: [Promote List, Patch and Delete LimitRange test to Conformance - +3 Endpoints #113060](https://pr.k8s.io/113060)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still three remaining LimitRange endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%LimitRange%'
      order by kind, endpoint desc
      limit 10;
```

```example
                    endpoint                  |                       path                        |    kind
  --------------------------------------------+---------------------------------------------------+------------
   patchCoreV1NamespacedLimitRange            | /api/v1/namespaces/{namespace}/limitranges/{name} | LimitRange
   listCoreV1LimitRangeForAllNamespaces       | /api/v1/limitranges                               | LimitRange
   deleteCoreV1CollectionNamespacedLimitRange | /api/v1/namespaces/{namespace}/limitranges        | LimitRange
  (3 rows)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Policy Resource / LimitRange](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/limit-range-v1/)
-   [client-go - LimitRange](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/limitrange.go)


# Test outline

```
Feature: Test list(All Namespaces), patch and deleteCollection LimitRange api endpoints
```

-   listCoreV1LimitRangeForAllNamespaces

```
Scenario: confirm that the list action for all namespaces will apply to a LimitRange
  Given the e2e test has created a LimitRange with a label
  When the test lists all LimitRanges with a label selector
  Then the requested action is accepted without any error
  And one LimitRange is found
```

-   patchCoreV1NamespacedLimitRange

```
Scenario: confirm that the patch action will apply the changes to a LimitRange
  Given the e2e test has a LimitRange after the "list" scenario
  And a valid payload has been created
  When the test patches the LimitRange
  Then the requested action is accepted without any error
  And the newly applied changes are found
```

-   deleteCoreV1CollectionNamespacedLimitRange

```
Scenario: confirm that the deleteCollection action will remove a LimitRange
  Given the e2e test has a LimitRange after the "patch" scenario
  When the test applies the deleteCollection action with a labelSelector
  Then the requested action is accepted without any error
  And the LimitRange with the label is not found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-limitrange-test/test/e2e/scheduling/limit_range.go#L229-L311) has been created for three LimitRange endpoints. The e2e logs for this test are listed below.

```
[It] should ensure that a limitRange can be listed, patched and deleted by collection
  /home/heyste/go/src/k8s.io/kubernetes/test/e2e/scheduling/limit_range.go:229
STEP: Creating LimitRange "e2e-limitrange-s69c5" 09/14/22 10:47:30.685
STEP: Listing all LimitRanges with label "e2e-limitrange-s69c5=created" 09/14/22 10:47:30.711
Sep 14 10:47:30.716: INFO: Found limitRange "e2e-limitrange-s69c5" in namespace "limitrange-8238"
STEP: Patching LimitRange "e2e-limitrange-s69c5" 09/14/22 10:47:30.716
Sep 14 10:47:30.733: INFO: LimitRange "e2e-limitrange-s69c5" has been patched
STEP: Delete LimitRange "e2e-limitrange-s69c5" by Collection with labelSelector: "e2e-limitrange-s69c5=patched" 09/14/22 10:47:30.733
STEP: Confirm that the limitRange "e2e-limitrange-s69c5" has been deleted 09/14/22 10:47:30.782
Sep 14 10:47:30.783: INFO: Requesting list of LimitRange to confirm quantity
Sep 14 10:47:30.784: INFO: Found 0 LimitRange with label "e2e-limitrange-s69c5=patched"
Sep 14 10:47:30.784: INFO: LimitRange "e2e-limitrange-s69c5" has been deleted.
```


# Verifying increase in coverage with APISnoop

This query shows which LimitRange endpoints are hit within a short period of running this e2e test

```sql-mode
select distinct  substring(endpoint from '\w+') AS endpoint,
                 right(useragent,80) AS useragent
from testing.audit_event
where endpoint ilike '%LimitRange%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
                  endpoint                  |                                    useragent
--------------------------------------------+----------------------------------------------------------------------------------
 createCoreV1NamespacedLimitRange           | should ensure that a limitRange can be listed, patched and deleted by collection
 deleteCoreV1CollectionNamespacedLimitRange | should ensure that a limitRange can be listed, patched and deleted by collection
 listCoreV1LimitRangeForAllNamespaces       | should ensure that a limitRange can be listed, patched and deleted by collection
 listCoreV1NamespacedLimitRange             | should ensure that a limitRange can be listed, patched and deleted by collection
 patchCoreV1NamespacedLimitRange            | should ensure that a limitRange can be listed, patched and deleted by collection
(5 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

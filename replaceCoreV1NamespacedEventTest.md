# Progress <code>[6/6]</code>

-   [X] APISnoop org-flow: [replaceCoreV1NamespacedEventTest.org](https://github.com/apisnoop/ticket-writing/blob/master/replaceCoreV1NamespacedEventTest.org)
-   [X] test approval issue: [#110797](https://issues.k8s.io/110797)
-   [X] test pr: [#110798](https://pr.k8s.io/110798)
-   [X] two weeks soak start date: [1 July 2022](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.manage.the.lifecycle.of.an.event)
-   [X] two weeks soak end date: 15 July 2022
-   [X] test promotion pr: [#110797](https://pr.k8s.io/110797)


# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still a single remaining Event endpoint which is untested.

```sql-mode
  select
    endpoint,
    path,
    kind
  from testing.untested_stable_endpoint
  where eligible is true
  and endpoint ilike '%Event%'
  order by kind, endpoint desc
  limit 10;
```

```example
             endpoint           |                     path                     | kind
  ------------------------------+----------------------------------------------+-------
   replaceCoreV1NamespacedEvent | /api/v1/namespaces/{namespace}/events/{name} | Event
  (1 row)

```


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API > Cluster Resources > Event](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/)
-   [client-go: core/v1/event.go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/event.go#L42-L54)


# Test outline

```
Feature: Test replace Event api endpoint
```

-   replaceCoreV1NamespacedEvent

```
Scenario: the test updates an event
  Given the e2e test has an event
  And a new event series has been created
  When the test updates the event
  Then the requested action is accepted without any error
  And a newly fetched copy passes and equality check with the current event
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-event-lifecycle-test/test/e2e/instrumentation/core_events.go#L135-L242) has been created for this pod status endpoint. The e2e logs for this test are listed below.

```
[It] should manage the lifecycle of an event
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/instrumentation/core_events.go:135
STEP: creating a test event
STEP: listing all events in all namespaces
STEP: patching the test event
STEP: fetching the test event
STEP: updating the test event
STEP: getting the test event
STEP: deleting the test event
STEP: listing all events in all namespaces
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the updated e2e test

This query shows the event endpoints hit within a short period of running the e2e test.

```sql-mode
select distinct  endpoint, right(useragent,39) AS useragent
from testing.audit_event
where endpoint ilike '%Event%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
            endpoint             |                useragent
---------------------------------+-----------------------------------------
 createCoreV1NamespacedEvent     | should manage the lifecycle of an event
 deleteCoreV1NamespacedEvent     | should manage the lifecycle of an event
 listCoreV1EventForAllNamespaces | should manage the lifecycle of an event
 patchCoreV1NamespacedEvent      | should manage the lifecycle of an event
 readCoreV1NamespacedEvent       | should manage the lifecycle of an event
 replaceCoreV1NamespacedEvent    | should manage the lifecycle of an event
(6 rows)

```


# Final notes

If a test with these calls gets merged, test coverage will go up by 1 point.

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

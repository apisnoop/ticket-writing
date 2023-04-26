# Progress <code>[1/6]</code>

-   [ ] APISnoop org-flow : [confirmAPIResourcesTest.org](https://github.com/apisnoop/ticket-writing/blob/master/confirmAPIResourcesTest.org)
-   [ ] test approval issue : [#](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop

According to following two APIsnoop queries, there are still 12 APIResources endpoints that are not tested for Conformance.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%APIResources'
      order by kind, endpoint
      limit 20;
```

```example
               endpoint             |               path               | kind
  ----------------------------------+----------------------------------+------
   getApiregistrationV1APIResources | /apis/apiregistration.k8s.io/v1/ |
   getAuthenticationV1APIResources  | /apis/authentication.k8s.io/v1/  |
   getAuthorizationV1APIResources   | /apis/authorization.k8s.io/v1/   |
   getAutoscalingV1APIResources     | /apis/autoscaling/v1/            |
   getAutoscalingV2APIResources     | /apis/autoscaling/v2/            |
   getBatchV1APIResources           | /apis/batch/v1/                  |
   getCoordinationV1APIResources    | /apis/coordination.k8s.io/v1/    |
   getEventsV1APIResources          | /apis/events.k8s.io/v1/          |
   getPolicyV1APIResources          | /apis/policy/v1/                 |
   getSchedulingV1APIResources      | /apis/scheduling.k8s.io/v1/      |
  (10 rows)

```

```sql-mode
  select distinct
    endpoint,
    test_hit AS "e2e Test",
    conf_test_hit AS "Conformance Test"
  from public.audit_event
  where endpoint ilike '%APIResources'
  and useragent like '%e2e%'
  and not conf_test_hit
  order by endpoint
  limit 10;
```

```example
            endpoint           | e2e Test | Conformance Test
  -----------------------------+----------+------------------
   getAppsV1APIResources       | t        | f
   getCoreV1APIResources       | t        | f
  (2 rows)

```

-   <https://apisnoop.cncf.io/1.27.0/stable/apps/getAppsV1APIResources>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/getCoreV1APIResources>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [client-go](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/core/v1)


# Test outline

```
Scenario: When each APIResource is accessed the test will confirm that the required groupVersion and resource are found.

  Given the e2e test has a set of structs to call each APIResource
  When the test requests each APIResource
  Then the requested action is accepted without any error
  And an APIResourceList is returned which contains a groupVersion matching the value from the struct
```

```
  Given the e2e test has an APIResourceList
  When the test searches for a resource from the struct
  Then the resource is found
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-apiresources-test/test/e2e/apimachinery/discovery.go#L161-L273) has been created to address these 12 endpoints. The e2e logs for this test are listed below.

```
[sig-api-machinery] Discovery should locate the groupVersion and a resource within each APIResource
/home/ii/go/src/k8s.io/kubernetes/test/e2e/apimachinery/discovery.go:161
  STEP: Creating a kubernetes client @ 04/26/23 14:13:01.743
  Apr 26 14:13:01.743: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename discovery @ 04/26/23 14:13:01.744
  STEP: Waiting for a default service account to be provisioned in namespace @ 04/26/23 14:13:01.785
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 04/26/23 14:13:01.79
  STEP: Setting up server cert @ 04/26/23 14:13:01.796
  STEP: Requesting APIResourceList from "/apis/apps/v1" @ 04/26/23 14:13:02.244
  STEP: Requesting APIResourceList from "/apis/autoscaling/v1" @ 04/26/23 14:13:02.245
  STEP: Requesting APIResourceList from "/apis/autoscaling/v2" @ 04/26/23 14:13:02.246
  STEP: Requesting APIResourceList from "/apis/apiregistration.k8s.io/v1" @ 04/26/23 14:13:02.247
  STEP: Requesting APIResourceList from "/apis/authentication.k8s.io/v1" @ 04/26/23 14:13:02.247
  STEP: Requesting APIResourceList from "/apis/authorization.k8s.io/v1" @ 04/26/23 14:13:02.248
  STEP: Requesting APIResourceList from "/apis/batch/v1" @ 04/26/23 14:13:02.249
  STEP: Requesting APIResourceList from "/apis/coordination.k8s.io/v1" @ 04/26/23 14:13:02.25
  STEP: Requesting APIResourceList from "/api/v1" @ 04/26/23 14:13:02.25
  STEP: Requesting APIResourceList from "/apis/events.k8s.io/v1" @ 04/26/23 14:13:02.251
  STEP: Requesting APIResourceList from "/apis/policy/v1" @ 04/26/23 14:13:02.252
  STEP: Requesting APIResourceList from "/apis/scheduling.k8s.io/v1" @ 04/26/23 14:13:02.253
  Apr 26 14:13:02.253: INFO: Waiting up to 3m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "discovery-5261" for this suite. @ 04/26/23 14:13:02.255
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following apiresources endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,69) AS useragent
from testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
  and endpoint ilike '%APIResources%'
order by endpoint
limit 20;
```

```example
             endpoint             |                               useragent
----------------------------------+-----------------------------------------------------------------------
 getApiregistrationV1APIResources | should locate the groupVersion and a resource within each APIResource
 getAppsV1APIResources            | should locate the groupVersion and a resource within each APIResource
 getAuthenticationV1APIResources  | should locate the groupVersion and a resource within each APIResource
 getAuthorizationV1APIResources   | should locate the groupVersion and a resource within each APIResource
 getAutoscalingV1APIResources     | should locate the groupVersion and a resource within each APIResource
 getAutoscalingV2APIResources     | should locate the groupVersion and a resource within each APIResource
 getBatchV1APIResources           | should locate the groupVersion and a resource within each APIResource
 getCoordinationV1APIResources    | should locate the groupVersion and a resource within each APIResource
 getCoreV1APIResources            | should locate the groupVersion and a resource within each APIResource
 getEventsV1APIResources          | should locate the groupVersion and a resource within each APIResource
 getPolicyV1APIResources          | should locate the groupVersion and a resource within each APIResource
 getSchedulingV1APIResources      | should locate the groupVersion and a resource within each APIResource
(12 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 12 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

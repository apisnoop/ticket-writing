# Progress <code>[6/6]</code>

-   [X] APISnoop org-flow : [AuthV1SubjectAccessReviewTest.org](https://github.com/apisnoop/ticket-writing/blob/master/AuthV1SubjectAccessReviewTest.org)
-   [X] test approval issue : [Write e2e test for SubjectAccessReview & createAuthorizationV1NamespacedLocalSubjectAccessReview +2 Endpoints #114344](https://issues.k8s.io/114344)
-   [X] test pr : [Write e2e test for SubjectAccessReview & createAuthorizationV1NamespacedLocalSubjectAccessReview +2 Endpoints #114345](https://pr.k8s.io/114345)
-   [X] two weeks soak start date : 16 Dec 2022 [testgrid-link](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.support.SubjectReview.API.operations)
-   [X] two weeks soak end date : 31 Dec 2022
-   [X] test promotion pr : [Promote e2e test for SubjectAccessReview & createAuthorizationV1NamespacedLocalSubjectAccessReview +2 Endpoints #114906](https://pr.k8s.io/114906)


# Identifying an untested feature Using APISnoop

According to following two APIsnoop queries, there are still two authorization endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%SubjectAccessReview%'
      order by kind, endpoint desc
      limit 10;
```

```example
                          endpoint                         |                                      path                                      |           kind
  ---------------------------------------------------------+--------------------------------------------------------------------------------+--------------------------
   createAuthorizationV1NamespacedLocalSubjectAccessReview | /apis/authorization.k8s.io/v1/namespaces/{namespace}/localsubjectaccessreviews | LocalSubjectAccessReview
  (1 row)

```

-   <https://apisnoop.cncf.io/1.25.0/stable/authorization/createAuthorizationV1NamespacedLocalSubjectAccessReview?conformance-only=true>
    
    ```sql-mode
      select distinct
        endpoint,
        test_hit AS "e2e Test",
        conf_test_hit AS "Conformance Test"
      from public.audit_event
      where endpoint ilike '%SubjectAccessReview'
      and useragent like '%e2e%'
      and not conf_test_hit
      order by endpoint
      limit 10;
    ```
    
    ```example
                       endpoint                 | e2e Test | Conformance Test
      ------------------------------------------+----------+------------------
       createAuthorizationV1SubjectAccessReview | t        | f
      (1 row)
    
    ```

-   <https://apisnoop.cncf.io/1.25.0/stable/authorization/createAuthorizationV1SubjectAccessReview?conformance-only=true>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Authorization Resources / LocalSubjectAccessReview](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/local-subject-access-review-v1/)
-   [Kubernetes API / Authorization Resources / SubjectAccessReview](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/subject-access-review-v1/)
-   [client-go - LocalSubjectAccessReview](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/authorization/v1/localsubjectaccessreview.go)
-   [client-go - SubjectAccessReview](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/authorization/v1/subjectaccessreview.go)


# Test outline


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-subjectaccessreview-test/test/e2e/auth/subjectreviews.go#L43-L172) has been created for 2 Authorization endpoints. The e2e logs for this test are listed below.

```
[It] should support SubjectReview API operations
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/auth/subjectreviews.go:43
STEP: Create pod "pod-x6fhh" in namespace "subjectreview-1704" 12/07/22 21:33:12.332
Dec  7 21:33:12.441: INFO: Waiting up to 5m0s for pod "pod-x6fhh" in namespace "subjectreview-1704" to be "running"
Dec  7 21:33:12.502: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 61.265222ms
Dec  7 21:33:14.512: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 2.070783878s
Dec  7 21:33:16.520: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 4.078677494s
Dec  7 21:33:18.513: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 6.07168643s
Dec  7 21:33:20.510: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 8.068598657s
Dec  7 21:33:22.509: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 10.068442532s
Dec  7 21:33:24.514: INFO: Pod "pod-x6fhh": Phase="Pending", Reason="", readiness=false. Elapsed: 12.073076728s
Dec  7 21:33:26.511: INFO: Pod "pod-x6fhh": Phase="Running", Reason="", readiness=true. Elapsed: 14.069523123s
Dec  7 21:33:26.511: INFO: Pod "pod-x6fhh" satisfied condition "running"
Dec  7 21:33:26.515: INFO: "pod-x6fhh" in namespace "subjectreview-1704" is "Running"
Dec  7 21:33:26.515: INFO: serviceaccount name: "system:serviceaccount:subjectreview-1704:default"
STEP: Creating SubjectAccessReview in "subjectreview-1704" namespace 12/07/22 21:33:26.515
Dec  7 21:33:26.521: INFO: sarResponse Status: v1.SubjectAccessReviewStatus{Allowed:false, Denied:false, Reason:"", EvaluationError:""}
STEP: Creating clientset to impersonate "system:serviceaccount:subjectreview-1704:default" 12/07/22 21:33:26.521
STEP: Verifying api 'get' call to "pod-x6fhh" as "system:serviceaccount:subjectreview-1704:default" 12/07/22 21:33:26.522
Dec  7 21:33:26.525: INFO: api call by "system:serviceaccount:subjectreview-1704:default" was denied
Dec  7 21:33:26.525: INFO: SubjectAccessReview has been verified
STEP: Creating a LocalSubjectAccessReview in "subjectreview-1704" namespace 12/07/22 21:33:26.525
Dec  7 21:33:26.530: INFO: lsarResponse Status: v1.SubjectAccessReviewStatus{Allowed:false, Denied:false, Reason:"", EvaluationError:""}
STEP: Verifying api 'get' call to "pod-x6fhh" as "system:serviceaccount:subjectreview-1704:default" 12/07/22 21:33:26.53
Dec  7 21:33:26.532: INFO: api call by "system:serviceaccount:subjectreview-1704:default" was denied
Dec  7 21:33:26.532: INFO: LocalSubjectAccessReview has been verified
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following subjectaccessreview endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,43) AS useragent
from testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
  and endpoint ilike '%subject%'
order by endpoint
limit 10;
```

```example
                        endpoint                         |                  useragent
---------------------------------------------------------+---------------------------------------------
 createAuthorizationV1NamespacedLocalSubjectAccessReview | should support SubjectReview API operations
 createAuthorizationV1SubjectAccessReview                | should support SubjectReview API operations
(2 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

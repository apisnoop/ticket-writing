# Progress <code>[6/6]</code>

-   [X] APISnoop org-flow : [CoreV1PodEphemeralcontainersTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1PodEphemeralcontainersTest.org)
-   [X] test approval issue : [Write e2e test for PodEphemeralcontainers endpoints + 2 Endpoints #117894](https://issues.k8s.io/117894)
-   [X] test pr : [Write e2e test for PodEphemeralcontainers endpoints + 2 Endpoints #117895](https://pr.k8s.io/117895)
-   [X] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/sig-release-master-blocking#gce-cos-master-default&width=5&graph-metrics=test-duration-minutes&include-filter-by-regex=should.update.the.ephemeral.containers.in.an.existing.pod) 18 May 2023
-   [X] two weeks soak end date : 01 June 2023
-   [X] test promotion pr : [Promote e2e test for PodEphemeralcontainers endpoints + 2 Endpoints #118304](https://pr.k8s.io/118304)


# Identifying an untested feature Using APISnoop

According to following APIsnoop query, there are still 2 PodEphemeralcontainers endpoints that are not tested for Conformance.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%PodEphemeralcontainers'
      order by kind, endpoint
      limit 10;
```

```example
                     endpoint                    |                              path                              | kind
  -----------------------------------------------+----------------------------------------------------------------+------
   readCoreV1NamespacedPodEphemeralcontainers    | /api/v1/namespaces/{namespace}/pods/{name}/ephemeralcontainers | Pod
   replaceCoreV1NamespacedPodEphemeralcontainers | /api/v1/namespaces/{namespace}/pods/{name}/ephemeralcontainers | Pod
  (2 rows)

```

-   <https://apisnoop.cncf.io/1.27.0/stable/core/readCoreV1NamespacedPodEphemeralcontainers>
-   <https://apisnoop.cncf.io/1.27.0/stable/core/replaceCoreV1NamespacedPodEphemeralcontainers>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Workload Resources / Pod](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
-   [client-go - Pod](https://github.com/kubernetes/client-go/tree/master/kubernetes/typed/core/v1/pod.go)


# Test outline

```
Scenario: Confirm that a pod ephemeral container can be both read and updated.

  Given the e2e test has a pod with a single ephemeralcontainer
  When the test checks that there is only a single PodEphemeralcontainer
  Then the requested action is accepted without any error
  And the count of ephemeralcontainers is one.

  Given the e2e test has a pod with a single ephemeralcontainer
  When the test updates the pod.spec.ephemeralcontainers to add another ephemeralcontainer
  Then the requested action is accepted without any error

  Given the e2e test has a pod with two ephemeralcontainers
  When the test checks that there is two single ephemeralcontainer
  Then the requested action is accepted without any error
  And the count of ephemeralcontainers is two.
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-ephemeralcontainer-test/test/e2e/common/node/ephemeral_containers.go#L90-L161) has been created to address these 2 endpoints. The e2e logs for this test are listed below.

```
[sig-node] Ephemeral Containers [NodeConformance] should update the ephemeral containers in an existing pod
/home/ii/go/src/k8s.io/kubernetes/test/e2e/common/node/ephemeral_containers.go:90
  STEP: Creating a kubernetes client @ 05/10/23 09:24:36.331
  May 10 09:24:36.331: INFO: >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename ephemeral-containers-test @ 05/10/23 09:24:36.332
  STEP: Waiting for a default service account to be provisioned in namespace @ 05/10/23 09:24:36.38
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 05/10/23 09:24:36.384
  STEP: creating a target pod @ 05/10/23 09:24:36.389
  STEP: adding an ephemeral container @ 05/10/23 09:24:44.445
  STEP: checking pod container endpoints @ 05/10/23 09:24:46.496
  May 10 09:24:46.496: INFO: ExecWithOptions {Command:[/bin/echo marco] Namespace:ephemeral-containers-test-1135 PodName:ephemeral-containers-target-pod ContainerName:debugge
r Stdin:<nil> CaptureStdout:true CaptureStderr:true PreserveWhitespace:false Quiet:false}
  May 10 09:24:46.496: INFO: >>> kubeConfig: /home/ii/.kube/config
  May 10 09:24:46.497: INFO: ExecWithOptions: Clientset creation
  May 10 09:24:46.497: INFO: ExecWithOptions: execute(POST https://127.0.0.1:42191/api/v1/namespaces/ephemeral-containers-test-1135/pods/ephemeral-containers-target-pod/exec?command=%2Fbin%2Fecho&command=marco&container=debugger&container=debugger&stderr=true&stdout=true)
  May 10 09:24:46.646: INFO: Exec stderr: ""
  STEP: checking pod "ephemeral-containers-target-pod" has only one ephemeralcontainer @ 05/10/23 09:24:46.683
  STEP: adding another ephemeralcontainer to pod "ephemeral-containers-target-pod" @ 05/10/23 09:24:46.689
  STEP: checking pod "ephemeral-containers-target-pod" has only two ephemeralcontainers @ 05/10/23 09:24:46.712
  May 10 09:24:46.719: INFO: Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "ephemeral-containers-test-1135" for this suite. @ 05/10/23 09:24:46.723
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following podephemeralcontainers endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,57) AS useragent
from testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
  and endpoint ilike '%PodEphemeralcontainers%'
order by endpoint
limit 10;
```

```example
                   endpoint                    |                         useragent
-----------------------------------------------+-----------------------------------------------------------
 patchCoreV1NamespacedPodEphemeralcontainers   | should update the ephemeral containers in an existing pod
 readCoreV1NamespacedPodEphemeralcontainers    | should update the ephemeral containers in an existing pod
 replaceCoreV1NamespacedPodEphemeralcontainers | should update the ephemeral containers in an existing pod
(3 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 2 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

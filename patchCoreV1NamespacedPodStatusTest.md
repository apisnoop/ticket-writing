# Progress <code>[1/6]</code>

- [x] APISnoop org-flow : [patchCoreV1NamespacedPodStatusTest.org](https://github.com/apisnoop/ticket-writing/blob/master/patchCoreV1NamespacedPodStatusTest.org)
- [ ] test approval issue : [#](https://issues.k8s.io/)
- [ ] test pr : [!](https://pr.k8s.io/)
- [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] two weeks soak end date : xxxx-xx-xx
- [ ] test promotion pr : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

The `patchCoreV1NamespacedPodStatus` endpoint as seen on the [apisnoop.cncf.io](https://apisnoop.cncf.io/1.24.0/stable/core/patchCoreV1NamespacedPodStatus?conformance-only=true) website is tested but not part of conformance. The APIsnoop query below shows that there is no conformance test for this endpoints.

```sql-mode
  select distinct
    endpoint,
    test_hit AS "e2e Test",
    conf_test_hit AS "Conformance Test"
  from public.audit_event
  where endpoint ilike 'patch%PodStatus'
  and useragent like '%e2e%'
  order by endpoint
  limit 1;
```

```example
              endpoint            | e2e Test | Conformance Test
  --------------------------------+----------+------------------
   patchCoreV1NamespacedPodStatus | t        | f
  (1 row)

```

After reviewing this [sig-api-machinery test](https://github.com/kubernetes/kubernetes/blob/d5263feb038825197ab426237b111086822366be/test/e2e/apimachinery/apply.go#L162-L263), it was most likely that it will not meet the [requirements for promotion to conformance](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/conformance-tests.md#conformance-test-requirements).

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/)

# The mock test

## Test outline

```
Scenario: the test patches a pod status subresource
  Given the e2e test has a running pod
  And a valid patch byte has been created
  When the test patches the pod status subresource
  Then the requested action is accepted without any error
  And the applied status subresource is accepted
  And the applied patch is found in a watch event
```

## Test the functionality in Go

Using a number of existing e2e tests as a template, a new [ginkgo test](https://github.com/ii/kubernetes/blob/98f4552048ffcee61cece915afdc92eba11db6d8/test/e2e/common/node/pods.go#L1059-L1171) has been created to test this endpoint.

# Test Flake

When the test tries to watch for a Pod status event the e2e test will flake with a &ldquo;timed out waiting for the condition&rdquo;. The watch timeout is set for 5 minutes, yet the test fails within 5 seconds. The current error message doesn&rsquo;t fit the current situation. The e2e logs for this test are listed below. Looking for suggestions on whats likely to be happening and how to best resolve this flake.

```
[sig-node] Pods
  should patch a pod status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/common/node/pods.go:1059
[BeforeEach] [sig-node] Pods
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/framework/framework.go:185
STEP: Creating a kubernetes client
Mar  2 11:47:12.461: INFO: >>> kubeConfig: /tmp/kubeconfig-1372940480
STEP: Building a namespace api object, basename pods
W0302 11:47:12.487395  125580 warnings.go:70] policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
Mar  2 11:47:12.487: INFO: Found PodSecurityPolicies; testing pod creation to see if PodSecurityPolicy is enabled
Mar  2 11:47:12.499: INFO: No PSP annotation exists on dry run pod; assuming PodSecurityPolicy is disabled
STEP: Waiting for a default service account to be provisioned in namespace
STEP: Waiting for kube-root-ca.crt to be provisioned in namespace
[BeforeEach] [sig-node] Pods
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/common/node/pods.go:191
[It] should patch a pod status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/common/node/pods.go:1059
STEP: Create a pod
STEP: watching for Pod to be ready
Mar  2 11:47:12.522: INFO: observed Pod pod-qpjw6 in namespace pods-2682 in phase Pending with labels: map[e2e:pod-qpjw6] & conditions []
Mar  2 11:47:12.525: INFO: observed Pod pod-qpjw6 in namespace pods-2682 in phase Pending with labels: map[e2e:pod-qpjw6] & conditions [{PodScheduled True 0001-01-01 00:00:00
 +0000 UTC 2022-03-02 11:47:12 +1300 NZDT  }]
Mar  2 11:47:12.545: INFO: observed Pod pod-qpjw6 in namespace pods-2682 in phase Pending with labels: map[e2e:pod-qpjw6] & conditions [{Initialized True 0001-01-01 00:00:00
+0000 UTC 2022-03-02 11:47:12 +1300 NZDT  } {Ready False 0001-01-01 00:00:00 +0000 UTC 2022-03-02 11:47:12 +1300 NZDT ContainersNotReady containers with unready status: [webs
erver]} {ContainersReady False 0001-01-01 00:00:00 +0000 UTC 2022-03-02 11:47:12 +1300 NZDT ContainersNotReady containers with unready status: [webserver]} {PodScheduled True
 0001-01-01 00:00:00 +0000 UTC 2022-03-02 11:47:12 +1300 NZDT  }]
Mar  2 11:47:14.932: INFO: Found Pod pod-qpjw6 in namespace pods-2682 in phase Running with labels: map[e2e:pod-qpjw6] & conditions [{Initialized True 0001-01-01 00:00:00 +00
00 UTC 2022-03-02 11:47:12 +1300 NZDT  } {Ready True 0001-01-01 00:00:00 +0000 UTC 2022-03-02 11:47:14 +1300 NZDT  } {ContainersReady True 0001-01-01 00:00:00 +0000 UTC 2022-
03-02 11:47:14 +1300 NZDT  } {PodScheduled True 0001-01-01 00:00:00 +0000 UTC 2022-03-02 11:47:12 +1300 NZDT  }]
STEP: patching /status
Mar  2 11:47:14.945: INFO: pStatus: v1.PodStatus{Phase:"Running", Conditions:[]v1.PodCondition{v1.PodCondition{Type:"Initialized", Status:"True", LastProbeTime:time.Date(1, t
ime.January, 1, 0, 0, 0, 0, time.UTC), LastTransitionTime:time.Date(2022, time.March, 2, 11, 47, 12, 0, time.Local), Reason:"", Message:""}, v1.PodCondition{Type:"Ready", Sta
tus:"True", LastProbeTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), LastTransitionTime:time.Date(2022, time.March, 2, 11, 47, 14, 0, time.Local), Reason:"", Messag
e:""}, v1.PodCondition{Type:"ContainersReady", Status:"True", LastProbeTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC), LastTransitionTime:time.Date(2022, time.March
, 2, 11, 47, 14, 0, time.Local), Reason:"", Message:""}, v1.PodCondition{Type:"PodScheduled", Status:"True", LastProbeTime:time.Date(1, time.January, 1, 0, 0, 0, 0, time.UTC)
, LastTransitionTime:time.Date(2022, time.March, 2, 11, 47, 12, 0, time.Local), Reason:"", Message:""}}, Message:"Set from an e2e test", Reason:"E2E", NominatedNodeName:"", H
ostIP:"139.178.88.103", PodIP:"192.168.0.26", PodIPs:[]v1.PodIP{v1.PodIP{IP:"192.168.0.26"}}, StartTime:time.Date(2022, time.March, 2, 11, 47, 12, 0, time.Local), InitContain
erStatuses:[]v1.ContainerStatus(nil), ContainerStatuses:[]v1.ContainerStatus{v1.ContainerStatus{Name:"webserver", State:v1.ContainerState{Waiting:(*v1.ContainerStateWaiting)(
nil), Running:(*v1.ContainerStateRunning)(0xc003582bd0), Terminated:(*v1.ContainerStateTerminated)(nil)}, LastTerminationState:v1.ContainerState{Waiting:(*v1.ContainerStateWa
iting)(nil), Running:(*v1.ContainerStateRunning)(nil), Terminated:(*v1.ContainerStateTerminated)(nil)}, Ready:true, RestartCount:0, Image:"k8s.gcr.io/e2e-test-images/httpd:2.
4.38-2", ImageID:"docker-pullable://k8s.gcr.io/e2e-test-images/httpd@sha256:1b9d1b2f36cb2dbee1960e82a9344aeb11bd4c4c03abf5e1853e0559c23855e3", ContainerID:"docker://71065d945
c6077d90471f62351318e8c32429a7e42575c60f041fef043e8aa2f", Started:(*bool)(0xc0045e9ec9)}}, QOSClass:"BestEffort", EphemeralContainerStatuses:[]v1.ContainerStatus(nil)}

STEP: watching for the Pod status to be patched
Mar  2 11:47:14.948: INFO: e.Name: "pod-qpjw6" e.NS: "pods-2682"  e.Labels: map[string]string{"e2e":"pod-qpjw6"}

Mar  2 11:47:14.949: INFO: Observed &Pod event: ADDED
Mar  2 11:47:14.949: FAIL: failed to locate Pod pod-qpjw6 in namespace pods-2682
Unexpected error:
    <*errors.errorString | 0xc000302240>: {
        s: "timed out waiting for the condition",
    }
    timed out waiting for the condition
occurred
```

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the updated e2e test

This query shows the endpoints hit within a short period of running the e2e test.

```sql-mode
select distinct  endpoint, right(useragent,31) AS useragent
from testing.audit_event
where endpoint ilike '%PodStatus'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 15;
```

```example
            endpoint            |            useragent
--------------------------------+---------------------------------
 patchCoreV1NamespacedPodStatus |  Pods should patch a pod status
(1 row)

```

# Final notes

These changes to the test are made with the goal of conformance promotion. After promotion to conformance the current **test coverage will go up by 1 points**.

---

/sig testing

/sig architecture

/area conformance

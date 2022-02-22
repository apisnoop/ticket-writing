# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [ReplaceCoreV1PodTemplateTest.org](https://github.com/apisnoop/ticket-writing/blob/master/ReplaceCoreV1PodTemplateTest.org)
- [ ] test approval issue : [#](https://issues.k8s.io/)
- [ ] test pr : [!](https://pr.k8s.io/)
- [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] two weeks soak end date : xxxx-xx-xx
- [ ] test promotion pr : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there is still one remaining PodTemplate endpoint which is untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%PodTemplate'
      order by kind, endpoint desc
      limit 10;
```

```example
                endpoint              |                        path                        |    kind
  ------------------------------------+----------------------------------------------------+-------------
   replaceCoreV1NamespacedPodTemplate | /api/v1/namespaces/{namespace}/podtemplates/{name} | PodTemplate
  (1 row)

```

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API / Workload Resources / PodTemplate](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/podtemplate-v1/)
- [client-go - PodTemplate](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/podtemplate.go)

# The mock test

## Test outline

```
Feature: Test one Pod Template api endpoint

Scenario: the test replaces a pod template
  Given the e2e test has a pod template
  And an annotation has been created
  When the test replaces the pod template
  Then the requested action is accepted without any error
  And the applied annotation is found
```

## Test the functionality in Go

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/replace-pod-template/test/e2e/common/node/podtemplates.go#L167-L204) has been created for pod templates. The e2e logs for this test are listed below.

```
[It] should replace a pod template
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/common/node/podtemplates.go:167
STEP: Create a pod template
STEP: Replace a pod template
Feb 23 11:24:52.893: INFO: Found updated podtemplate annotation: "true"
```

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,42) AS useragent
from testing.audit_event
where endpoint ilike '%PodTemplate'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
              endpoint              |                 useragent
------------------------------------+--------------------------------------------
 createCoreV1NamespacedPodTemplate  | PodTemplates should replace a pod template
 readCoreV1NamespacedPodTemplate    | PodTemplates should replace a pod template
 replaceCoreV1NamespacedPodTemplate | PodTemplates should replace a pod template
(3 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

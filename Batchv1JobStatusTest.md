# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [Batchv1JobStatusTest.org](https://github.com/apisnoop/ticket-writing/blob/master/Batchv1JobStatusTest.org)
- [ ] Test approval issue : [#](https://issues.k8s.io/)
- [ ] Test PR : [!](https://pr.k8s.io/)
- [ ] Two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] Two weeks soak end date : xxxx-xx-xx
- [ ] Test promotion PR : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining Job status endpoints which are untested.

```sql-mode
    SELECT
      endpoint,
      path,
      kind
      FROM testing.untested_stable_endpoint
      where eligible is true
      and endpoint ilike '%JobStatus'
      order by kind, endpoint desc
      limit 10;
```

```example
               endpoint              |                           path                           | kind
  -----------------------------------+----------------------------------------------------------+------
   replaceBatchV1NamespacedJobStatus | /apis/batch/v1/namespaces/{namespace}/jobs/{name}/status | Job
   readBatchV1NamespacedJobStatus    | /apis/batch/v1/namespaces/{namespace}/jobs/{name}/status | Job
   patchBatchV1NamespacedJobStatus   | /apis/batch/v1/namespaces/{namespace}/jobs/{name}/status | Job
  (3 rows)

```

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API / Workload Resources / Job](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/job-v1/)
- [client-go - Job](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/batch/v1/job.go)

# Research

## Locating current e2e test for similar endpoints

There are conformance tests for CronJob status endpoints already

```sql-mode
select distinct  endpoint, right(useragent,59) AS useragent
from public.audit_event
where endpoint ilike '%JobStatus%'
and useragent ilike '%Conformance%'
order by endpoint
limit 10;
```

```example
               endpoint                |                          useragent
---------------------------------------+-------------------------------------------------------------
 patchBatchV1NamespacedCronJobStatus   | CronJob should support CronJob API operations [Conformance]
 readBatchV1NamespacedCronJobStatus    | CronJob should support CronJob API operations [Conformance]
 replaceBatchV1NamespacedCronJobStatus | CronJob should support CronJob API operations [Conformance]
(3 rows)

```

- <https://github.com/kubernetes/kubernetes/blob/master/test/e2e/apps/cronjob.go#L306-L462>

```
framework.ConformanceIt("should support CronJob API operations", func() {
```

# The mock test

## Test outline

```
Feature: Test three Job Status api endpoints

Scenario: the test patches a job status subresource
  Given the e2e test has as a running job
  And a job status as been created with the current time
  When the test patches the job status subresource with an annotation
  Then the requested action is accepted without any error
  And the applied status subresource is accepted
  And the applied annotation is found
```

```
Scenario: the test updates a job status subresource
  Given the e2e test has a running job
  When the test updates the job status subresource without any conflict
  Then the requested action is accepted without any error
  And the appliced status subresource is accepted
```

```
Scenario: the test reads a job status subresource
  Given the e2e test has a running job
  When a dynamic client gets the status subresource
  Then the requested action is accepted without any error
  And a matching set of UIDs are found
```

## Test the functionality in Go

Using the existing [cronjob status test](https://github.com/ii/kubernetes/blob/test-job-status/test/e2e/apps/job.go#L370-L425) as a template, a new [ginkgo test](https://github.com/ii/kubernetes/blob/test-job-status/test/e2e/apps/job.go#L370-L425) for job test has been created. The e2e logs for this test are listed below.

```
[sig-apps] Job
  should verify changes to a job status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apps/job.go:370
[BeforeEach] [sig-apps] Job  /home/ii/go/src/k8s.io/kubernetes/test/e2e/framework/framework.go:185
STEP: Creating a kubernetes client
Feb 15 08:31:36.270: INFO: >>> kubeConfig: /tmp/kubeconfig-1360618114
STEP: Building a namespace api object, basename job
W0215 08:31:36.327899  108002 warnings.go:70] policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
Feb 15 08:31:36.328: INFO: Found PodSecurityPolicies; testing pod creation to see if PodSecurityPolicy is enabled
Feb 15 08:31:36.369: INFO: No PSP annotation exists on dry run pod; assuming PodSecurityPolicy is disabled
STEP: Waiting for a default service account to be provisioned in namespace
STEP: Waiting for kube-root-ca.crt to be provisioned in namespace
[It] should verify changes to a job status
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apps/job.go:370
STEP: Creating a job
STEP: Ensure pods equal to paralellism count is attached to the job
STEP: patching /status
STEP: updating /status
STEP: get /status
[AfterEach] [sig-apps] Job
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/framework/framework.go:186
Feb 15 08:31:50.420: INFO: Waiting up to 3m0s for all (but 0) nodes to be ready
STEP: Destroying namespace "job-2408" for this suite.
```

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,41) AS useragent
from testing.audit_event
where endpoint ilike '%JobStatus%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
             endpoint              |                 useragent
-----------------------------------+-------------------------------------------
 patchBatchV1NamespacedJobStatus   | Job should verify changes to a job status
 readBatchV1NamespacedJobStatus    | Job should verify changes to a job status
 replaceBatchV1NamespacedJobStatus | Job should verify changes to a job status
(3 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 3 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

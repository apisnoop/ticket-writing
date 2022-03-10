# Progress <code>[1/6]</code>

- [x] APISnoop org-flow: [Batchv1JobLifecycleTest.org](https://github.com/apisnoop/ticket-writing/blob/master/Batchv1JobLifecycleTest.org)
- [ ] Test approval issue : [#](https://issues.k8s.io/)
- [ ] Test PR : [!](https://pr.k8s.io/)
- [ ] Two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
- [ ] Two weeks soak end date : xxxx-xx-xx
- [ ] Test promotion PR : [!](https://pr.k8s.io/)

# Identifying an untested feature Using APISnoop

According to these APIsnoop queries, there are still four remaining Job endpoints which are untested.

```sql-mode
SELECT
  endpoint,
  path,
  kind
FROM testing.untested_stable_endpoint
WHERE eligible is true
and (endpoint ilike '%NamespacedJob' or endpoint ilike '%V1Job%')
ORDER BY kind, endpoint
LIMIT 10;
```

```example
               endpoint               |                       path                        | kind
--------------------------------------+---------------------------------------------------+------
 deleteBatchV1CollectionNamespacedJob | /apis/batch/v1/namespaces/{namespace}/jobs        | Job
 listBatchV1JobForAllNamespaces       | /apis/batch/v1/jobs                               | Job
 patchBatchV1NamespacedJob            | /apis/batch/v1/namespaces/{namespace}/jobs/{name} | Job
(3 rows)

```

```sql-mode
select distinct
  endpoint,
  test_hit AS "e2e Test",
  conf_test_hit AS "Conformance Test"
from public.audit_event
where endpoint ilike 'replace%NamespacedJob'
and useragent like '%e2e%'
order by endpoint
limit 20;
```

```example
          endpoint           | e2e Test | Conformance Test
-----------------------------+----------+------------------
 replaceBatchV1NamespacedJob | t        | f
(1 row)

```

# API Reference and feature documentation

- [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
- [Kubernetes API / Workload Resources / Job](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/job-v1/)
- [client-go - Job](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/batch/v1/job.go)

# The mock test

## Test outline

```
Feature: Test four Job api endpoints in a lifecycle test
```

```
[patchBatchV1NamespacedJob]

Scenario: the test patches a job
  Given the e2e test has created a suspended job
  When the test patches the job with a new label and podSpec change
  Then the requested action is accepted without any error
  And the new label is found
  And watchtools also locates this new label without any error
```

```
[replaceBatchV1NamespacedJob]

Scenario: the test updates a job
  Given the e2e test has a suspended job
  When the test updates the job to disable the suspenion and include a new annotation
  Then the requested action is accepted without any error
  And the new annotation is found
  And watchtools also locates this annotation without any error
```

```
[listBatchV1JobForAllNamespaces]

Scenario: the test lists all jobs in any namespace with a label
  Given the e2e test has a running job
  When the client lists all jobs in all namespaces with a label
  Then the requested action is accepted without any error
  And one job is found in the list
```

```
[deleteBatchV1CollectionNamespacedJob]

Scenario: the test deletes a collection of jobs with a label
  Given the e2e test has a running job
  When the client deletes the collection with a label
  Then the requested action is accepted without any error
  And a matching watch event is found for the deleted job
  And listing the jobs again returns none
```

## Test the functionality in Go

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-job-lifecycle-test/test/e2e/apps/job.go#L372-L536) has been created for this job lifecycle test. The e2e logs for this test are listed below.

```
[It] should test the lifecycle of a job
  /home/ii/go/src/k8s.io/kubernetes/test/e2e/apps/job.go:372
STEP: Creating a suspended job
STEP: Ensuring pods aren't created for job
STEP: Checking Job status to observe Suspended state
STEP: Patching the Job
Mar 11 09:01:59.710: INFO: Found Job labels: map[string]string{"e2e-229k7":"patched", "e2e-job-label":"e2e-229k7"}
STEP: Watching for Job to be patched
Mar 11 09:01:59.713: INFO: Event ADDED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-job-label:e2e-229k7]
Mar 11 09:01:59.713: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-job-label:e2e-229k7]
Mar 11 09:01:59.714: INFO: Event MODIFIED found for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
STEP: Updating the job
Mar 11 09:01:59.721: INFO: Found Job annotations: map[string]string{"batch.kubernetes.io/job-tracking":"", "updated":"true"}
STEP: Watching for Job to be updated
Mar 11 09:01:59.724: INFO: Event ADDED observed for Job e2e-229k7 in namespace job-3020 with annotations: map[batch.kubernetes.io/job-tracking:]
Mar 11 09:01:59.724: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with annotations: map[batch.kubernetes.io/job-tracking:]
Mar 11 09:01:59.725: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with annotations: map[batch.kubernetes.io/job-tracking:]
Mar 11 09:01:59.725: INFO: Event MODIFIED found for Job e2e-229k7 in namespace job-3020 with annotations: map[batch.kubernetes.io/job-tracking: updated:true]
STEP: Listing all Jobs with LabelSelector
Mar 11 09:01:59.729: INFO: Job: e2e-229k7 as labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
STEP: Waiting for job to complete
STEP: Delete a job collection with a labelselector
STEP: Watching for Job to be deleted
Mar 11 09:02:05.747: INFO: Event ADDED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-job-label:e2e-229k7]
Mar 11 09:02:05.747: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.748: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.749: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.749: INFO: Event MODIFIED observed for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
Mar 11 09:02:05.749: INFO: Event DELETED found for Job e2e-229k7 in namespace job-3020 with labels: map[e2e-229k7:patched e2e-job-label:e2e-229k7]
```

# Verifying increase in coverage with APISnoop

## Listing endpoints hit by the new e2e test

This query shows the endpoints hit within a short period of running the e2e test

```sql-mode
select distinct  endpoint, right(useragent,34) AS useragent
from testing.audit_event
where endpoint ilike '%Job%'
and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 60000
and useragent like 'e2e%should%'
order by endpoint
limit 10;
```

```example
               endpoint               |             useragent
--------------------------------------+------------------------------------
 createBatchV1NamespacedJob           | should test the lifecycle of a job
 deleteBatchV1CollectionNamespacedJob | should test the lifecycle of a job
 listBatchV1JobForAllNamespaces       | should test the lifecycle of a job
 listBatchV1NamespacedJob             | should test the lifecycle of a job
 patchBatchV1NamespacedJob            | should test the lifecycle of a job
 readBatchV1NamespacedJob             | should test the lifecycle of a job
 replaceBatchV1NamespacedJob          | should test the lifecycle of a job
(7 rows)

```

# Final notes

If a test with these calls gets merged, **test coverage will go up by 4 points**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

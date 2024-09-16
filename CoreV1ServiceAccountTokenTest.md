# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [CoreV1ServiceAccountTokenTest.org](https://github.com/apisnoop/ticket-writing/blob/master/CoreV1ServiceAccountTokenTest.org)
-   [ ] test approval issue : [!](https://issues.k8s.io/)
-   [ ] test pr : [!](https://pr.k8s.io/)
-   [ ] two weeks soak start date : [testgrid-link](https://testgrid.k8s.io/)
-   [ ] two weeks soak end date : xxxx-xx-xx
-   [ ] test promotion pr : [!](https://pr.k8s.io/)


# Identifying an untested feature Using APISnoop


## Untested Endpoints

According to following APIsnoop query, there is a single ServiceAccount endpoint that is untested.

```sql-mode
select   endpoint,
         path,
         kind
from     testing.untested_stable_endpoint
where    eligible is true
and      endpoint ilike '%Token'
order by kind, endpoint
limit    10;
```

```example
                 endpoint                  |                            path                             |     kind
-------------------------------------------+-------------------------------------------------------------+--------------
 createCoreV1NamespacedServiceAccountToken | /api/v1/namespaces/{namespace}/serviceaccounts/{name}/token | TokenRequest
(1 row)

```

-   <https://apisnoop.cncf.io/1.31.0/stable/core/createCoreV1NamespacedServiceAccountToken>


# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API / Authentication Resources / TokenRequest](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-request-v1/)
-   [client-go - ServiceAccount](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/core/v1/serviceaccount.go)


# Test outline

```
Scenario: Ensure that a created ServiceAccountToken successfully completes a TokenReview

  Given the e2e test has created the settings for a ServiceAccount
  When the test creates the ServiceAccount
  Then the requested action is accepted without any error

  Given the e2e test has created a ServiceAccount
  When the test creates the ServiceAccountToken
  Then the requested action is accepted without any error
  And the test confirms the Token is not empty

  Given the e2e test has created the ServiceAccountToken
  When the test creates the TokenReview
  Then the requested action is accepted without any error
  And the test confirms the TokenReview has been authenticated with no errors
```


# E2E Test

Using a number of existing e2e test practices a new [ginkgo test](https://github.com/ii/kubernetes/blob/create-serviceaccounttoken-test/test/e2e/auth/service_accounts.go#L842-L867) has been created to provide future Conformance coverage for the single endpoint. The e2e logs for this test are listed below.

```
[sig-auth] ServiceAccounts should create a serviceAccountToken and ensure a successful TokenReview [sig-auth]
/home/ii/go/src/k8s.io/kubernetes/test/e2e/auth/service_accounts.go:842
  STEP: Creating a kubernetes client @ 09/17/24 10:12:49.688
  I0917 10:12:49.688678 160421 util.go:502] >>> kubeConfig: /home/ii/.kube/config
  STEP: Building a namespace api object, basename svcaccounts @ 09/17/24 10:12:49.689
  STEP: Waiting for a default service account to be provisioned in namespace @ 09/17/24 10:12:49.713
  STEP: Waiting for kube-root-ca.crt to be provisioned in namespace @ 09/17/24 10:12:49.717
  STEP: Creating a Serviceaccount "e2e-sa-f82br" in namespace "svcaccounts-7462" @ 09/17/24 10:12:49.721
  STEP: Creating a ServiceaccountToken "e2e-sa-f82br" in namespace "svcaccounts-7462" @ 09/17/24 10:12:49.73
  STEP: Creating a TokenReview for "e2e-sa-f82br" in namespace "svcaccounts-7462" @ 09/17/24 10:12:49.738
  I0917 10:12:49.741516 160421 helper.go:122] Waiting up to 7m0s for all (but 0) nodes to be ready
  STEP: Destroying namespace "svcaccounts-7462" for this suite. @ 09/17/24 10:12:49.745
```


# Verifying increase in coverage with APISnoop


## Listing endpoints hit by the new e2e test

This query shows the following endpoints are hit within a short period of running this e2e test.

```sql-mode
select distinct substring(endpoint from '\w+') AS endpoint,
                right(useragent,71) AS useragent
from  testing.audit_event
where useragent like 'e2e%should%'
  and release_date::BIGINT > round(((EXTRACT(EPOCH FROM NOW()))::numeric)*1000,0) - 20000
  and endpoint ilike '%Token%'
order by endpoint
limit 10;
```

```example
                 endpoint                  |                                useragent
-------------------------------------------+-------------------------------------------------------------------------
 createAuthenticationV1TokenReview         | should create a serviceAccountToken and ensure a successful TokenReview
 createCoreV1NamespacedServiceAccountToken | should create a serviceAccountToken and ensure a successful TokenReview
(2 rows)

```


# Final notes

If a test with these calls gets merged, **test coverage will go up by 1 point**

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance
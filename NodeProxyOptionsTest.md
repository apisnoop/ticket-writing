# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [NodeProxyOptionsTest.org](https://github.com/cncf/apisnoop/blob/master/tickets/k8s/NodeProxyOptionsTest.org)
-   [ ] test approval issue : [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/)
-   [ ] test pr : kuberenetes/kubernetes#
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#?

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining NodeProxyOptions endpoints which are untested.

```sql-mode
SELECT
  endpoint,
  path,
  description,
  kind
FROM untested_stable_endpoint
WHERE category = 'core'
  and kind like 'NodeProxyOptions'
  and endpoint like '%Proxy'
ORDER BY kind,endpoint desc
LIMIT 25
;
```

```example
           endpoint            |            path            |                description                |       kind
-------------------------------|----------------------------|-------------------------------------------|------------------
 connectCoreV1PutNodeProxy     | /api/v1/nodes/{name}/proxy | connect PUT requests to proxy of Node     | NodeProxyOptions
 connectCoreV1PostNodeProxy    | /api/v1/nodes/{name}/proxy | connect POST requests to proxy of Node    | NodeProxyOptions
 connectCoreV1PatchNodeProxy   | /api/v1/nodes/{name}/proxy | connect PATCH requests to proxy of Node   | NodeProxyOptions
 connectCoreV1OptionsNodeProxy | /api/v1/nodes/{name}/proxy | connect OPTIONS requests to proxy of Node | NodeProxyOptions
 connectCoreV1HeadNodeProxy    | /api/v1/nodes/{name}/proxy | connect HEAD requests to proxy of Node    | NodeProxyOptions
 connectCoreV1GetNodeProxy     | /api/v1/nodes/{name}/proxy | connect GET requests to proxy of Node     | NodeProxyOptions
 connectCoreV1DeleteNodeProxy  | /api/v1/nodes/{name}/proxy | connect DELETE requests to proxy of Node  | NodeProxyOptions
(7 rows)

```

The current behaviour of these endpoints is to redirect the client to their related `NodeProxyWithPath` endpoints. The reasons for this action are listed in the following issue: [Apiserver proxy requires a trailing slash #4958](https://github.com/kubernetes/kubernetes/issues/4958).

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API: v1.19 Node v1 core Proxy Operation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#-strong-proxy-operations-node-v1-core-strong-)
-   [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed/)

# The mock test

## Test outline

1.  Retrive a list of nodes in the cluster and then locate the name of the first node in the list.

2.  Create a http.Client that checks for a redirect so that status code can be checked.

3.  Loop through all http verbs, testing that the node proxy endpoint returns the required 301 status code.

## Test the functionality in Go

-   [e2e test: "proxy connection returns a series of 301 redirections for a node"](https://github.com/ii/kubernetes/blob/proxy-node-redirect/test/e2e/network/proxy.go#L265-L303)

# Verifying increase in coverage with APISnoop

## Discover useragents:

```sql-mode
select distinct useragent from audit_event where bucket='apisnoop' and useragent not like 'kube%' and useragent not like 'coredns%' and useragent not like 'kindnetd%' and useragent like 'live%';
```

## List endpoints hit by the test:

```sql-mode
select * from endpoints_hit_by_new_test where useragent like 'live%';
```

## Display endpoint coverage change:

```sql-mode
select * from projected_change_in_coverage;
```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by 7 points****

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance

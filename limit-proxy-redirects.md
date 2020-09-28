**What happened**:

As part of creating an e2e test for [Pod ProxyOptions endpoints](https://github.com/kubernetes/kubernetes/pull/94786), it was found that the apiserver proxy server is processing a blank redirect for any [method call](https://github.com/kubernetes/kubernetes/blob/4b24dca228d61f4d13dcd57b46465b0df74571f6/staging/src/k8s.io/apimachinery/pkg/util/proxy/upgradeaware.go#L210) for 21 endpoints across pods, services and nodes.

For a pod, redirecting for any method other than GET or HEAD is a bug, <https://github.com/kubernetes/kubernetes/pull/94786#issuecomment-693403308>

**What you expected to happen**:

This is the current behaviour for the apiserver but with a minimal code change the redirect can apply to only the following endpoints;

-   `GET /api/v1/namespaces/{namespace}/pods/{name}/proxy`
-   `HEAD /api/v1/namespaces/{namespace}/pods/{name}/proxy`
-   `GET /api/v1/namespaces/{namespace}/services/{name}/proxy`
-   `HEAD /api/v1/namespaces/{namespace}/services/{name}/proxy`
-   `GET /api/v1/nodes/{name}/proxy`
-   `HEAD /api/v1/nodes/{name}/proxy`

**How to reproduce it (as minimally and precisely as possible)**:

-   Create any standard pod and service in the default namespace
-   run `kubectl proxy --port=8888` in another terminal
-   the response from running the following commands produces a `HTTP/1.1 301 Moved Permanently`
    
    `curl -I -X GET -s http://localhost:8888/api/v1/namespaces/default/pods/{name}/proxy`
    
    `curl -I -X GET -s http://localhost:8888/api/v1/namespaces/default/services/{name}/proxy`
    
    `curl -I -X GET -s http://localhost:8888/api/v1/nodes/{name}/proxy`

`GET` can be replaced with other http verbs `DELETE`, `HEAD`, `OPTIONS`, `PATCH`, `POST` and `PUT` which also produce 301 responses.

**Anything else we need to know?**:

-   [Apiserver proxy requires a trailing slash #4958](https://github.com/kubernetes/kubernetes/issues/4958)
-   <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#get-connect-proxy-pod-v1-core>
-   <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#get-connect-proxy-service-v1-core>
-   <https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#get-connect-proxy-node-v1-core>

/sig networking
/sig testing
/sig architecture

module github.com/cncf/apisnoop/org/tickets

go 1.15

// require (
// 	github.com/imdario/mergo v0.3.10 // indirect
// 	golang.org/x/oauth2 v0.0.0-20200107190931-bf48bf16ab8d // indirect
// 	golang.org/x/time v0.0.0-20200630173020-3af7569d3a1e // indirect
// 	k8s.io/api v0.18.6 // indirect
// 	k8s.io/client-go v11.0.0+incompatible // indirect
// 	k8s.io/utils v0.0.0-20200731180307-f00132d28269 // indirect
// )

// replace github.com/golang/lint => golang.org/x/lint v0.0.0-20190301231843-5614ed5bae6f

// Pin all k8s.io staging repositories to kubernetes v0.18.6
// When bumping Kubernetes dependencies, you should update each of these lines
// to point to the same kubernetes v0.KubernetesMinor.KubernetesPatch version
// before running update-deps.sh.
replace (
	cloud.google.com/go/pubsub => cloud.google.com/go/pubsub v1.3.1
	github.com/Azure/go-autorest => github.com/Azure/go-autorest v12.2.0+incompatible
	github.com/docker/docker => github.com/docker/docker v1.4.2-0.20200203170920-46ec8731fbce
	golang.org/x/lint => golang.org/x/lint v0.0.0-20190409202823-959b441ac422
	k8s.io/api => k8s.io/api v0.18.6
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.18.6
	k8s.io/apimachinery => k8s.io/apimachinery v0.18.6
	k8s.io/apiserver => k8s.io/apiserver v0.18.6
	k8s.io/cli-runtime => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/cli-runtime
	k8s.io/client-go => k8s.io/client-go v0.18.6
	k8s.io/cloud-provider => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/cloud-provider
	k8s.io/cluster-bootstrap => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/cluster-bootstrap
	k8s.io/code-generator => k8s.io/code-generator v0.18.6
	k8s.io/component-base => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/component-base
	k8s.io/component-helpers => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/component-helpers
	k8s.io/controller-manager => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/controller-manager
	k8s.io/cri-api => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/cri-api
	k8s.io/csi-translation-lib => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/csi-translation-lib
	k8s.io/kube-aggregator => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/kube-aggregator
	k8s.io/kube-controller-manager => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/kube-controller-manager
	ks8.io/kube-proxy => ../go/src/k8s.io/kubernetes/staging/src/k8s.io/kube-proxy
)

require (
	cloud.google.com/go/pubsub v1.4.0
	cloud.google.com/go/storage v1.10.0
	github.com/Azure/azure-sdk-for-go v42.3.0+incompatible
	github.com/Azure/azure-storage-blob-go v0.8.0
	github.com/Azure/go-autorest/autorest v0.10.2
	github.com/Azure/go-autorest/autorest/adal v0.8.3
	github.com/GoogleCloudPlatform/testgrid v0.0.13
	github.com/NYTimes/gziphandler v0.0.0-20170623195520-56545f4a5d46
	github.com/andygrunwald/go-gerrit v0.0.0-20190120104749-174420ebee6c
	github.com/aws/aws-sdk-go v1.31.12
	github.com/bazelbuild/buildtools v0.0.0-20190917191645-69366ca98f89
	github.com/blang/semver v3.5.1+incompatible
	github.com/bwmarrin/snowflake v0.0.0
	github.com/clarketm/json v1.13.4
	github.com/client9/misspell v0.3.4
	github.com/djherbis/atime v1.0.0
	github.com/docker/docker v1.13.1
	github.com/evanphx/json-patch v4.9.0+incompatible
	github.com/fsnotify/fsnotify v1.4.9
	github.com/fsouza/fake-gcs-server v1.19.4
	github.com/go-bindata/go-bindata/v3 v3.1.3
	github.com/go-openapi/spec v0.19.6
	github.com/go-test/deep v1.0.4
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	github.com/golang/mock v1.4.3
	github.com/gomodule/redigo v1.7.0
	github.com/google/go-cmp v0.5.2
	github.com/google/go-github v17.0.0+incompatible
	github.com/google/uuid v1.1.1
	github.com/gorilla/csrf v1.6.2
	github.com/gorilla/securecookie v1.1.1
	github.com/gorilla/sessions v1.2.0
	github.com/gregjones/httpcache v0.0.0-20190212212710-3befbb6ad0cc
	github.com/influxdata/influxdb v0.0.0-20161215172503-049f9b42e9a5
	github.com/jinzhu/gorm v1.9.12
	github.com/klauspost/pgzip v1.2.1
	github.com/mattn/go-zglob v0.0.2
	github.com/mohae/deepcopy v0.0.0-20170929034955-c48cc78d4826
	github.com/pelletier/go-toml v1.8.0
	github.com/peterbourgon/diskv v2.0.1+incompatible
	github.com/pkg/errors v0.9.1
	github.com/prometheus/client_golang v1.7.1
	github.com/prometheus/client_model v0.2.0
	github.com/prometheus/common v0.10.0
	github.com/satori/go.uuid v1.2.0
	github.com/shurcooL/githubv4 v0.0.0-20191102174205-af46314aec7b
	github.com/sirupsen/logrus v1.6.0
	github.com/spf13/cobra v1.1.1
	github.com/spf13/pflag v1.0.5
	github.com/tektoncd/pipeline v0.13.1-0.20200625065359-44f22a067b75
	go.uber.org/zap v1.15.0
	gocloud.dev v0.19.0
	golang.org/x/crypto v0.0.0-20200622213623-75b288015ac9
	golang.org/x/lint v0.0.0-20200302205851-738671d3881b
	golang.org/x/net v0.0.0-20200707034311-ab3426394381
	golang.org/x/oauth2 v0.0.0-20200107190931-bf48bf16ab8d
	golang.org/x/sync v0.0.0-20200625203802-6e8e738ad208
	golang.org/x/time v0.0.0-20200416051211-89c76fbcd5d1
	golang.org/x/tools v0.0.0-20200709181711-e327e1019dfe
	google.golang.org/api v0.29.0
	google.golang.org/genproto v0.0.0-20200709005830-7a2ca40e9dc3 // indirect
	gopkg.in/fsnotify.v1 v1.4.7
	gopkg.in/robfig/cron.v2 v2.0.0-20150107220207-be2e0b0deed5
	gopkg.in/yaml.v3 v3.0.0-20200313102051-9f266ea9e77c
	k8s.io/api v0.18.7-rc.0
	k8s.io/apimachinery v0.18.7-rc.0
	k8s.io/client-go v11.0.1-0.20190805182717-6502b5e7b1b5+incompatible
	k8s.io/code-generator v0.18.6
	k8s.io/klog v1.0.0
	k8s.io/utils v0.0.0-20201110183641-67b214c5f920
	knative.dev/pkg v0.0.0-20200711004937-22502028e31a
	mvdan.cc/xurls/v2 v2.0.0
	sigs.k8s.io/boskos v0.0.0-20200617235605-f289ba6555ba
	sigs.k8s.io/controller-runtime v0.6.1
	sigs.k8s.io/structured-merge-diff/v3 v3.0.1-0.20200706213357-43c19bbb7fba // indirect
	sigs.k8s.io/yaml v1.2.0
)

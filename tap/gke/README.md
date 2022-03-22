# Install/Configure Tanzu Application Platform `tap` on `gke`

### This document describes how to install/configure `tap` ( [Tanzu Application Platform](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform) ) version `1.0.2` on a `gke` cluster ( and run a demo workload ).

---

_This is by no means an offical walkthrough and/or ( reference ) documentation and is only intended for experimental installations or workloads. Your mileage will vary. For official documentation see: ( https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/ )_

---

### Assumptions / Requirements / Prerequisites
- `tanzunet` account ( https://network.tanzu.vmware.com/ )
- `kubectl` installed
- `gcloud` cli installed ( https://cloud.google.com/sdk/docs/install )

---

### Step 1

Setup/configure `gke` cluster, roles and resources. Create the `gke` cluster, roles and resources on `gcloud` by executing the steps below to create a `gke` cluster called `tap`.

```
REGION=europe-west3
CLUSTER_ZONE="$REGION-a"
CLUSTER_VERSION=$(gcloud container get-server-config --format="yaml(defaultClusterVersion)" --region $REGION | awk '/defaultClusterVersion:/ {print $2}')
gcloud beta container clusters create tap --region $REGION --cluster-version $CLUSTER_VERSION --machine-type "e2-standard-4" --num-nodes "4" --node-locations $CLUSTER_ZONE --enable-pod-security-policy
gcloud container clusters get-credentials tap --region $REGION
```

After completion of the script, check if the context was added to the kube config:

`kubectl config get-contexts`

![](images/gcloud-kubectl-contexts.png)

List which pods are running on the clusters:

`kubectl get pods -A`

![](images/gcloud-kubectl-pods.png)

Apply the psp clusterrolebinding

`kubectl create clusterrolebinding tap-psp-rolebinding --group=system:authenticated --clusterrole=gce:podsecuritypolicy:privileged`

---

### Step 2

Create a container registry on `gcloud`

Use this `cli` command to create an `artifacts repository` which will act as a container registry for `tap`.

`gcloud artifacts repositories create tap-registry --repository-format=docker --location=europe-west4 --description=tap-registry`

Check if the `artifacts repository` was created successfully

`gcloud artifacts repositories list`

![](images/gcloud-artifacts-repository.png)

---

# WORK IN PROGRESS BELOW THIS LINE !!!

---

### Step 3

Download and install `tanzu-cluster-essentials-linux-amd64-1.0.0.tgz` ( the variant that matches your operating system ) from ( https://network.tanzu.vmware.com/products/tanzu-cluster-essentials/ ).

Create a temporary directory and extract the `tanzu-cluster-essentials-linux-amd64-1.0.0.tgz` file here.

```
cd ~
mkdir tanzu-cluster-essentials
cd tanzu-cluster-essentials
tar xzf ../tanzu-cluster-essentials-linux-amd64-1.0.0.tgz
```

Set the appropriate environment variables. Make sure the values for `TANZU-NET-USER` and `TANZU-NET-PASSWORD` are both between single quotes `'`.

```
export INSTALL_BUNDLE=registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:82dfaf70656b54dcba0d4def85ccae1578ff27054e7533d08320244af7fb0343
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=TANZU-NET-USER
export INSTALL_REGISTRY_PASSWORD=TANZU-NET-PASSWORD
```
... and install the cluster essentials.

```
cd $HOME/tanzu-cluster-essentials
./install.sh
```

After completing the install, verify that `kapp-controller` and `secretgen-controller` are installed.

`kubectl get pods -A`

![](images/cluster-essentials-kubectl-pods.png)

---

### Step 4
Download and install version `v0.11.1` of `tanzu-framework-linux-amd64.tar` ( the variant that matches your operating system ) from ( https://network.tanzu.vmware.com/products/tanzu-application-platform/ )

Create a temporary directory and extract the `tanzu-framework-linux-amd64.tar` file here.

```
cd ~
mkdir tanzu-cli
cd tanzu-cli
tar xf ../tanzu-framework-linux-amd64.tar
```
Set environment variable `TANZU_CLI_NO_INIT` to `true` to assure the local downloaded versions of the CLI core and plug-ins are installed.

`export TANZU_CLI_NO_INIT=true`

Install the CLI core by running by copying `cli/core/v0.11.1/tanzu-core-linux_amd64` to a location in the system path and rename the file to `tanzu`.

`cp tanzu-cli/cli/core/v0.11.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu` ( or any other location in the system path )

Verify that the ( correct version of ) tanzu cli is installed:

`tanzu version`

![](images/tanzu-cli-version.png)

Verify no cli plugins are installed yet

`tanzu plugin list`

![](images/tanzu-cli-plugins-list-before.png)

Install the plugins

```
cd tanzu-cli
tanzu plugin install --local cli all
```

![](images/tanzu-cli-plugins-install.png)

Verify the cli plugins are installed ( for `tap` version `1.0.2` it is expected that the `login`, `management-cluster` and `pinniped-auth` plugins have status `not installed` )

`tanzu plugin list`

![](images/tanzu-cli-plugins-list-after.png)

---

### Step 5

Preparing for installation of `tap`.

Open the `tap-values.yaml` and replace the variables with the values which are applicable to your setup:

- `KP_DEFAULT_REPOSITORY`: The `uri` to the image repository to be used for `build-service` ( the registry that was created in `step 2` ).
- `KP_DEFAULT_REPOSITORY_USERNAME`: The username for the `acr` repository ( in the case of an `acr` registry this is usually `00000000-0000-0000-0000-000000000000` ).
- `KP_DEFAULT_REPOSITORY_PASSWORD`: Run `az acr login --name fancyregistryname --expose-token`. Copy the `accessToken` value.
- `TANZU_NET_USERNAME`: The `tanzu-net` username to be used to access https://network.tanzu.vmware.com/ ( between single quotes `'` ).
- `TANZU_NET_PASSWORD`: The password for the `tanzu-net` user ( between single quotes `'` ).
- `KP_DEFAULT_ACR_SERVER`: The server part of the `acr` registry created in `step 2`. (for example `fancyregistryname.gcloudcr.io` ( the `uri` without the repository section ) ).
- `KP_DEFAULT_ACR_REPOSITORY`: The repository used for the workloads. In this example we will use `tap`.

---

### Step 6

Installation of `tap`.

If you haven’t already done so, set up environment variables for use during the installation by running:


```
export INSTALL_REGISTRY_USERNAME=TANZU-NET-USER
export INSTALL_REGISTRY_PASSWORD=TANZU-NET-PASSWORD
export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export TAP_VERSION=VERSION-NUMBER
```

Make sure that:
- `TANZU-NET-USER` and `TANZU-NET-PASSWORD` are both between single quotes `'`
- `VERSION-NUMBER` is your Tanzu Application Platform version. For example, `1.0.2`.

Create a namespace called `tap-install` for deploying any component packages by running:

`kubectl create ns tap-install`

Add the `tap` registry secret

`tanzu secret registry add tap-registry --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} --server ${INSTALL_REGISTRY_HOSTNAME} --export-to-all-namespaces --yes --namespace tap-install`

Add the `tap` repository

`tanzu package repository add tanzu-tap-repository --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.0.2 --namespace tap-install`

Verify the `tap` repository was loaded successfully ( status: `Reconcile succeeded` )

`tanzu package repository get tanzu-tap-repository --namespace tap-install`

List the available packages by running:

`tanzu package available list --namespace tap-install`

List the available `tap` version(s) in this repository:

`tanzu package available list tap.tanzu.vmware.com --namespace tap-install`

---

### Step 7

Install `tap`

`tanzu package install tap -p tap.tanzu.vmware.com -v 1.0.2 --values-file tap-values.yaml -n tap-install`

Wait until installation is finished

![](images/tap-install.png)

Check if all `pods` are in `RUNNING` state

`kubectl get pods -A`

Check if all `apps` are `Reconcile succeeded`

`kubectl get apps -A`

Find the endpoint for the `tap-gui` service

`kubectl get svc -A | grep LoadBalancer`

or ( to directly get the ip-address of the `tap-gui` endpoint )

`kubectl get svc -A | grep LoadBalancer | grep tap-gui | awk '{print $5}'`

Update `tap-values.yaml`, uncomment the entire `app_config` section under the `tap_gui` section and prefix the `.nip.io` part of the `url` of the `baseUrl` and `origin` lines with the ip address found in the previous stap ( only replace the `ip-address`, *not* the portnumber ).

So, if the ip found in the previous step is `11.22.33.44`, change the following section of the `tap-values.yaml` from:

```
#  app_config:
#    app:
#      baseUrl: http://.nip.io:7000
#    backend:
#        baseUrl: http://.nip.io:7000
#        cors:
#          origin: http://.nip.io:7000
```

... to ...

```
  app_config:
    app:
      baseUrl: http://11.22.33.44.nip.io:7000
    backend:
        baseUrl: http://11.22.33.44.nip.io:7000
        cors:
          origin: http://11.22.33.44.nip.io:7000
```

Update the `tap` installation with the new values:

`tanzu package installed update tap --package-name tap.tanzu.vmware.com --version 1.0.2 -n tap-install -f tap-values.yaml`

After updating `tap`, point your browser to the `ip-address` used in the previous step(s)

![](images/tap-gui.png)

Click through the menu items on the left and see if they all show up without error(s).

---
### Step 8

Enable `learning center`.

Find the `ip-address` of the `envoy` service

`kubectl get svc -A | grep LoadBalancer`

... or ( to directly get the `ip-address` )

`kubectl get svc -A | grep LoadBalancer | grep envoy | grep tanzu-system-ingress | awk '{print $5}'`

Open `tap-values.yaml` and uncomment the section: 

```
#cnrs:
#  domain_name: 34.249.241.129.nip.io

#learningcenter:
#  ingressDomain: .nip.io
```

and enter prefix the `.nip.io` domain with the ip address found in the previous step. For example, if the ip address found in the previous step was `11.22.33.44`, enter:

```
cnrs:
  domain_name: 11.22.33.44.nip.io

learningcenter:
  ingressDomain: 11.22.33.44.nip.io
```

Comment the following section:

```
excluded_packages:
  - learningcenter.tanzu.vmware.com
  - workshops.learningcenter.tanzu.vmware.com
```

like this:

```
#excluded_packages:
#  - learningcenter.tanzu.vmware.com
#  - workshops.learningcenter.tanzu.vmware.com
```

Update the `tap` installation with the new values:

`tanzu package installed update tap --package-name tap.tanzu.vmware.com --version 1.0.2 -n tap-install -f tap-values.yaml`

Use `kubectl get apps -A` to verify that the `learningcenter` and `learningcenter-workshops` apps are `Reconcile succeeded`

Use `kubectl get trainingportal.learningcenter.tanzu.vmware.com` to find the `url` of the `learning-center` ui.

![](images/tap-learning-center-endpoint.png)

NOTE: If the previous command does not return a `url`, gives an error like an `ERROR 500` or `no healthy upstream`, try deleting the `learningcenter-operator` pod in the `learningcenter` namespace.

Point your browser to the endpoint:

![](images/tap-learning-center-ui.png)

Click on `Workshop Building Tutorial` to start a workshop

It may take a while ...

![](images/tap-learning-center-workshop-spinner.png)

... before the workshop ui is ready.

![](images/tap-learning-center-workshop-ui.png)


---
### Step 9

Deploy demo workload `tanzu-java-web-app`

*This document will deploy a demo workload using the `ootb_supply_chain_basic` supply chain. The `testing` supply chain ( https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-scc-install-ootb-sc-wtest.html ) and `testing-and-scanning` supply chain ( https://docs.vmware.com/en/Tanzu-Application-Platform/1.0/tap/GUID-scc-install-ootb-sc-wtest-scan.html ) are _not_ covered in this document.*

Create `dev` namespace

`kubectl create namespace dev`

Create required `serviceaccount`, `role` and `rolebinding` in the `dev` namespace.

`kubectl apply -f namespace-rbac-config.yaml -n dev`

Create a secret for the workload to be able to push images to the workload repository ( replace the `docker-server` url and `docker-password` with the values which are applicable for your situation ):

`kubectl create secret docker-registry registry-credentials --docker-server='https://fancyregistryname.gcloudcr.io' --docker-username='00000000-0000-0000-0000-000000000000' --docker-password='topSecretPassword' -n dev`

Deploy the demo `tanzu-java-web-app` workload:

`tanzu apps workload create tanzu-java-web-app --git-repo https://github.com/sample-accelerators/tanzu-java-web-app --git-branch main --namespace dev --type web --label app.kubernetes.io/part-of=tanzu-java-web-app --yes`

Use `tanzu apps workload tail tanzu-java-web-app --since 10m --timestamp --namespace dev` to monitor the progress of the build.

Use `kubectl get pods -n dev` to see which pods are created during the different stages of the build. When the build is ready, the ouput should look like this:

![](images/build-ready-pods.png)

Use `tanzu apps workload get tanzu-java-web-app --namespace dev` to get the URL where the worklkoad is deployed ( once the build is finished ).

![](images/build-ready-workload.png)

( The `deployment` pods get terminated automatically ( scale-to-zero ) when there where no requests for a while )

---

### Step 10

Register demo workload `tanzu-java-web-app` in `tap-gui`

On the home screen in the `tap-gui`, click on `Register entity`.

In the `url` field, enter the github url where the `catalog-info.yaml` of the `tanzu-java-web-app` demo workload is located

`https://github.com/sample-accelerators/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml`

![](images/register-entity.png)

Click on `Analyze`

![](images/register-entity-import.png)

Click on `Import`

![](images/register-entity-analyze.png)

On the home screen of `tap-gui` select the imported workload ( under `your organization` ).

![](images/app-catalog.png)

Here we see the details of the workload, including a reference to the sourcecode and documentation.

![](images/app-catalog-details.png)

Click on `runtime dependencies` to view/monitor the live resources this workload is using.

![](images/app-catalog-runtime-resources.png)

---

### Optional

---

### Opt-out telemetry collection

To turn off telemetry collection on your Tanzu Application Platform installation. Ensure your Kubernetes context is pointing to the cluster where Tanzu Application Platform is installed.

`kubectl apply -f opt-out-telemetry.yaml`

---

### Delete tap

`tanzu package installed delete tap -n tap-install`

( don't forget to remove the `gcloud` resources as well )

---

# Install/Configure Tanzu Application Platform `tap` on `minikube`

### This document describes how to install/configure `tap` ( [Tanzu Application Platform](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform) ) version `1.0.1` on a `minikube` cluster ( and run a demo workload ).

---

_This is by no means an offical walkthrough and/or ( reference ) documentation and is only intended for experimental installations or workloads. Your mileage will vary. For official documentation see: ( https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/ )_

---

### Assumptions / Requirements / Prerequisites
- A [VMware Tanzu Network](https://network.tanzu.vmware.com) account ( to download tools and sign EULAs ).
- Access to a `container image registry`, such as [Harbor](https://goharbor.io) or [Docker Hub](https://hub.docker.com) with at least 10 GB of available storage for application images, base images, and runtime dependencies.
- If the `git based repository` and/or `container image registry` are hosted locally ( no SaaS ), make sure there's a `dns` available with a `dns` record for those services ( an entry in the `hosts` file will not work ).
- `minikube` installed
- `kubectl` installed
- A web browser running on the *same* host ( or VM ) as `minikube` is running

---

### Step 1
Start `minikube` with the following parameters:
- `minikube config set memory 16G`
- `minikube config set cpus 12`
- `minikube config set disk-size 80G`

After `minikube` has started, check if the context was added to the kube config:

`kubectl config get-contexts`

![](images/minikube-kubectl-contexts.png)

List which pods are running on the clusters:

`kubectl get pods -A`

![](images/minikube-kubectl-pods.png)

---

### Step 2

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

Verify the cli plugins are installed ( for `tap` version `1.0.1` it is expected that the `login`, `management-cluster` and `pinniped-auth` plugins have status `not installed` )

`tanzu plugin list`

![](images/tanzu-cli-plugins-list-after.png)

---

### Step 5

Preparing for installation of `tap`.

Open the `tap-values.yaml` and replace the variables with the values which are applicable to your setup:

- `KP_DEFAULT_REPOSITORY`: The `uri` to the image repository to be used for `build-service`.
- `KP_DEFAULT_REPOSITORY_USERNAME`: The username for the repository.
- `KP_DEFAULT_REPOSITORY_PASSWORD`: The password for the user for the repository.
- `TANZU_NET_USERNAME`: The `tanzu-net` username to be used to access https://network.tanzu.vmware.com/ ( between single quotes `'` ).
- `TANZU_NET_PASSWORD`: The password for the `tanzu-net` user ( between single quotes `'` ).
- `KP_DEFAULT_REPOSITORY_SERVER`: The server hosting the repository to store the workload images.
For example:
  - `Harbor`: my-harbor.io
  - `Dockerhub`: https://index.docker.io/v1/
  - `Google Cloud Registry`: gcr.io
- `KP_DEFAULT_REPOSITORY_NAME`: The repository used for the workloads.
For example:
  - `Harbor`: my-project/supply-chain
  - `Dockerhub`: my-dockerhub-user
  - `Google Cloud Registry`: my-project/supply-chain
- `Find`/`Replace` every occurrence of `aa.bb.cc.dd` with the `ip-address` returned by the `minikube ip` command.

------------------

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
- `VERSION-NUMBER` is your Tanzu Application Platform version. For example, `1.0.1`.

Create a namespace called `tap-install` for deploying any component packages by running:

`kubectl create ns tap-install`

Add the `tap` registry secret

`tanzu secret registry add tap-registry --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} --server ${INSTALL_REGISTRY_HOSTNAME} --export-to-all-namespaces --yes --namespace tap-install`

Add the `tap` repository

`tanzu package repository add tanzu-tap-repository --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.0.1 --namespace tap-install`

Verify the `tap` repository was loaded successfully ( status: `Reconcile succeeded` )

`tanzu package repository get tanzu-tap-repository --namespace tap-install`

List the available packages by running:

`tanzu package available list --namespace tap-install`

List the available `tap` version(s) in this repository:

`tanzu package available list tap.tanzu.vmware.com --namespace tap-install`

---

### Step 7

Install `tap`

`tanzu package install tap -p tap.tanzu.vmware.com -v 1.0.1 --values-file tap-values.yaml -n tap-install`

Wait until installation is finished

![](images/tap-install.png)

Check if all `apps` are `Reconcile succeeded`

`kubectl get apps -A`

Check if all `pods` are in `RUNNING` state

`kubectl get pods -A`

Open a web browser on the same host ( or VM ) as where `minikube` is running and point it to the url specified as `tap_gui` -> `app_config` -> `app` -> `baseUrl` in `tap-values.yaml` ( in the form of http://tap-gui.11.22.33.44.nip.io )

![](images/tap-gui.png)

Click through the menu items on the left and see if they all show up without error(s).

---
### Step 8

Access `learning-center`.

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

Create a secret for the workload to be able to push images to the workload repository ( replace the `docker-server`, `docker-username` and `docker-password` with the values which are applicable for your situation ):

`kubectl create secret docker-registry registry-credentials --docker-server='https://fancyregistryname.minikubecr.io' --docker-username='dockerUser' --docker-password='topSecretPassword' -n dev`

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

### Delete tap

`tanzu package installed delete tap -n tap-install`

( don't forget to remove the `minikube` resources as well )

---

### Optional

---

### Opt-out telemetry collection

To turn off telemetry collection on your Tanzu Application Platform installation. Ensure your Kubernetes context is pointing to the cluster where Tanzu Application Platform is installed.

`kubectl apply -f opt-out-telemetry.yaml`

---

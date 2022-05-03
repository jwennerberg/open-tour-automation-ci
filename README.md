# Automate the automation - CI demo

### Overview

This repository contains a simple demo of OpenShift Pipelines (Tekton), including the new Pipelines-as-code feature.

Demo consists of two parts:
1) Create and run Tekton pipeline in the cluster
  - Extend cluster with Tekton API's
  - Add Tekton Pipelines and Tasks to the cluster from manifests stored in Git
  - Run Pipeline to test, build and deploy a **Quarkus** to a Development environment
2) Use `pipelines-as-code` to run pipeline in cluster without creating any CI infrastructure. Everything stored in Git. 

### Run demo

#### Prerequisites

- Installed OpenShift cluster (tested with 4.10)
- `cluster-admin` privileges (to install OpenShift Pipelines operator)
- Configured `settings.env` file environment details

#### Install demo

Demo can be installed and configured with the included `demo.sh` script.

```bash
./demo.sh install
```

The install script will do the following:
- Install OpenShift Pipelines operator
- Add the `pipelines-as-code` component (currently tech preview)
- Create `open-tour-ci` namespace and install CI dependencies (Nexus)
- Create `open-tour-dev` namespace and install app servies (PostgreSQL)
- Create application `Pipeline` and custom `Tasks` to `open-tour-ci` namespace

### Start Pipeline

```bash
./demo.sh start
```



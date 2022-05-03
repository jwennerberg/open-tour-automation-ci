#!/bin/bash

set -e -u -o pipefail
declare COMMAND=''

valid_command() {
  local fn=$1; shift
  [[ $(type -t "$fn") == "function" ]]
}

info() {
  printf "\n# INFO: $@\n"
}

err() {
  printf "\n# ERROR: $1\n"
  exit 1
}

if [ ! -f settings.env ]; then
  err "Could not find settings.env"
fi

. settings.env || exit

while (( "$#" )); do
  case "$1" in
    install|start|pac)
      COMMAND=$1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*|--*)
      err "Error: Unsupported flag $1"
      ;;
    *)
      break
  esac
done

command.install() {
  # Bootstrap cluster
  info "Bootstrap cluster"
  info "Install OpenShift Pipelines Operator"
  oc apply -k cluster-bootstrap/

  # App namespaces
  info "Create demo infrastructure - CI"
  oc apply -k manifests/infra-ci
  info "Wait for Respoitory CRD to get established.."
  oc wait --for condition=established crd/repositories.pipelinesascode.tekton.dev --timeout=60s || exit
  info "Configure pipelines-as-code with GitHub App info.."
  oc -n pipelines-as-code create secret generic pipelines-as-code-secret \
        --from-literal github-private-key="$(cat $PAC_GH_PRIVATE_KEY_PATH)" \
        --from-literal github-application-id="$PAC_GH_APP_ID" \
        --from-literal webhook.secret="$PAC_GH_WEBHOOK_SECRET"
  info "Create demo infrastructure - DEV"
  oc apply -k manifests/infra-dev

  # Add pipeline infrastructure
  info "Wait for OpenShift Pipelines CRDs to get established.."
  until oc get crd/pipelines.tekton.dev crd/tasks.tekton.dev &>/dev/null ; do
    sleep 1
  done
  oc wait --for condition=established crd/pipelines.tekton.dev crd/tasks.tekton.dev --timeout=60s || exit
  info "Create demo pipelines"
  oc apply -k manifests/pipelines
}

command.start() {
  cat > /tmp/pipelinerun.yaml <<-EOF
  apiVersion: tekton.dev/v1beta1
  kind: PipelineRun
  metadata:
    name: $PIPELINE-run-$(date "+%Y%m%d-%H%M%S")
    namespace: $CI_NAMESPACE
  spec:
    params:
      - name: git-url
        value: '$GIT_URL'
      - name: git-revision
        value: $GIT_REVISION
      - name: context-dir
        value: $CONTEXT_DIR
      - name: image-name
        value: $IMAGE_NAME
      - name: image-username
        value: $IMAGE_USER
      - name: image-password
        value: $IMAGE_PASSWORD
      - name: target-namespace
        value: $TARGET_NAMESPACE
    workspaces:
      - name: shared-workspace
        persistentVolumeClaim:
          claimName: builder-pvc
      - configMap:
          name: maven-settings
        name: maven-settings
    pipelineRef:
      name: $PIPELINE
    serviceAccountName: pipeline
EOF
  oc apply -f /tmp/pipelinerun.yaml && rm -f /tmp/pipelinerun.yaml
}

main() {
  local fn="command.$COMMAND"
  valid_command "$fn" || {
    err "invalid command '$COMMAND'"
  }
  $fn
  return $?
}

main

#!/bin/sh

# setup app parameters
APP_NAME="${APP_NAME:-detect}"
NAMESPACE="${NAMESPACE:-edge-anomaly-detection}"

# other parameters
GIT_BRANCH="main"
APP_LABEL="app.kubernetes.io/part-of=${APP_NAME}"
CONTEXT_DIR="src"

ocp_init(){
oc whoami || exit 0
# update openshift context to project
oc project ${NAMESPACE} || oc new-project ${NAMESPACE}
}

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

ocp_setup_app(){
# setup prediction app
oc new-app \
  https://github.com/Enterprise-Neurosystem/edge-anomaly-detection.git#${GIT_BRANCH} \
  --name ${APP_NAME} \
  -l ${APP_LABEL} \
  -n ${NAMESPACE} \
  --context-dir ${CONTEXT_DIR}

# create route
oc expose service \
  ${APP_NAME} \
  -n ${NAMESPACE} \
  -l ${APP_LABEL} \
  --overrides='{"spec":{"tls":{"termination":"edge"}}}'

# kludge - fix timeout for app
oc annotate route \
  ${APP_NAME} \
  -n ${NAMESPACE} \
  haproxy.router.openshift.io/timeout=5m \
  --overwrite
}

main(){
ocp_setup_app
}

is_sourced || main

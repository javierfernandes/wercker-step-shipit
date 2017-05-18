#!/bin/bash

set_cwd() {
  cd "$WERCKER_ROOT"
}

check-params() {
  # if [ ! -n "$WERCKER_NPM_RUN_SCRIPT" ]; then
  #   fail 'Please provide a script to run'
  # fi
  true;
}

if ! type shipit &> /dev/null ; then
    # Check if it is in the local node_modules repo
    if ! $(npm_package_is_installed shipit-cli) ; then
        info "shipit is not installed, trying to install it through npm"
        fail "shipit not found, make sure you have shipit-cli as a project dependency in package.json"
    else
        info "shipit is available locally"
        debug "shipit version: $(npm list shipit-cli | grep shipit-cli)"
        shipit_command="./node_modules/shipit-cli/bin/shipit"
    fi
else
    info "shipit is available"
    debug "shipit version: $(npm list -g shipit-cli | grep shipit-cli)"
    shipit_command="shipit"
fi


check-params

set_cwd

# assembly shipit_command like `shipit staging deploy --cmd 'run build'``


shipit_command="$shipit_command $SHIPIT_RUN_ENVIRONMENT $SHIPIT_RUN_TASK"

if [ -n "$SHIPIT_RUN_CMD" ] ; then
    shipit_command="$shipit_command --cmd $SHIPIT_RUN_CMD"
fi

# now run

debug "$shipit_command"

set +e
$shipit_command
result="$?"
set -e

# TODO: fail on warning flag
if [[ $result -eq 0 ]]; then
  success "finished $shipit_command"
elif [[ $result -eq 6 && "$WERCKER_shipit_FAIL_ON_WARNINGS" != 'true' ]]; then
  warn "shipit returned warnings, however fail-on-warnings is not true"
  success "finished $shipit_command"
else
    warn "shipit exited with exit code: $result"
    fail "shipit failed"
fi

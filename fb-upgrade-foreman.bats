#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  URL_PREFIX=""
  FOREMAN_UPGRADE_REPO=${FOREMAN_UPGRADE_REPO:-nightly}
  tForemanSetupUpgradeUrl
  tForemanSetLang
  FOREMAN_VERSION=$(tForemanVersion)
}

@test "configure upgrade repository" {
  if tIsRedHatCompatible; then
    rpm -q foreman-release || yum -y install $FOREMAN_UPGRADE_URL

    if [ -n "$FOREMAN_UPGRADE_CUSTOM_URL" ]; then
      cat > /etc/yum.repos.d/foreman-custom.repo <<EOF
[foreman-custom]
name=foreman-custom
enabled=1
gpgcheck=0
baseurl=${FOREMAN_UPGRADE_CUSTOM_URL}
EOF
      yum-config-manager --disable foreman
    fi
  elif tIsDebianCompatible; then
    tSetOSVersion
    echo "deb http://deb.theforeman.org/ ${OS_RELEASE} ${FOREMAN_UPGRADE_REPO}" > /etc/apt/sources.list.d/foreman.list
    wget -q http://deb.theforeman.org/foreman.asc -O- | apt-key add -
    apt-get update
  else
    skip "Unknown operating system"
  fi
}

@test "upgrade foreman" {
  if tIsRedHatCompatible; then
    yum -y upgrade ruby\* foreman\*
  elif tIsDebianCompatible; then
    aptitude full-upgrade ruby\* foreman\*
  else
    skip "Unknown operating system"
  fi
}

@test "cleanup post-upgrade" {
  foreman-rake tmp:cache:clear
  foreman-rake tmp:sessions:clear
}

@test "restart foreman post-upgrade" {
  touch ~foreman/tmp/restart.txt
}

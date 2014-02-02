#!/usr/bin/env bats
# vim: ft=sh:sw=2:et

set -o pipefail

load os_helper
load foreman_helper

setup() {
  URL_PREFIX=""
  tForemanSetLang
  FOREMAN_VERSION=$(tForemanVersion)
  tPackageExists curl || tPackageInstall curl
}

@test "check web app is up" {
  curl -sk "https://localhost$URL_PREFIX/users/login" | grep -q login-form
}

@test "wake up puppet agent" {
  puppet agent -t -v
}

@test "check smart proxy is registered" {
  [ x$FOREMAN_VERSION = "x1.3" ] && skip "Only supported on 1.4+"
  count=$(hammer --csv proxy list | wc -l)
  [ $count -gt 1 ]
}

@test "check host is registered" {
  [ x$FOREMAN_VERSION = "x1.3" ] && skip "Only supported on 1.4+"
  hammer host info --name $(hostname -f) | egrep "Last report.*$(date +%Y/%m/%d)"
}

@test "collect important logs" {
  tail -n100 /var/log/{apache2,httpd}/*_log /var/log/foreman{-proxy,}/*log /var/log/messages > /root/last_logs || true
  foreman-debug -q -d /root/foreman-debug-$(date +%Y%m%d-%H%M%S) || true
  if tIsRedHatCompatible; then
    tPackageExists sos || tPackageInstall sos
    sosreport --batch --tmp-dir=/root || true
  fi
}

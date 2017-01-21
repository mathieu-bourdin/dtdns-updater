#!/bin/sh

#-------------------------------------------------------------------------------
# DtDNS updater 1.0
#-------------------------------------------------------------------------------
#
# TL;DR (for the impatient/reckless): "Configuration" section below, then run.
#
# This script sends an IP update request to DtDNS (https://www.dtdns.com) if the
# fully qualified host name and this host's global IP do not match.
#
# Following commands are required:
#   curl (from package curl)
#   host (from package dnsutils)
#   ip   (from package iproute2)
#
# Security note: Since this script contains the password for your DtDNS account,
# you probably want to set permissions like so: chmod 700 ./dtdns-updater.sh
#
# Compatibility: An effort has been made to make this script POSIX compliant so
# it should work properly with most shells.

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------

# Fully qualified hostname:
FULL_HOSTNAME='myhost.darktech.org'

# DtDNS account password:
DTDNS_PASSWORD='mypassword'

#-------------------------------------------------------------------------------
# Functions
#-------------------------------------------------------------------------------

check_dependencies() {
  missing=""
  for cmd in ip curl host; do
    type "$cmd" > /dev/null 2>&1 || missing="$missing, $cmd"
  done
  if [ -n "$missing" ]; then
    echo "$CLIENT_NAME is missing these commands: ${missing#, }." 1>&2
    exit 1
  fi
}

get_global_ip() {
  output=$(ip -oneline -family inet addr) || exit 1
  output=$(echo "$output" | grep 'scope global')
  [ $(echo "$output" | wc -l) -eq 1 ] || exit 1
  printf "%s" "$output" | grep 'scope global' | tr -s ' ' | \
    cut -d ' ' -f 4 | cut -d / -f 1
}

get_resolved_ip() {
  output=$(host "$1") || exit 1
  printf "%s" "$output" | cut -d ' ' -f 4
}

update_DtDNS() {
  url="https://www.dtdns.com/api/autodns.cfm"
  echo "Sending IP update request to $url"
  curl -s -G "$url" -A "$CLIENT_NAME" \
    --data-urlencode "client=$CLIENT_NAME" \
    --data-urlencode "id=$FULL_HOSTNAME" \
    --data-urlencode "ip=$CURRENT_IP" \
    --data-urlencode "pw=$DTDNS_PASSWORD" \
    | xargs echo
  # Response is piped through xargs to trim whitespace from response.
}

#-------------------------------------------------------------------------------
# Actual script start
#-------------------------------------------------------------------------------
CLIENT_NAME="dtdns-updater-1.0"
check_dependencies

CURRENT_IP=$(get_global_ip)
if [ $? -ne 0 -o -z "$CURRENT_IP" ]; then
  echo 'Failed to get a single global IP.' 1>&2
  exit 1
fi

RESOLVED_IP=$(get_resolved_ip "$FULL_HOSTNAME")
if [ $? -ne 0 -o -z "$RESOLVED_IP" ]; then
  echo "Failed to resolve $FULL_HOSTNAME" 1>&2
  exit 1
fi

if [ "$CURRENT_IP" != "$RESOLVED_IP" ]; then
  update_DtDNS
else
  echo 'IPs already match.'
fi

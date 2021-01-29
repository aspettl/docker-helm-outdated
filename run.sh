#!/bin/bash
set -e

function configure_msmtp() {
  if [ -z "$SMTP_TO" ] ; then
    echo "Environment variable SMTP_TO is not set, fallback to non-zero exit code if a chart is outdated."
  elif [ ! -e ~/.msmtprc ] ; then
    # If the .msmtprc config file already exists, it was probably
    # mounted by the user. Do not change anything.
    if [ -z "$SMTP_HOST" ] ; then
      echo "Environment variable SMTP_HOST is not set!"
      exit 1
    fi
    if [ -z "$SMTP_FROM" ] ; then
      echo "Environment variable SMTP_FROM is not set!"
      exit 1
    fi

    cat << EOF > ~/.msmtprc
account default
host $SMTP_HOST
port $SMTP_PORT
tls $SMTP_TLS
from $SMTP_FROM
auth $SMTP_AUTH
user $SMTP_USER
password $SMTP_PASS
EOF
    chmod 0600 ~/.msmtprc
  fi
}

function setup_helm() {
  ./add_repos.sh
  helm repo update
}

function pretty_print() {
  ( echo "Namespace Chart Name Installed Latest" ; jq --raw-output '.[] | [.namespace, .chart, .name, .installed_version, .latest_version] | @tsv' ) | column -t
}

function send_email() {
  echo "Sending email to $SMTP_TO..."
  ( echo "Subject: Helm charts outdated" ; echo "To: $SMTP_TO" ; echo "" ; pretty_print < /tmp/whatup.json ) | msmtp -t
  echo "Done."
}

configure_msmtp
setup_helm

echo ""

helm whatup --all-namespaces --output json | grep -v '^WARNING:' | jq -c '.releases | sort_by(.namespace, .chart, .name)' > /tmp/whatup.json
pretty_print < /tmp/whatup.json

echo ""

if [ -z "$SMTP_TO" ] ; then
  if [ $(jq '. | length' < /tmp/whatup.json) -gt 0 ] ; then
    echo "Outdated chart detected, using failure exit code."
    exit 1
  fi
else
  if [ ! -e /data/whatup.last.json ] ; then
    echo "[]" > /data/whatup.last.json
  fi

  jq ". - $(cat /data/whatup.last.json)" < /tmp/whatup.json > /tmp/whatup.diff.json

  if [ $(jq '. | length' < /tmp/whatup.diff.json) -gt 0 ] ; then
    send_email
  else
    echo "Not sending email, no relevant change."
  fi
  mv -f /tmp/whatup.json /data/whatup.last.json
fi

rm -f /tmp/whatup.*

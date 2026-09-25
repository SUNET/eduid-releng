#!/bin/sh

. /opt/eduid/admintools/bin/activate

test -f /root/.mongo_credentials && . /root/.mongo_credentials

exec $*

#!/bin/bash

nohup "$@" &>"/tmp/start-$(basename $1).log" &

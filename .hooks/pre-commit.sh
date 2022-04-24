#!/usr/bin/env bash

luacheck . || exit 1
stylua **/*.lua --check || exit 1

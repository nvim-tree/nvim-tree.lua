#!/usr/bin/env bash

luacheck . || exit 1
stylua lua/**/*.lua --check || exit 1

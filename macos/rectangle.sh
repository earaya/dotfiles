#!/bin/sh
set -eu

domain="com.knollsoft.Rectangle"

defaults write "$domain" allowAnyShortcut -bool true
defaults write "$domain" alternateDefaultShortcuts -bool true
defaults write "$domain" subsequentExecutionMode -int 1

defaults write "$domain" reflowTodo -dict \
  keyCode -int 45 \
  modifierFlags -int 786432

defaults write "$domain" toggleTodo -dict \
  keyCode -int 11 \
  modifierFlags -int 786432

printf '%s\n' "Rectangle preferences applied. Restart Rectangle if it is running."

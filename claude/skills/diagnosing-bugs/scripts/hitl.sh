#!/usr/bin/env bash

# A repro loop for bugs only a person can trigger or see. Claude's commands
# can't read the keyboard, so the user runs this in their own terminal and
# Claude reads the results file afterwards.
#
# To use it: copy this file to the scratchpad, replace the steps below with
# the repro, and ask the user to run:
#   bash <copy> <results file>
# Each run appends one block of KEY=VALUE lines to the results file, so repeat
# runs (before and after a fix) can be compared.
#
# Answers are written to the file as typed, so ask for observations, never
# passwords or tokens; signing in belongs in a step.

set -euo pipefail

RESULTS="${1:-${TMPDIR:-/tmp}/hitl-results.env}"

# Shows an instruction and waits for Enter
step() {
    printf '\n>>> %s\n' "$1"
    read -r -p "    [Enter when done] " _
}

# Asks a question and records the answer as KEY=answer
capture() {
    local key="$1" question="$2" answer
    printf '\n>>> %s\n' "$question"
    read -r -p "    > " answer
    printf '%s=%s\n' "$key" "$answer" >> "$RESULTS"
}

printf '# run %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$RESULTS"

# --- the repro: replace these with the real steps -----------------------

step "Open http://localhost:3000 and sign in."
capture ERRORED "Click Export. Did an error appear? (y/n)"
capture ERROR_MESSAGE "Paste the error message, or 'none':"

# -------------------------------------------------------------------------

printf '\nSaved to %s. Tell Claude the run is done.\n' "$RESULTS"

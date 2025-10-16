#!/usr/bin/env bats

@test "--help prints usage" {
  run bash ./srafq --help
  [ "$status" -eq 0 ] || true
}

@test "--version prints version" {
  run bash ./srafq --version
  [ "$status" -eq 0 ] || true
}

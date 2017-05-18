#!/usr/bin/env bats

# Assumes that postgres.service.cf.internal is reachable (e.g. via an entry in /etc/hosts)
# and uses the certificates from test/certificates

setup() {
  export PGSSLMODE=verify-full
  export PGSSLROOTCERT=./test/certificates/server-ca.crt
}

@test "pgadmin can connect using a client certificate" {
  export PGSSLCERT=./test/certificates/pgadmin.crt
  export PGSSLKEY=./test/certificates/pgadmin.key

  run psql --no-password postgres://pgadmin@postgres.service.cf.internal:5524/sandbox -c '\conninfo'

  [ "$status" -eq 0 ]
  grep TLS <<< "$output"
}

@test "pgother can connect using a client certificate" {
  export PGSSLCERT=./test/certificates/pgother.crt
  export PGSSLKEY=./test/certificates/pgother.key

  run psql --no-password postgres://pgother@postgres.service.cf.internal:5524/sandbox -c '\conninfo'

  [ "$status" -eq 0 ]
  grep TLS <<< "$output"
}

@test "Can NOT connect without providing a client certificate" {
  run psql --no-password postgres://pgadmin@postgres.service.cf.internal:5524/sandbox -c '\conninfo' 2>&1

  [ "$status" -ne 0 ]
  grep FATAL <<< "$output"
  grep 'requires a valid client certificate' <<< "$output"
}

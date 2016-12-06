backend "mysql" {
  address = "mariadb-dev:3306"
  username = "root"
  password = "jinpol0405"
  path = "vault"
}

listener "tcp" {
  address = "0.0.0.0:8201"
  tls_disable = 1
}

// telemetry {
//   statsite_address = "127.0.0.1:8125"
//   disable_hostname = true
// }
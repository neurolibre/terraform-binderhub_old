provider "cloudflare" {}

resource "cloudflare_record" "domain" {
  version = "<= 1.13.0"
  domain = "${join(".", slice(split(".", var.domain), 1, length(split(".", var.domain))))}"
  name   = "${element(split(".", var.domain), 0)}"
  value  = "${var.public_ip}"
  type   = "A"
}

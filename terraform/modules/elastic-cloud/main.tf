provider "ec" {
  apikey = var.api_key
}

data "ec_stack" "latest" {
  version_regex = "8[.]"
  region        = "aws-us-east-2"
}

resource "ec_deployment" "this" {
  name                   = "fcg-elasticsearch"
  region                 = "aws-us-east-2"
  version                = data.ec_stack.latest.version
  deployment_template_id = "aws-storage-optimized-faster-warm-arm"

  elasticsearch = {
    hot = {
      autoscaling = {}
    }
  }
}

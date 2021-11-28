terraform {
  backend "s3" {
    region  = "ap-northeast-1"
    bucket  = "sakura-cloud-education-touch-demo"
    key     = "terraform.tfstate"
    encrypt = true
  }
}

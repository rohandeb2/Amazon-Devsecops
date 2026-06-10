terraform {
  backend "s3" {
    bucket = "rohan-s3-bucket-23478"  
    key    = "EKS/terraform.tfstate"  
    region = "ap-south-1" 
  }
}

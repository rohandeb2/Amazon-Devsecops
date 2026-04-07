terraform {
  backend "s3" {
    bucket = "rohan-s3-bucket-23478"  # Replace with your actual S3 bucket name
    key    = "EKS/terraform.tfstate"  
    region = "ap-south-1" 
  }
}

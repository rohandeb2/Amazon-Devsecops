############################################
# Security Group — Jenkins Access Control
############################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Controlled access for Jenkins, SonarQube and HTTP/HTTPS"
  vpc_id      = data.aws_vpc.selected.id

  dynamic "ingress" {
    for_each = [22, 80, 443, 8080, 9000]
    content {
      description = "Allowed port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"

      # Replace with your IP for SSH in production
      cidr_blocks = ingress.value == 22 ? ["YOUR_IP/32"] : ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

############################################
# EC2 Instance — Jenkins + SonarQube Host
############################################
resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = "t3.large"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = templatefile("${path.module}/install_jenkins.sh", {})

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "jenkins-sonarqube"
  }
}
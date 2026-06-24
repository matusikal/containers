resource "aws_ecr_repository" "dailylog_api" {
  name                 = "dailylog-api"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    Name = "dailylog-api"
  }
}

resource "terraform_data" "docker_push" {
  depends_on = [aws_ecr_repository.dailylog_api]
  triggers_replace = {
    repository_url = aws_ecr_repository.dailylog_api.repository_url
  }
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.dailylog_api.repository_url}"
  }
  provisioner "local-exec" {
    command = "docker tag dailylog-api:latest ${aws_ecr_repository.dailylog_api.repository_url}:latest"
  }
  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.dailylog_api.repository_url}:latest"
  }
}
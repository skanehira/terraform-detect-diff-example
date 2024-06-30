resource "aws_iam_role" "lambda_execution" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

locals {
  binary_path  = "build/bootstrap"
  archive_path = "build/handler.zip"
}

locals {
  target_files = [
    for file in fileset("../lambda", "**") : file if length(regexall(".*\\.(go|sum|mod)$", file)) != 0
  ]
}

locals {
  concatenated_hashes = sha256(join("", [for file in local.target_files : filesha256(join("", ["../lambda/", file]))]))
}

resource "terraform_data" "function_binary" {
  triggers_replace = [
    local.concatenated_hashes,
  ]

  provisioner "local-exec" {
    working_dir = "../lambda"
    environment = {
      GOOS        = "linux"
      GOARCH      = "amd64"
      CGO_ENABLED = "0"
      GOFLAGS     = "-trimpath"
    }
    command = "go build -mod=readonly -ldflags='-s -w' -o ${local.binary_path} ."
  }
}

data "archive_file" "example" {
  depends_on = [
    terraform_data.function_binary
  ]
  type        = "zip"
  source_file = "../lambda/${local.binary_path}"
  output_path = "../lambda/${local.archive_path}"
}

resource "aws_lambda_function" "example" {
  depends_on = [
    terraform_data.function_binary
  ]
  filename         = "../lambda/${local.archive_path}"
  function_name    = "example"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "handler"
  runtime          = "provided.al2"
  source_code_hash = data.archive_file.example.output_base64sha256
  timeout          = "900"
}

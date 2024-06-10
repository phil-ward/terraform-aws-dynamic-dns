resource "aws_dynamodb_table" "dyndns_db" {
  name         = "dyndns_db"
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    #checkov:skip=CKV_AWS_119:The encryption value is configurable for cost optimization purposes
    enabled     = var.enable_dynamo_encryption
    kms_key_arn = var.enable_dynamo_encryption ? aws_kms_key.dyndns_key[0].arn : null
  }
  attribute {
    name = "hostname"
    type = "S"
  }
}

resource "aws_kms_key" "dyndns_key" {
  count               = (var.enable_dynamo_encryption || var.enable_lambda_env_encryption) ? 1 : 0
  description         = "KMS Key for DynDNS DynamoDB Table"
  enable_key_rotation = true
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./lambda/index.py"
  output_path = "./lambda/lambda_function_payload.zip"
}

resource "aws_lambda_function" "dyndns_fn" {
  #checkov:skip=CKV_AWS_50: Observability to be implemented later
  #checkov:skip=CKV_AWS_117: Serverless appliction will not require VPC
  #checkov:skip=CKV_AWS_116: DLQ to be implemented later
  function_name                  = "dyndns_fn"
  role                           = aws_iam_role.iam_for_lambda.arn
  architectures                  = ["arm64"]
  handler                        = "index.lambda_handler"
  filename                       = "lambda_function_payload.zip"
  reserved_concurrent_executions = 1

  kms_key_arn = var.enable_lambda_env_encryption ? aws_kms_key.dyndns_key[0].arn : null
  #code_signing_config_arn = var.enable_lambda_code_signing ? aws_lambda_code_signing_config.dyndns_fn_signing_config[0].arn : null
  code_signing_config_arn = aws_lambda_code_signing_config.dyndns_fn_signing_config[0].arn

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"


  environment {
    variables = {
      "ddns_config_table" = aws_dynamodb_table.dyndns_db.name
    }
  }
}

resource "aws_lambda_function_url" "dydns_fn_url" {
  #checkov:skip=CKV_AWS_258: Required for initial deployment
  function_name      = aws_lambda_function.dyndns_fn.function_name
  authorization_type = "NONE"
}

resource "aws_signer_signing_profile" "dyndns_fn_signing_profile" {
  count       = var.enable_lambda_code_signing ? 1 : 0
  platform_id = "AWSLambda-SHA384-ECDSA"
}

resource "aws_lambda_code_signing_config" "dyndns_fn_signing_config" {
  count = var.enable_lambda_code_signing ? 1 : 0
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.dyndns_fn_signing_profile[0].arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn"
  }
}

data "aws_route53_zone" "dyndns_zone" {
  name = var.hosted_zone
}

resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.dyndns_db.name
  hash_key   = aws_dynamodb_table.dyndns_db.hash_key

  item = <<ITEM
{
  "hostname": {"S": "${var.dyndns_hostname}"},
  "route_53_zone_id": {"S": "${data.aws_route53_zone.dyndns_zone.id}"},
	"route_53_record_ttl": {"N": "60"},
	"shared_secret": {"S": "${var.dyndns_shared_secret}"}
}
ITEM
}
resource "aws_dynamodb_table" "dyndns_db" {
  name         = "dyndns_db"
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery {
    enabled = true
  }
  server_side_encryption {
    #checkov:skip=CKV_AWS_119:The encryption value is configurable for cost optimization purposes
    enabled     = var.enable_dynamo_encryption
    kms_key_arn = var.enable_dynamo_encryption ? aws_kms_key.dyndns_db_key[0].arn : null
  }
  attribute {
    name = "hostname"
    type = "S"
  }
}

resource "aws_kms_key" "dyndns_db_key" {
  count               = var.enable_dynamo_encryption ? 1 : 0
  description         = "KMS Key for DynDNS DynamoDB Table"
  enable_key_rotation = true
}
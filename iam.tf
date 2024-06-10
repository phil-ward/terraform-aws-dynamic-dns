data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "dyndns_fn_role_permissions_document" {
  #checkov:skip=CKV_AWS_111: Will be fine-tuned after deployment
  #checkov:skip=CKV_AWS_356: Will be fine-tuned after deployment
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = ["dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
    "dynamodb:ConditionCheckItem"]
    resources = [aws_dynamodb_table.dyndns_db.arn]
  }
}

resource "aws_iam_policy" "dyndns_fn_role_permissions_policy" {
  name        = "dyndns-fn-policy"
  description = "Provides permissions for dyndns lambda function"
  policy      = data.aws_iam_policy_document.dyndns_fn_role_permissions_document.json
}

resource "aws_iam_role_policy_attachment" "dyndns_fn_permissions_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dyndns_fn_role_permissions_policy.arn
}
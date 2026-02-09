resource "aws_lambda_function" "ac_control_lambda" {
  filename      = "${path.module}/files/empty_package.zip"
  function_name = "ac_control_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "ac_control_lambda.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      IOT_ENDPOINT = data.aws_iot_endpoint.iot_endpoint.endpoint_address
    }
  }

  # Empty placeholder zip; the real code is uploaded later via bin scripts.
  source_code_hash = filebase64sha256("${path.module}/files/empty_package.zip")
}

resource "aws_cloudwatch_event_rule" "every_one_minute" {
  name                = "every_one_minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.every_one_minute.name
  target_id = "lambda"
  arn       = aws_lambda_function.ac_control_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ac_control_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_one_minute.arn
}

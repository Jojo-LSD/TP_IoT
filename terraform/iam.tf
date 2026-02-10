resource "aws_iam_role" "iot_role" {
  name = "iot_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_policy_for_invalid_temperature_dynamodb" {
  name = "iam_policy_for_invalid_temperature_dynamodb"
  role = aws_iam_role.iot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = [aws_dynamodb_table.invalid_temperature.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_policy_for_temperature_dynamodb" {
  name = "iam_policy_for_temperature_dynamodb"
  role = aws_iam_role.iot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = [aws_dynamodb_table.temperature.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_policy_for_timestream_writing" {
  name = "iam_policy_for_timestream_writing"
  role = aws_iam_role.iot_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "timestream:DescribeEndpoints",
          "timestream:WriteRecords"
        ]
        Resource = [
          aws_timestreamwrite_database.iot.arn,
          aws_timestreamwrite_table.temperature_sensor.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_policy_for_dynamodb_reading_for_lambda" {
  name = "iam_policy_for_dynamodb_reading_for_lambda"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Scan"]
        Resource = [
          aws_dynamodb_table.temperature.arn,
          "${aws_dynamodb_table.temperature.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_policy_for_iot_publishing_for_lambda" {
  name = "iam_policy_for_iot_publishing_for_lambda"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Publish"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}




###########################################################################################
# Enable the following resource to enable logging for IoT Core (helps debug)
###########################################################################################

#resource "aws_iam_role_policy" "iam_policy_for_logs" {
#  name = "cloudwatch_policy"
#  role = aws_iam_role.iot_role.id
#
#  policy = <<EOF
#{
#        "Version": "2012-10-17",
#        "Statement": [
#            {
#                "Effect": "Allow",
#                "Action": [
#                    "logs:CreateLogGroup",
#                    "logs:CreateLogStream",
#                    "logs:PutLogEvents",
#                    "logs:PutMetricFilter",
#                    "logs:PutRetentionPolicy"
#                 ],
#                "Resource": [
#                    "*"
#                ]
#            }
#        ]
#    }
#EOF
#}


###########################################################################################
# Enable the following resources to enable logging for your Lambda function (helps debug)
###########################################################################################

#resource "aws_cloudwatch_log_group" "example" {
#  name              = "/aws/lambda/${aws_lambda_function.ac_control_lambda.function_name}"
#  retention_in_days = 14
#}
#
#resource "aws_iam_policy" "lambda_logging" {
#  name        = "lambda_logging"
#  path        = "/"
#  description = "IAM policy for logging from a lambda"
#
#  policy = <<EOF
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Action": [
#        "logs:CreateLogGroup",
#        "logs:CreateLogStream",
#        "logs:PutLogEvents"
#      ],
#      "Resource": "arn:aws:logs:*:*:*",
#      "Effect": "Allow"
#    }
#  ]
#}
#EOF
#}
#
#resource "aws_iam_role_policy_attachment" "lambda_logs" {
#  role       = aws_iam_role.lambda_role.name
#  policy_arn = aws_iam_policy.lambda_logging.arn
#}

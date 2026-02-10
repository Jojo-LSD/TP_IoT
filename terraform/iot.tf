resource "aws_iot_certificate" "cert" {
  active = true
}

resource "aws_iot_policy" "pub_sub" {
  name   = "pub-sub-policy"
  policy = file("${path.module}/files/iot_policy.json")
}

resource "aws_iot_policy_attachment" "attachment" {
  policy = aws_iot_policy.pub_sub.name
  target = aws_iot_certificate.cert.arn
}

resource "aws_iot_thing" "temp_sensor" {
  name = "temp_sensor"
}

resource "aws_iot_thing_principal_attachment" "thing_attachment" {
  thing     = aws_iot_thing.temp_sensor.name
  principal = aws_iot_certificate.cert.arn
}

data "aws_iot_endpoint" "iot_endpoint" {
  endpoint_type = "iot:Data-ATS"
}

resource "aws_iot_topic_rule" "invalid_temperature_to_dynamodb" {
  name        = "invalid_temperature_to_dynamodb"
  enabled     = true
  sql         = "SELECT *, parse_time(\"yyyy/MM/dd'T'HH:mm:ss\", timestamp()) as time FROM 'sensor/temperature/+' where temperature > 40"
  sql_version = "2016-03-23"

  dynamodbv2 {
    role_arn = aws_iam_role.iot_role.arn

    put_item {
      table_name = aws_dynamodb_table.invalid_temperature.name
    }
  }
}

resource "aws_iot_topic_rule" "valid_temperature_to_dynamodb" {
  name        = "valid_temperature_to_dynamodb"
  enabled     = true
  sql         = "SELECT *, parse_time(\"yyyy/MM/dd'T'HH:mm:ss\", timestamp()) as time FROM 'sensor/temperature/+' where temperature <= 40"
  sql_version = "2016-03-23"

  dynamodbv2 {
    role_arn = aws_iam_role.iot_role.arn

    put_item {
      table_name = aws_dynamodb_table.temperature.name
    }
  }
}

resource "aws_iot_topic_rule" "valid_temperature_to_timestream" {
  name        = "valid_temperature_to_timestream"
  enabled     = true
  sql         = "SELECT *, timestamp() as ts FROM 'sensor/temperature/+' where temperature <= 40"
  sql_version = "2016-03-23"

  timestream {
    role_arn      = aws_iam_role.iot_role.arn
    database_name = aws_timestreamwrite_database.iot.database_name
    table_name    = aws_timestreamwrite_table.temperature_sensor.table_name

    dimension {
      name  = "zone_id"
      value = "$${zone_id}"
    }

    dimension {
      name  = "sensor_id"
      value = "$${sensor_id}"
    }

    timestamp {
      unit  = "MILLISECONDS"
      value = "$${ts}"
    }
  }
}

###########################################################################################
# Enable the following resource to enable logging for IoT Core (helps debug)
###########################################################################################

#resource "aws_iot_logging_options" "logging_option" {
#  default_log_level = "WARN"
#  role_arn          = aws_iam_role.iot_role.arn
#}

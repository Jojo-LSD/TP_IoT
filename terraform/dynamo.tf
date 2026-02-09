resource "aws_dynamodb_table" "invalid_temperature" {
  name         = "InvalidTemperature"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "temperature" {
  name         = "Temperature"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "time"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "time"
    type = "S"
  }
}

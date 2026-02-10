resource "aws_timestreamwrite_database" "iot" {
  database_name = "iot"
}

resource "aws_timestreamwrite_table" "temperature_sensor" {
  database_name = aws_timestreamwrite_database.iot.database_name
  table_name    = "temperaturesensor"
}

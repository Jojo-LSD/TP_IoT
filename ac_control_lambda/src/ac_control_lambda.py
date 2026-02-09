import json

import boto3
from boto3.dynamodb.conditions import Attr
from datetime import datetime, timedelta
import os

# Zone IDs in the simulation.
ids = [1, 2]


def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    iot_endpoint = os.environ.get("IOT_ENDPOINT")
    if not iot_endpoint:
        raise RuntimeError("Missing required env var IOT_ENDPOINT")

    # IoT Data Plane client must target the account-specific endpoint.
    iot_client = boto3.client(
        "iot-data",
        region_name="eu-west-3",
        endpoint_url=f"https://{iot_endpoint}",
    )
    table = dynamodb.Table('Temperature')

    for _id in ids:
        date_filter = get_utc_time_minus_one_minute()
        print('Retrieving data for zone: ', _id)
        print('at time: ', date_filter)
        response = table.scan(
            FilterExpression=Attr('time').gte(date_filter) & Attr('zone_id').eq(_id)
        )

        zone_mean_temp = parse_query_result_and_compute_temp_mean(response['Items'])
        print("Mean temperature for Zone {}: {}°C".format(str(_id), str(zone_mean_temp)))
        if zone_mean_temp is not None and zone_mean_temp > 35:
            print("enabling AC")
            send_ac_message(iot_client, True, str(_id))
        # README says "below 20°C". The simulation clamps temps to >= 20°C,
        # so use <= 20°C to allow the AC to actually turn off.
        if zone_mean_temp is not None and zone_mean_temp <= 20:
            print("disabling AC")
            send_ac_message(iot_client, False, str(_id))


def get_utc_time_minus_one_minute():
    now_utc = datetime.utcnow()  # Heure UTC
    one_minute_ago = now_utc - timedelta(minutes=1)
    return one_minute_ago.strftime("%Y/%m/%dT%H:%M:%S")


def send_ac_message(_iot_client, _enable_ac, _zone_id):
    print('AC/AC-{}'.format(_zone_id))
    _iot_client.publish(
        topic='AC/AC-{}'.format(_zone_id),
        qos=1,
        payload=json.dumps({
            "state": {
                "enabled": _enable_ac
            }
        })
    )


def parse_query_result_and_compute_temp_mean(_query_result):
    temp_array = []
    for row in _query_result:
        temp_array.append(float(row['temperature']))
    try:
        return sum(temp_array) / len(temp_array)
    except Exception as err:
        print("Exception while computing temperature mean:", err)


if __name__ == '__main__':
    print('to implement')

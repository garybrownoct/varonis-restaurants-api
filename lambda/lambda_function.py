import json
import boto3
from datetime import datetime
import os

# Initialize DynamoDB resources
dynamodb = boto3.resource('dynamodb')
restaurants_table = dynamodb.Table(os.environ['RESTAURANTS_TABLE'])
history_table = dynamodb.Table(os.environ['REQUESTS_HISTORY_TABLE'])

def lambda_handler(event, context):
    # Parse query parameters
    query_params = event.get('queryStringParameters') or {}
    style = query_params.get('style')
    vegetarian = query_params.get('vegetarian')
    is_open_now = query_params.get('isOpenNow')

    # Build DynamoDB filter expression
    filter_expression = []
    expression_attribute_values = {}
    expression_attribute_names = {}

    if style:
        filter_expression.append('#style = :style')
        expression_attribute_values[':style'] = style
        expression_attribute_names['#style'] = 'style'

    if vegetarian is not None:
        filter_expression.append('vegetarian = :vegetarian')
        expression_attribute_values[':vegetarian'] = vegetarian.lower() == 'true'

    # Scan Restaurants Table
    scan_params = {}
    if filter_expression:
        scan_params['FilterExpression'] = ' AND '.join(filter_expression)
        scan_params['ExpressionAttributeValues'] = expression_attribute_values
        if expression_attribute_names:
            scan_params['ExpressionAttributeNames'] = expression_attribute_names

    response = restaurants_table.scan(**scan_params)
    restaurants = response.get('Items', [])

    # Filter by opening hours if required
    if is_open_now and is_open_now.lower() == 'true':
        current_time = datetime.utcnow().strftime('%H:%M')
        restaurants = [
            r for r in restaurants
            if r['openHour'] <= current_time <= r['closeHour']
        ]

    # Select a restaurant
    recommendation = restaurants[0] if restaurants else None

    # Log request and response
    history_table.put_item(
        Item={
            'requestId': context.aws_request_id,
            'timestamp': datetime.utcnow().isoformat(),
            'parameters': query_params,
            'response': recommendation or {}
        }
    )

    # Return the response
    status_code = 200 if recommendation else 404
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'restaurantRecommendation': recommendation
        })
    }

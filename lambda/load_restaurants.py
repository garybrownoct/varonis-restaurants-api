import json
import boto3
import os

def load_data():
    # Initialize DynamoDB resource
    dynamodb = boto3.resource('dynamodb')
    restaurants_table = dynamodb.Table(os.environ['RESTAURANTS_TABLE'])

    # Read data from JSON file
    with open('restaurants.json', 'r') as f:
        restaurants = json.load(f)

    # Batch write to DynamoDB
    with restaurants_table.batch_writer() as batch:
        for restaurant in restaurants:
            batch.put_item(Item=restaurant)

if __name__ == '__main__':
    load_data()

import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE')
table = dynamodb.Table(table_name)

class DecimalEncoder(json.JSONEncoder):
    """Helper class to convert a DynamoDB item to JSON."""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super(DecimalEncoder, self).default(obj)

def handler(event, context):
    """
    Lambda function handler for API requests
    Supports GET, POST, PUT, DELETE operations
    """
    
    print(f"Event: {json.dumps(event)}")
    
    # Parse the request
    http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
    
    try:
        if http_method == 'OPTIONS':
            # Handle CORS preflight request
            return response(200, {})
        elif http_method == 'GET':
            return handle_get(event)
        elif http_method == 'POST':
            return handle_post(event)
        elif http_method == 'PUT':
            return handle_put(event)
        elif http_method == 'DELETE':
            return handle_delete(event)
        else:
            return response(405, {'error': 'Method not allowed'})
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})

def handle_get(event):
    """Handle GET requests - retrieve items"""
    
    query_params = event.get('queryStringParameters', {})
    
    if query_params and 'id' in query_params:
        # Get single item
        item_id = query_params['id']
        result = table.get_item(Key={'id': item_id})
        
        if 'Item' in result:
            return response(200, result['Item'])
        else:
            return response(404, {'error': 'Item not found'})
    else:
        # Scan all items (limit for demo purposes)
        result = table.scan(Limit=50)
        return response(200, {
            'items': result.get('Items', []),
            'count': len(result.get('Items', []))
        })

def handle_post(event):
    """Handle POST requests - create new item"""
    
    try:
        body = json.loads(event.get('body', '{}'))
        
        if not body:
            return response(400, {'error': 'Request body is required'})
        
        # Generate ID if not provided
        item_id = body.get('id', f"item-{int(datetime.now().timestamp())}")
        
        item = {
            'id': item_id,
            'status': body.get('status', 'active'),
            'data': body.get('data', {}),
            'created_at': datetime.now().isoformat()
        }
        
        table.put_item(Item=item)
        
        return response(201, {
            'message': 'Item created successfully',
            'item': item
        })
    
    except json.JSONDecodeError:
        return response(400, {'error': 'Invalid JSON in request body'})

def handle_put(event):
    """Handle PUT requests - update existing item"""
    
    try:
        body = json.loads(event.get('body', '{}'))
        
        if not body or 'id' not in body:
            return response(400, {'error': 'Item ID is required'})
        
        item_id = body['id']
        
        # Update item
        update_expression = "SET #status = :status, #data = :data, updated_at = :updated_at"
        expression_attribute_names = {
            '#status': 'status',
            '#data': 'data'
        }
        expression_attribute_values = {
            ':status': body.get('status', 'active'),
            ':data': body.get('data', {}),
            ':updated_at': datetime.now().isoformat()
        }
        
        result = table.update_item(
            Key={'id': item_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues='ALL_NEW'
        )
        
        return response(200, {
            'message': 'Item updated successfully',
            'item': result.get('Attributes', {})
        })
    
    except json.JSONDecodeError:
        return response(400, {'error': 'Invalid JSON in request body'})

def handle_delete(event):
    """Handle DELETE requests - delete item"""
    
    query_params = event.get('queryStringParameters', {})
    
    if not query_params or 'id' not in query_params:
        return response(400, {'error': 'Item ID is required'})
    
    item_id = query_params['id']
    
    table.delete_item(Key={'id': item_id})
    
    return response(200, {'message': 'Item deleted successfully'})

def response(status_code, body):
    """Generate HTTP response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }

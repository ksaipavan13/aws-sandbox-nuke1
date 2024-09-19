import boto3

def lambda_handler(event, context):
    iam = boto3.client('iam')
    
    # Get all IAM users
    users = iam.list_users()['Users']
    
    for user in users:
        print(f"Processing user: {user['UserName']}")
        
        # Disable console login
        try:
            iam.delete_login_profile(UserName=user['UserName'])
            print(f"Deleted console login profile for user {user['UserName']}")
        except iam.exceptions.NoSuchEntityException:
            print(f"User {user['UserName']} does not have console login")

        # Deactivate access keys
        access_keys = iam.list_access_keys(UserName=user['UserName'])['AccessKeyMetadata']
        for key in access_keys:
            if key['Status'] == 'Active':
                iam.update_access_key(UserName=user['UserName'], AccessKeyId=key['AccessKeyId'], Status='Inactive')
                print(f"Deactivated access key {key['AccessKeyId']} for user {user['UserName']}")
    
    return {
        'statusCode': 200,
        'body': 'Deactivation complete'
    }


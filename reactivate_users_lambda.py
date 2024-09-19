import boto3

def lambda_handler(event, context):
    iam = boto3.client('iam')
    
    # Get all IAM users
    users = iam.list_users()['Users']
    
    for user in users:
        print(f"Processing user: {user['UserName']}")
        
        # Enable console login
        try:
            iam.create_login_profile(UserName=user['UserName'], Password='TempPassword123!', PasswordResetRequired=True)
            print(f"Re-enabled console login for user {user['UserName']}")
        except iam.exceptions.EntityAlreadyExistsException:
            print(f"Login profile for user {user['UserName']} already exists")

        # Activate access keys
        access_keys = iam.list_access_keys(UserName=user['UserName'])['AccessKeyMetadata']
        for key in access_keys:
            if key['Status'] == 'Inactive':
                iam.update_access_key(UserName=user['UserName'], AccessKeyId=key['AccessKeyId'], Status='Active')
                print(f"Activated access key {key['AccessKeyId']} for user {user['UserName']}")
    
    return {
        'statusCode': 200,
        'body': 'Reactivation complete'
    }


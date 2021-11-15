provider "aws" {
  region = "eu-west-1"
}

resource "aws_kms_key" "this" {
  enable_key_rotation = true
}



# resource "aws_kms_alias" "kms-ws-volume-alias" {
#   name          = "alias/workspace-volume"
#   target_key_id = aws_kms_key.this.key_id
# }

module "users_unencrypted" {
  source = "../../"

  name = "users-unencrypted"

  tags = {
    Secure = "false"
  }
}

module "users_encrypted" {
  source = "../../"

  name_prefix = "users-encrypted-"

  kms_master_key_id = aws_kms_key.this.id

  tags = {
    Secure = "true"
  }
}

resource "aws_sqs_queue_policy" "users_unencrypted_policy" {
  queue_url = module.users_unencrypted.sqs_queue_id

  policy = <<EOF
  {
    "Version": "2008-10-17",
    "Id": " policy",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Action": [
          "SQS:SendMessage",
          "SQS:ReceiveMessage"
        ],
        "Resource": "${module.users_unencrypted.sqs_queue_arn}"
      }
    ]
  }
  EOF
}

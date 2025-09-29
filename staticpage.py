import json
from typing import Optional, TypedDict

import pulumi
from pulumi import ResourceOptions
from pulumi_aws import s3


class StaticPageArgs(TypedDict):
    index_content: pulumi.Input[str]
    """The HTML content for index.html."""


class StaticPage(pulumi.ComponentResource):
    website_url: pulumi.Output[str]
    """The URL of the static website."""

    def __init__(self,
                 name: str,
                 args: StaticPageArgs,
                 opts: Optional[ResourceOptions] = None) -> None:

        super().__init__('python-components:index:StaticPage', name, {}, opts)

        # Create a bucket and expose a website index document.
        bucket = s3.Bucket(
            f'{name}-bucket',
            website=s3.BucketWebsiteArgs(index_document='index.html'),
            opts=ResourceOptions(parent=self))

        # Create a bucket object for the index document.
        s3.BucketObject(
            f'{name}-index-object',
            bucket=bucket.bucket,
            key='index.html',
            content=args.get("index_content"),
            content_type='text/html',
            opts=ResourceOptions(parent=bucket))

        # Set the access policy for the bucket so all objects are readable.
        s3.BucketPolicy(
            f'{name}-bucket-policy',
            bucket=bucket.bucket,
            policy=bucket.bucket.apply(_allow_getobject_policy),
            opts=ResourceOptions(parent=bucket))

        self.website_url = bucket.website_endpoint

        # By registering the outputs on which the component depends, we ensure
        # that the Pulumi CLI will wait for all the outputs to be created before
        # considering the component itself to have been created.
        self.register_outputs({
            'websiteUrl': bucket.website_endpoint,
        })


def _allow_getobject_policy(bucket_name: str) -> str:
    return json.dumps({
        'Version': '2012-10-17',
        'Statement': [
            {
                'Effect': 'Allow',
                'Principal': '*',
                'Action': ['s3:GetObject'],
                'Resource': [
                    f'arn:aws:s3:::{bucket_name}/*',  # policy refers to bucket name explicitly
                ],
            },
        ],
    })

# Copyright 2016-2021, Pulumi Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
from typing import Optional

from pulumi import Inputs, ResourceOptions
from pulumi_aws import s3
import pulumi


class StaticPageArgs:

    index_content: pulumi.Input[str]
    """The HTML content for index.html."""

    @staticmethod
    def from_inputs(inputs: Inputs) -> 'StaticPageArgs':
        return StaticPageArgs(index_content=inputs['indexContent'])

    def __init__(self, index_content: pulumi.Input[str]) -> None:
        self.index_content = index_content


class StaticPage(pulumi.ComponentResource):
    bucket: s3.Bucket
    website_url: pulumi.Output[str]

    def __init__(self,
                 name: str,
                 args: StaticPageArgs,
                 props: Optional[dict] = None,
                 opts: Optional[ResourceOptions] = None) -> None:

        super().__init__('xyz:index:StaticPage', name, props, opts)

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
            content=args.index_content,
            content_type='text/html',
            opts=ResourceOptions(parent=bucket))

        # Set the access policy for the bucket so all objects are readable.
        s3.BucketPolicy(
            f'{name}-bucket-policy',
            bucket=bucket.bucket,
            policy=bucket.bucket.apply(_allow_getobject_policy),
            opts=ResourceOptions(parent=bucket))

        self.bucket = bucket
        self.website_url = bucket.website_endpoint

        self.register_outputs({
            'bucket': bucket,
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

#  Copyright 2016-2021, Pulumi Corporation.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

from typing import Optional

from pulumi import Inputs, ResourceOptions
from pulumi.provider import ConstructResult
import pulumi.provider as provider

import xyz_provider
from xyz_provider.staticpage import StaticPage, StaticPageArgs


class Provider(provider.Provider):

    def __init__(self) -> None:
        super().__init__(xyz_provider.__version__)

    def construct(self,
                  name: str,
                  resource_type: str,
                  inputs: Inputs,
                  options: Optional[ResourceOptions] = None) -> ConstructResult:

        if resource_type == 'xyz:index:StaticPage':
            return _construct_static_page(name, inputs, options)

        raise Exception(f'Unknown resource type {resource_type}')


def _construct_static_page(name: str,
                           inputs: Inputs,
                           options: Optional[ResourceOptions] = None) -> ConstructResult:

    # Create the component resource.
    static_page = StaticPage(name, StaticPageArgs.from_inputs(inputs), dict(inputs), options)

    # Return the component resource's URN and outputs as its state.
    return provider.ConstructResult(
        urn=static_page.urn,
        state={
            'bucket': static_page.bucket,
            'websiteUrl': static_page.website_url
        })

from typing import Optional, TypedDict

import pulumi
from pulumi import ResourceOptions
import pulumi_random as random

class RandomComponentArgs(TypedDict):
    length: pulumi.Input[int]
    """The desired password length."""


class RandomComponent(pulumi.ComponentResource):
    password: pulumi.Output[str]
    """The randomly-generated password."""

    def __init__(self,
                 name: str,
                 args: RandomComponentArgs,
                 opts: Optional[ResourceOptions] = None) -> None:

        super().__init__('python-components:index:RandomComponent', name, {}, opts)

        # Generate a random password.
        password = random.RandomPassword(
            f'{name}-password',
            length=args.get("length"),
            opts=ResourceOptions(parent=self)
        )
        
        self.password = password.result

        # By registering the outputs on which the component depends, we ensure
        # that the Pulumi CLI will wait for all the outputs to be created before
        # considering the component itself to have been created.
        self.register_outputs({
            'password': password.result,
        })

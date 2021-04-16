from distutils.core import setup

setup(
    name='xyz_provider',
    version='0.0.1',
    description='XYZ Pulumi Provider',
    packages=['xyz_provider'],
    package_data={'xyz_provider': ['py.typed']},
    zip_safe=False)

## TODO Correct Pulumi SDK dependency information

from distutils.core import setup
import os.path


PKG = 'xyz_provider'


def read_version():
    with open(os.path.join(os.path.dirname(__file__), PKG, 'VERSION')) as version_file:
        version = version_file.read().strip()
    return version


setup(
    name=PKG,
    version=read_version(),
    description='XYZ Pulumi Provider',
    packages=[PKG],
    package_data={PKG: ['py.typed', 'VERSION']},
    zip_safe=False,
    install_requires=[
        'pulumi>=3.0.0',
        'pulumi_aws>=4.0.0',
    ],
)

import os.path

with open(os.path.join(os.path.dirname(__file__), 'VERSION')) as version_file:
    __version__ = version_file.read().strip()

with open(os.path.join(os.path.dirname(__file__), 'schema.json')) as schema_file:
    __schema__ = schema_file.read().strip()

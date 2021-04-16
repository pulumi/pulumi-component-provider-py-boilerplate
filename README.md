# xyz Pulumi Component Provider (Python)

This repo builds a working Pulumi component provider in Python. You
can use it as boilerplate for creating your own provider. Simply
search-replace `xyz` with your chosen name.

Pulumi component providers make
[component resources](https://www.pulumi.com/docs/intro/concepts/resources/#components)
available to Pulumi code in all supported programming languages.
Specifically, `xyz` component provider defines an example `StaticPage`
component resource that provisions a public AWS S3 HTML page.

The important pieces include:

- [schema.json](schema.json) declaring the `StaticPage` interface

- [xyz_provider](provider/cmd/pulumi-resource-xyz/xyz_provider/provider.py) package
  implementing `StaticPage` using typical Pulumi Python code

From here, the build generates:

- SDKs for Python, Go, .NET, and Node (under `sdk/`)

- `pulumi-resource-xyz` Pulumi plugin (under `bin/`)

Users can deploy `StaticPage` instances in their language of choice,
as seen in the [TypeScript example](examples/simple/index.ts). Only
two things are needed to run `pulumi up`:

- the code needs to reference the `xyz` SDK package

- `pulumi-resource-xyz` needs to be on `PATH` for `pulumi` to find it


## Prerequisites

- Pulumi CLI
- Python 3.6+
- Node.js
- Yarn
- Go 1.15
- Node.js (to build the Node SDK)
- .NET Code SDK (to build the .NET SDK)


## Build and Test


## Naming

The `xyz` plugin must be packaged as a `pulumi-resource-xyz` script or
binary (in the format `pulumi-resource-<provider>`).

While the plugin must follow this naming convention, the SDK package
naming can be custom.

## Packaging

TODO details on tarball packaging. Ideally Makefile contains targets
for generating the tarballs.


## StaticPage Example

### Schema

### Implementation

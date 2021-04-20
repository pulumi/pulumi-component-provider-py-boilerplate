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

```bash

# Regenerate SDKs
make generate

# Build and install the provider and SDKs
make build
make install

# Ensure the pulumi-provider-xyz script is on PATH (for testing)
$ export PATH=$PATH:$PWD/bin

# Test Node.js SDK
$ cd examples/simple
$ yarn install
$ yarn link @pulumi/xyz
$ pulumi stack init test
$ pulumi config set aws:region us-east-1
$ pulumi up

```

## Naming

The `xyz` plugin must be packaged as a `pulumi-resource-xyz` script or
binary (in the format `pulumi-resource-<provider>`).

While the plugin must follow this naming convention, the SDK package
naming can be custom.

## Packaging

The `xyz` plugin can be packaged as a tarball for distribution:

```bash
$ make dist

$ ls dist/
pulumi-resource-xyz-v0.0.1-darwin-amd64.tar.gz
pulumi-resource-xyz-v0.0.1-windows-amd64.tar.gz
pulumi-resource-xyz-v0.0.1-linux-amd64.tar.gz
```

Users can install the plugin with:

```bash
pulumi plugin install resource xyz 0.0.1 --file dist/pulumi-resource-xyz-v0.0.1-darwin-amd64.tar.gz
```

The tarball only includes the `xyz_provider` sources. During the
installation phase, `pulumi` will use the user's system Python command
to rebuild a virtual environment and restore dependencies (such as
Pulumi SDK).

TODO explain custom server hosting in more detail.


## StaticPage Example

### Schema

The component resource's type [token](schema.json#L4)
is `xyz:index:StaticPage` in the
format of `<package>:<module>:<type>`. In this case, it's in the `xyz`
package and `index` module. This is the same type token passed inside
the implementation of `StaticPage` in
[staticpage.py](provider/cmd/pulumi-resource-xyz/xyz_provider/staticpage.py#L46),
and also the same token referenced in `construct` in
[provider.py](provider/cmd/pulumi-resource-xyz/xyz_provider/provider.py#L36).

This component has a required `indexContent` input property typed as
`string`, and two required output properties: `bucket` and
`websiteUrl`. Note that `bucket` is typed as the
`aws:s3/bucket:Bucket` resource from the `aws` provider (in the schema
the `/` is escaped as `%2F`).

Since this component returns a type from the `aws` provider, each SDK
must reference the associated Pulumi `aws` SDK for the language. For
the .NET, Node.js, and Python SDKs, dependencies are specified in the
[language section](schema.json#31) of the schema.

### Implementation

The key method to implement is
[construct](provider/cmd/pulumi-resource-xyz/xyz_provider/provider.py#L36)
on the `Provider` class. It receives `Inputs` representing arguments the user passed,
and returns a `ConstructResult` with the new StaticPage resource `urn` an state.

It is important that the implementation aligns the structure of inptus
and outputs with the interface declared in `schema.json`.

---
title: "Bicep modules and how scopes work"
description: "Why a module that compiles fine in one file fails in another, what targetScope actually controls, and the three scope mistakes that cost the most time."
track: "bicep"
level: "working"
order: 10
objectives:
  - "Explain what targetScope controls and where Bicep gets it from"
  - "Deploy a module into a resource group from a subscription-scoped file"
  - "Predict what resourceGroup() returns inside a module before you run it"
  - "Debug a nested deployment name collision in a module loop"
prerequisites: []
tags: ["azure", "bicep", "iac", "arm"]
updated: 2026-08-07
draft: false
---

Most people learn Bicep by writing one file that deploys into one resource group.
That works right up until the day you need the template to create the resource
group too. Then you add `targetScope = 'subscription'` at the top, and every
resource in the file starts throwing errors that have nothing obvious to do with
the change you made.

The confusion is almost always the same thing: Bicep has two scopes in play at
once, and they are set in two different files. Once you can name both of them,
the error messages start reading like instructions instead of noise.

## The problem this solves

Every Bicep file declares one target scope. It is the kind of thing the file
deploys into: a resource group, a subscription, a management group, or a tenant.
If you do not declare one, it is `resourceGroup`.

```bicep
// No targetScope line, so this is targetScope = 'resourceGroup'
resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stexample001'
  location: 'eastus2'
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
}
```

A resource group cannot contain another resource group, so the moment you want a
template that creates its own resource groups, the whole file has to move up to
subscription scope. And a subscription cannot directly contain a storage account.
So the storage account has to move somewhere else.

That somewhere else is a module. A module is a separate Bicep file with its own
target scope, invoked from the parent with an explicit `scope`. It is the only
mechanism Bicep has for deploying across scope boundaries, which is why modules
and scopes are really one topic rather than two.

## Minimum working example

Two files. The parent runs at subscription scope and creates a resource group.
The module runs at resource group scope and creates a storage account inside it.

`main.bicep`:

```bicep
targetScope = 'subscription'

param location string = 'eastus2'
param environment string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-app-${environment}'
  location: location
}

module storage 'modules/storage.bicep' = {
  name: 'storage-${environment}'
  scope: rg
  params: {
    location: location
    environment: environment
  }
}

output storageAccountName string = storage.outputs.storageAccountName
```

`modules/storage.bicep`:

```bicep
// No targetScope line, so this file is resourceGroup scoped.
param location string
param environment string

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stapp${environment}${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

output storageAccountName string = sa.name
```

Deploy it at subscription scope:

```bash
az deployment sub create \
  --name app-infra \
  --location eastus2 \
  --template-file main.bicep \
  --parameters environment=dev
```

Note the command: `az deployment sub create`, not `az deployment group create`.
The CLI subcommand has to match the file's target scope. If they disagree you get
an error about the template not being valid for the deployment scope, which reads
like a template problem and is actually a command problem.

## How it actually behaves

There are two scopes, and keeping them separate is most of the battle.

The **declared scope** is what a file says about itself, through `targetScope`.
It controls which resource types the file is allowed to declare and which scope
functions are available inside it.

The **invoked scope** is where the parent asks for that module to be deployed,
through the `scope` property on the module declaration. It has to be compatible
with the module's declared scope.

When those two agree, the deployment works. When they disagree, Bicep rejects it
at compile time, before anything reaches Azure.

`scope` accepts a resource symbol, or one of the scope functions:

```bicep
targetScope = 'subscription'

// Into a resource group this same file creates
module a 'modules/storage.bicep' = {
  name: 'into-new-rg'
  scope: rg
  params: { location: location, environment: environment }
}

// Into a resource group that already exists
module b 'modules/storage.bicep' = {
  name: 'into-existing-rg'
  scope: resourceGroup('rg-shared-prod')
  params: { location: location, environment: environment }
}

// Into a different subscription entirely, at resource group scope
module c 'modules/storage.bicep' = {
  name: 'into-other-sub'
  scope: resourceGroup('00000000-0000-0000-0000-000000000000', 'rg-shared-prod')
  params: { location: location, environment: environment }
}
```

Omitting `scope` means the module inherits the parent's scope. That is fine when
the scopes match and a bug when they do not, which is the first trip-up below.

Module outputs are available on the module symbol under `outputs`, and they
create an implicit dependency. Referencing `storage.outputs.storageAccountName`
tells ARM that whatever consumes it has to wait for the storage module. You
almost never need `dependsOn` if you are passing outputs around.

One thing outputs cannot do is carry secrets. Deployment outputs are readable by
anyone with read access to the deployment history, so a module cannot mark an
output `@secure()`. Pass a Key Vault reference instead of the value itself.

## Three things that trip people up

### 1. A module with no targetScope is a resource group module

This is the one that produces the most confusing error, because the file that is
wrong is not the file the error points at.

A module file with no `targetScope` line is `resourceGroup` scoped. If a
subscription-scoped parent invokes it without a `scope`, the module inherits
subscription scope, which does not match what the module declared, and Bicep
refuses to compile.

```bicep
targetScope = 'subscription'

// Broken: storage.bicep is resourceGroup scoped, but with no scope property
// this module inherits the parent's subscription scope.
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: { location: location, environment: environment }
}
```

The fix is one line, either `scope: rg` at the call site, or an explicit
`targetScope` in the module if it really was meant to run at subscription scope.
The habit worth building is putting `targetScope` at the top of every Bicep file
you write, including the resource group scoped ones where it is the default.
It costs one line and it makes the mismatch obvious in review.

### 2. resourceGroup() inside a module is the module's resource group

Scope functions resolve against the scope the file is running at, not the scope
of the file that invoked it. So `resourceGroup()` inside a module returns the
resource group that module was deployed into.

That sounds obvious until a common shortcut meets it:

```bicep
// Inside a module. Convenient, and quietly coupled to the call site.
param location string = resourceGroup().location
```

That default is not the location of the resource group you were thinking about
when you wrote the module. It is the location of whichever resource group the
parent happens to point the module at, which can be a different region than the
rest of the deployment. Change `scope:` in the parent six months later and the
module silently deploys to a new region.

Pass location in as an explicit parameter. The extra line at each call site is
the point: it makes the region a decision the caller states out loud.

The related gotcha is that `resourceGroup()` is not available at all in a
subscription-scoped file. There is no resource group in context, so calls to it
fail to compile. Use `subscription()` there. Both functions exist at resource
group scope, which is why the mistake usually surfaces only after a file is
promoted to subscription scope.

### 3. Module names are deployment names, and they collide in loops

The `name` property on a module is the name of the nested ARM deployment it
creates. Deployment names are unique per scope, so two deployments with the same
name in the same scope means the second overwrites the first.

Inside a loop with a static name, every iteration writes to the same deployment:

```bicep
// Broken: every iteration creates a deployment called 'storage'.
module storage 'modules/storage.bicep' = [for env in environments: {
  name: 'storage'
  scope: rg
  params: { location: location, environment: env }
}]
```

What makes this expensive to debug is that it often appears to work. The
resources get created, because each iteration still submits its own template. It
is the deployment history that gets clobbered, so you lose the record of what ran
and the outputs from every iteration but the last, and `what-if` output stops
matching reality.

Include the loop variable:

```bicep
module storage 'modules/storage.bicep' = [for env in environments: {
  name: 'storage-${env}'
  scope: rg
  params: { location: location, environment: env }
}]

output firstAccountName string = storage[0].outputs.storageAccountName
```

Two limits worth knowing while you are in here. Deployment names cap at 64
characters, so a generated name built from several interpolated parameters can
get truncated into a collision. And a resource group keeps 800 deployments in
history, after which the oldest are deleted automatically, so a pipeline that
deploys per-commit with unique names will roll its own history off faster than
you expect.

## Exercise

Take the two files from the minimum working example and extend them.

1. Add a second resource group, `rg-data-${environment}`, to `main.bicep`.
2. Deploy the storage module into both resource groups using a single loop over
   an array of the two resource group symbols.
3. Output an array of both storage account names.

Then run `az deployment sub what-if` with the same arguments as the create
command and read the output before deploying anything. Two things to check: the
nested deployment names are distinct, and the storage account names are distinct.
If they are not, you have reproduced trip-up three on purpose, which is a
cheaper way to learn it than finding it in a pipeline.

For step 2 you will need to know that a module loop can iterate over resource
symbols directly, and that `scope` accepts the loop variable.

## References

- [Bicep modules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/modules)
- [Understand the structure and syntax of Bicep files](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file)
- [Scope functions](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-scope)
- [Deploy resources to a subscription](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-subscription)
- [Deploy resources to a management group](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-to-management-group)
- [Bicep loops](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops)

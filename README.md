# X Smart Evidence

**X Smart Evidence** is a standalone, commercial-ready evidence and chain-of-custody management resource for FiveM.

**Developer:** MR X  
**Studio:** X Studio  
**Version:** 1.0.0  
**Resource:** `x_smart_evidence`

---

## Features

- Dark, premium MR X / X Studio NUI
- Case management
- Automatic case numbering (`XS-0001`, `XS-0002`, etc.)
- Evidence records attached to cases
- Evidence types and statuses
- Serial/identifier tracking
- Quantity tracking
- Storage location tracking
- Tags and searchable metadata
- Chain-of-custody history
- Check-out / return workflow
- Release workflow
- Controlled destruction workflow
- Permanent deletion protection
- Server-side permission checks
- Configurable ACE permissions
- Persistent JSON storage with no database dependency
- Audit log
- Lua exports for MDT/dispatch/other resources
- Clean configuration file
- No required third-party UI library
- No external web requests
- No telemetry or hidden callbacks
- Included MR X logo and GitHub-ready documentation

## Requirements

- FXServer / FiveM with OneSync enabled
- A current FiveM server artifact
- No framework is required

The resource uses the modern `fxmanifest.lua` format and CfxLua/Lua 5.4 runtime.

## Installation

1. Put the `x_smart_evidence` folder in your server's resources directory.
2. Make sure `data/storage.json` exists. The included file is ready to use.
3. Add this to `server.cfg`:

```cfg
ensure x_smart_evidence
```

4. Add ACE permissions:

```cfg
add_ace group.police xsmart.evidence allow
add_ace group.police xsmart.evidence.destroy allow

add_ace group.admin xsmart.evidence allow
add_ace group.admin xsmart.evidence.admin allow
add_ace group.admin xsmart.evidence.destroy allow
```

5. Restart the resource/server.

Open the system with `/evidence` or the configured key.

## Permissions

The default permission is:

```text
xsmart.evidence
```

Admin deletion permission:

```text
xsmart.evidence.admin
```

Evidence destruction permission:

```text
xsmart.evidence.destroy
```

You can change these in `config.lua`.

## Storage

The default edition uses:

```text
data/storage.json
```

This makes the resource dependency-free and easy to deploy.

For larger production servers, X Studio can replace the storage layer with an SQL adapter while keeping the same UI and export API.

## Exports

### Get a case

```lua
local case = exports.x_smart_evidence:GetCase(caseId)
```

### Get evidence

```lua
local evidence = exports.x_smart_evidence:GetEvidence(evidenceId)
```

### Get all cases

```lua
local cases = exports.x_smart_evidence:GetAllCases()
```

### Get all evidence

```lua
local evidence = exports.x_smart_evidence:GetAllEvidence()
```

### Create a case from another resource

```lua
local case, err = exports.x_smart_evidence:CreateCase({
    title = 'Robbery Investigation',
    description = 'Bank robbery investigation.',
    location = 'Downtown',
    priority = 'high'
}, 'MDT Integration')
```

## Framework Integration

The resource is intentionally standalone.

This makes it suitable for:

- QBCore
- Qbox
- ESX
- vMenu
- custom frameworks
- custom police/MDT systems

A framework-specific adapter can be added to connect jobs, ranks, callsigns, identifiers, inventory evidence items, and department permissions.

## Commercial Use

This package is authored by **MR X** under **X Studio**.

You may deploy and sell this resource only according to the commercial license supplied with the package. Do not redistribute the source as a free public release or claim authorship.

If you resell or provide the resource as part of a server development package, the license holder remains MR X / X Studio unless a separate written agreement says otherwise.

## Security

Important actions are validated server-side. Client UI input is never treated as trusted permission data.

The resource does not include:

- credential collection
- hidden HTTP requests
- remote code loading
- resource infection logic
- global bans
- unauthorized file access
- obfuscated malicious code

## Support

Developer: **MR X**  
Studio: **X Studio**

For commercial customization, framework integration, SQL storage, MDT integration, evidence item integration, photo storage, department permissions, or additional workflows, contact X Studio.

## Changelog

See `CHANGELOG.md`.

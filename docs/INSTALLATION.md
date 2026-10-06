# Installation Guide

## Folder

Place:

```text
x_smart_evidence/
```

inside your FiveM resources folder.

## server.cfg

```cfg
ensure x_smart_evidence
```

## ACE

Minimum:

```cfg
add_ace group.police xsmart.evidence allow
```

Admin:

```cfg
add_ace group.admin xsmart.evidence.admin allow
add_ace group.admin xsmart.evidence.destroy allow
```

If your server uses identifiers, ACE can also be assigned directly:

```cfg
add_ace identifier.license:YOUR_LICENSE xsmart.evidence allow
```

## First Start

The resource creates/updates:

```text
data/storage.json
```

Do not delete this file if you want to preserve evidence data.

## Commands

```text
/evidence
```

The command is configurable in `config.lua`.

## Keybind

The default key is F7. Players can change FiveM keybinds through the normal key mapping system.

## Recommended Production Setup

Back up `data/storage.json` regularly.

For high-volume servers, use an SQL storage adapter. The included JSON adapter is intended to keep the commercial package dependency-free.

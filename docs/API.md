# API

Resource name:

```text
x_smart_evidence
```

## Exports

```lua
exports.x_smart_evidence:GetCase(caseId)
exports.x_smart_evidence:GetEvidence(evidenceId)
exports.x_smart_evidence:GetAllCases()
exports.x_smart_evidence:GetAllEvidence()
```

Create a case:

```lua
local case, err = exports.x_smart_evidence:CreateCase({
    title = 'Case title',
    description = 'Case description',
    location = 'Mission Row',
    priority = 'high'
}, 'External MDT')
```

## Example MDT Integration

```lua
RegisterCommand('makeevidencecase', function()
    local case = exports.x_smart_evidence:CreateCase({
        title = 'Evidence Review',
        description = 'Created from an MDT workflow.',
        location = 'Mission Row',
        priority = 'normal'
    }, 'My MDT')

    if case then
        print(('Created %s'):format(case.caseNumber))
    end
end)
```

The server remains authoritative for evidence records and permissions.

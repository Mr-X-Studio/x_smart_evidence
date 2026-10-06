Config = {}

Config.ResourceName = 'x_smart_evidence'
Config.Brand = {
    developer = 'MR X',
    studio = 'X Studio',
    product = 'X Smart Evidence'
}

-- General behavior
Config.OpenCommand = 'evidence'
Config.OpenKey = 'F7'
Config.AllowCommand = true
Config.RequireAce = true
Config.AcePermission = 'xsmart.evidence'

-- Standalone by default. Framework hooks can be added through the exports below.
-- Supported value: 'standalone'
Config.Framework = 'standalone'

-- Evidence settings
Config.MaxTitleLength = 80
Config.MaxDescriptionLength = 500
Config.MaxNoteLength = 500
Config.MaxSearchLength = 80
Config.MaxEvidencePerCase = 500
Config.MaxCases = 5000
Config.MaxCustodyEntries = 100
Config.CaseNumberPrefix = 'XS'
Config.AutoCaseNumber = true

Config.EvidenceTypes = {
    { value = 'physical', label = 'Physical Evidence' },
    { value = 'weapon', label = 'Weapon' },
    { value = 'document', label = 'Document' },
    { value = 'digital', label = 'Digital Evidence' },
    { value = 'photo', label = 'Photo' },
    { value = 'video', label = 'Video' },
    { value = 'biological', label = 'Biological' },
    { value = 'narcotics', label = 'Narcotics' },
    { value = 'currency', label = 'Currency' },
    { value = 'vehicle', label = 'Vehicle' },
    { value = 'other', label = 'Other' }
}

Config.EvidenceStatuses = {
    { value = 'stored', label = 'Stored' },
    { value = 'checked_out', label = 'Checked Out' },
    { value = 'released', label = 'Released' },
    { value = 'destroyed', label = 'Destroyed' }
}

Config.DefaultLocations = {
    'Evidence Room',
    'Property Locker',
    'Digital Evidence Vault',
    'Cold Storage',
    'External Lab'
}

-- Optional location restriction. Leave empty to allow evidence management anywhere.
Config.RestrictedLocations = {}

-- Security / role labels. For standalone servers, these are display values.
-- If RequireAce is true, ACE controls access.
Config.Roles = {
    police = 'Police',
    sheriff = 'Sheriff',
    investigator = 'Investigator',
    admin = 'Administrator'
}

Config.Audit = {
    enabled = true,
    maxEntries = 5000
}

-- JSON persistence is dependency-free and survives resource restarts.
-- For high-volume production environments, a SQL adapter can be added later
-- without changing the client UI/API surface.
Config.StorageFile = 'data/storage.json'

Config.Commands = {
    newCase = 'newcase',
    addEvidence = 'addevidence',
    viewCase = 'viewcase'
}

Config.UI = {
    accent = '#d8d8d8',
    dark = '#090909',
    showBrand = true
}

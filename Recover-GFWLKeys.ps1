<#
.SYNOPSIS
  Recover product keys of previously activated Games for Windows LIVE (GFWL) titles.

.DESCRIPTION
  This script recovers product keys for previously activated Games for Windows LIVE (GFWL) titles
  by locating and decrypting each title's activation data.

  The script performs the following actions:
    - Scans the default GFWL titles directory (or a user-specified root path)
    - Identifies valid title-specific subdirectories containing "Token.bin" activation files
    - Decrypts each product key using Windows Data Protection API (DPAPI)
    - Validates the product key format and logs warnings for any decryption issues
    - Outputs the recovered product keys alongside their corresponding title IDs and names

  Example output:

  Recovered 2 GFWL product keys

  Title ID  Product Key                    Title Name
  --------  -----------                    ----------
  4D5307D6  ABCDE-FGHIJ-KLMNO-PQRST-UVWXY  Shadowrun
  4E4D0FA1  ZYXWV-UTSRQ-PONML-KJIHG-FEDCB  Dark Souls: Prepare to Die Edition

.PARAMETER BasePath
  Optional. Specifies the root path to scan for GFWL titles. Defaults to "%LOCALAPPDATA%\Microsoft\XLive\Titles".

.PARAMETER AllowWebLookup
  Optional. If specified, the script will attempt to fetch title names from the dbox.tools API for titles not found in the local cache.
  This requires an internet connection and may fail if the API is unavailable.

.PARAMETER Help
  Optional. Displays usage information for the script.

.PARAMETER Verbose
  Optional. Enables verbose output for debugging and detailed logging.

.INPUTS
  None. This script does not accept pipeline input.

.OUTPUTS
  Outputs a count of any recovered GFWL product keys, along with a formatted table of recovered keys, title IDs, and title names.

.EXAMPLE
  .\Recover-GFWLKeys.ps1
  Scans the default GFWL titles directory and outputs recovered product keys.

.EXAMPLE
  .\Recover-GFWLKeys.ps1 -AllowWebLookup
  Scans the default GFWL titles directory, allows fetching of title names from the dbox.tools API for titles not found in the local cache, and outputs recovered product keys.

.EXAMPLE
  .\Recover-GFWLKeys.ps1 -BasePath "D:\Custom\XLive\Titles"
  Uncommon. Scans a custom directory for GFWL titles and outputs recovered product keys.

.EXAMPLE
  .\Recover-GFWLKeys.ps1 -Verbose
  Runs the script with verbose output enabled.

.EXAMPLE
  .\Recover-GFWLKeys.ps1 -Help
  Shows usage information.

.NOTES
  Requires PowerShell 5.1 or later (available with Windows 10 and later). No administrator privileges needed.

  Attribution:
  This script uses title data from dbox.tools (https://dbox.tools/titles/gfwl/) and its API (https://dbox.tools/api/docs).

.LINK
  https://github.com/elusiveeagle/recover-gfwl-keys
  https://dbox.tools/titles/gfwl/
  https://dbox.tools/api/docs

.LIMITATIONS
  Each Windows user account stores GFWL activation data separately.
  In addition, product keys are encrypted using the Windows Data Protection API (DPAPI) specific to the user account that activated the titles.
  Run this script under the same account used to activate the titles.

.PRIVACY
  By default, this script does not transmit any data over the network. All operations are performed locally.
  If the -AllowWebLookup parameter is used, however, the script will fetch title names from the dbox.tools API for titles not found in the local cache.
  Ensure you trust the source of this script and review its contents before running it.

.VERSION
  1.3.0
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
  [Parameter(Position = 0, HelpMessage = 'Root path to scan for GFWL titles.')]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$BasePath = "$env:LOCALAPPDATA\Microsoft\XLive\Titles",

  [Parameter(Position = 1, HelpMessage = 'Allow fetching of title names from dbox.tools.')]
  [switch]$AllowWebLookup,

  [Parameter(Position = 2, HelpMessage = 'Display usage information.')]
  [Alias('?', 'h')]
  [switch]$Help
)

if ($Help) {
  Get-Help -Detailed $MyInvocation.MyCommand.Path
  exit 0
}

Write-Verbose 'STEP 1: Verifying requirements...'

# Verify root directory path exists
if (-not (Test-Path $BasePath -PathType Container)) {
  Write-Warning @"
The scan path does not exist: $BasePath

This is expected if no GFWL titles have been installed or activated under the current Windows user account.
"@
  exit 0
}

# Attempt to load the required .NET assemblies
try {
  Add-Type -AssemblyName System.Security -ErrorAction Stop
  Write-Verbose 'Successfully loaded System.Security assembly.'
}
catch {
  Write-Error 'FATAL: Failed to load Data Protection API types. Ensure you have the System.Security assembly available.'
  exit 1
}

# Verify that ProtectedData exists
try {
  # Referencing the type will throw if missing
  $null = [System.Security.Cryptography.ProtectedData]
  Write-Verbose 'Successfully verified ProtectedData type.'
}
catch {
  Write-Error 'FATAL: ProtectedData type not found after loading assemblies. Unable to decrypt product keys.'
  exit 1
}

Write-Verbose 'STEP 2: Initializing title map using data from dbox.tools (https://dbox.tools/titles/gfwl/)...'

# Product key regex pattern (5×5 alphanumeric groups)
# Matches GFWL product keys in the format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX (5 groups of 5 alphanumeric characters).
New-Variable -Name ProductKeyPattern -Value '^([0-9A-Z]{5}-){4}[0-9A-Z]{5}$' -Scope Script -Option Constant

# Title ID regex pattern (8 hex digits)
# Matches GFWL Title IDs, which are always 8-character hexadecimal strings (e.g., 4D5308B1).
New-Variable -Name TitleIdPattern -Value '^[0-9A-F]{8}$' -Scope Script -Option Constant

#region TitleMap JSON
$TitleMapJson = @'
{
  "33390FA0":  "7 Wonders 3",
  "33390FA1":  "Chainz 2: Relinked",
  "35530FA0":  "Cubis Gold",
  "35530FA1":  "Cubis Gold 2",
  "35530FA2":  "Ranch Rush 2",
  "355A0FA0":  "Mahjongg Dimensions",
  "36590FA0":  "TextTwist 2",
  "36590FA1":  "Super TextTwist",
  "41560829":  "007: Quantum of Solace",
  "41560FA0":  "Call of Duty 4",
  "41560FA1":  "Call of Duty: World at War",
  "41560FA2":  "Singularity",
  "41560FA3":  "Transformers: War for Cybertron",
  "41560FA4":  "Blur",
  "41560FA5":  "Prototype",
  "41560FA6":  "007: Blood Stone",
  "415807D5":  "BlazBlue: Calamity Trigger",
  "425307D6":  "Fallout 3",
  "42530FA0":  "Hunted Demon’s Forge",
  "425607F3":  "Tron: Evolution",
  "42560FA0":  "LEGO Pirates of the Caribbean: The Video Game",
  "434307DE":  "Lost Planet: Extreme Condition: Colonies Edition",
  "434307F4":  "Street Fighter IV",
  "434307F7":  "Resident Evil 5",
  "43430803":  "Dark Void",
  "43430808":  "Lost Planet 2",
  "4343080E":  "Dead Rising 2",
  "43430FA0":  "Super Street Fighter IV: Arcade Edition",
  "43430FA1":  "Resident Evil: Operation Raccoon City",
  "43430FA2":  "Dead Rising 2 Off The Record",
  "43430FA5":  "Street Fighter X Tekken",
  "434D0820":  "Dirt 2",
  "434D082F":  "Fuel",
  "434D0831":  "F1 2010",
  "434D083E":  "Operation Flashpoint: Red River",
  "434D0FA0":  "Dirt 3",
  "434D0FA1":  "F1 2011",
  "44540FA0":  "Crash Time 4",
  "44540FA1":  "Crash Time 4 Demo",
  "4541091C":  "Dragon Age: Awakening",
  "4541091F":  "Battlefield: Bad Co. 2",
  "45410920":  "Mass Effect 2",
  "45410921":  "Dragon Age: Origins",
  "45410935":  "Bulletstorm",
  "45410FA1":  "Medal of Honor",
  "45410FA2":  "Need for Speed: Shift",
  "45410FA3":  "Dead Space 2",
  "45410FA4":  "Bulletstrom Demo",
  "45410FA5":  "Dragon Age 2",
  "45410FA8":  "Crysis 2",
  "45410FAB":  "The Sims 3",
  "45410FAC":  "The Sims 3: Late Night",
  "45410FAD":  "The Sims 3: Ambitions",
  "45410FAE":  "World Adventures",
  "45410FAF":  "The Sims Medieval",
  "45410FB1":  "Darkspore",
  "45410FB2":  "Shift 2: Unleashed",
  "45410FB3":  "Spore",
  "45410FB4":  "The Sims 3 Generations",
  "45410FB5":  "Alice: Madness Returns",
  "45410FB6":  "Harry Potter and the Deathly Hallows: Part 2",
  "45410FB7":  "The Sims Medieval Pirates \u0026 Nobles",
  "45410FB8":  "Tiger Woods PGA Tour 12: The Masters",
  "454D07D4":  "FlatOut: Ultimate Carnage",
  "46450FA0":  "Divinity II: The Dragon Knight Saga",
  "46450FA1":  "Cities XL 2011",
  "46450FA2":  "The Next Big Thing",
  "46450FA3":  "Faery",
  "46450FA4":  "Pro Cycling Manager",
  "46550FA0":  "Jewel Quest 5",
  "46550FA1":  "Family Feud Dream Home",
  "48450FA0":  "AFL Live",
  "48450FA1":  "Rugby League Live 2",
  "49470FA1":  "Test Drive Ferrari Racing Legend",
  "4B590FA0":  "Tropico 3 Gold Edition",
  "4B590FA1":  "Patrician IV",
  "4B590FA3":  "Commandos Complete",
  "4B590FA5":  "Dungeons",
  "4B590FA8":  "Patrician: RoaD",
  "4B590FA9":  "Elements of War",
  "4B590FAA":  "The First Templar",
  "4C4107EB":  "Star Wars: The Clone Wars: Republic Heroes",
  "4D5307D6":  "Shadowrun",
  "4D53080F":  "Halo 2",
  "4D530841":  "Viva Piñata",
  "4D530842":  "Gears of War",
  "4D5308D2":  "Microsoft Flight",
  "4D5308D3":  "Firebird Project",
  "4D530901":  "Game Room",
  "4D53090A":  "Fable III",
  "4D530935":  "Flight Simulator X",
  "4D530936":  "Age of Empires III",
  "4D530937":  "Fable: The Lost Chapters",
  "4D530942":  "AoE Online - Beta",
  "4D530FA0":  "Zoo Tycoon 2",
  "4D530FA2":  "Toy Soldiers",
  "4D530FA3":  "Age of Empires Online",
  "4D530FA4":  "Toy Soldiers: Cold War",
  "4D530FA5":  "Ms. Splosion Man",
  "4D530FA6":  "Skulls of the Shogun",
  "4D530FA7":  "Insanely Twisted Shadow Planet",
  "4D530FA8":  "Iron Brigade Download Games for Windows Live",
  "4D530FA9":  "MGS Pinball FX2 GFWL Games For Windows Live",
  "4D530FAA":  "MGS Vodka PC",
  "4D5388B0":  "BugBash 2",
  "4E4D0FA1":  "Dark Souls: Prepare to Die Edition",
  "4E4D0FA2":  "Ace Combat: Assault Horizon: Enhanced Edition",
  "4E4E0FA0":  "Trainz Simulator 2010",
  "4E4E0FA1":  "Settle and Carlisle",
  "4E4E0FA2":  "Classic Cabon City",
  "4E4E0FA3":  "TS 2010: Blue Comet",
  "4E4E0FA4":  "Trainz Simulator 12",
  "4F420FA0":  "BubbleTown",
  "4F430FA0":  "King’s Bounty Platinum",
  "50470FA1":  "Bejeweled 2",
  "50470FA3":  "Bookworm",
  "50470FA4":  "Plants vs. Zombies",
  "50470FA5":  "Zuma\u0027s Revenge",
  "50470FA6":  "Bejeweled 3",
  "50580FA0":  "Europa Universalis III",
  "50580FA1":  "Hearts of Iron III",
  "50580FA2":  "King Arthur",
  "50580FA3":  "Mount \u0026 Blade Warband",
  "50580FA4":  "Victoria 2",
  "50580FA6":  "Europa Universalis III: Divine Wind",
  "50580FA7":  "Europa Universalis III: Heir to the Throne",
  "50580FA8":  "King Arthur The Druids",
  "50580FA9":  "King Arthur The Saxons",
  "50580FAB":  "Cities in Motion",
  "50580FAC":  "Cities in Motion",
  "50580FAD":  "Europa Universalis III: Chronicles",
  "50580FAE":  "Darkest Hour",
  "50580FAF":  "Mount \u0026 Blade: With Fire \u0026 Sword",
  "50580FB0":  "King Arthur Collection",
  "50580FB1":  "Supreme Ruler Cold War",
  "50580FB2":  "Pirates of Black Cove",
  "51320FA0":  "Poker Superstars III",
  "51320FA1":  "Slingo Deluxe",
  "534307EB":  "Kane \u0026 Lynch: Dead Men",
  "534307FA":  "Battlestations Pacific",
  "534307FF":  "Batman: Arkham Asylum",
  "53430800":  "Battlestations Pacific",
  "5343080C":  "Batman: Arkham Asylum: Game of the Year Edition",
  "53430813":  "Championship Manager 10",
  "53430814":  "Tomb Raider Underworld",
  "534507F0":  "Universe at War: Earth Assault",
  "534507F6":  "The Club",
  "53450826":  "Stormrise",
  "5345082C":  "Vancouver 2010",
  "53450849":  "Alpha Protocol",
  "5345084E":  "Football Manager 2010",
  "53450854":  "Rome: Total War",
  "53450FA0":  "Football Manager 2011",
  "53450FA1":  "Dreamcast Collection",
  "53450FA2":  "Virtua Tennis 4",
  "53460FA0":  "A Vampyre Story",
  "53460FA1":  "Ankh 2",
  "53460FA2":  "Ankh 3",
  "53460FA3":  "Rise of Flight: Iron Cross Edition",
  "535007E3":  "Section 8",
  "53510FA0":  "Deus Ex: Game of the Year Edition",
  "53510FA1":  "Deus Ex: Invisible War",
  "53510FA2":  "Hitman: Blood Money",
  "53510FA3":  "Thief: Deadly Shadows",
  "53510FA4":  "Hitman 2: Silent Assassin",
  "53510FA5":  "Mini Ninjas",
  "53510FA6":  "Lara Croft Tomb Raider: Legend",
  "53510FA7":  "Lara Croft Tomb Raider: Anniversary",
  "53510FA8":  "Battlestations: Midway",
  "53510FA9":  "Conflict: Denied Ops",
  "53510FAA":  "Project: Snowblind",
  "544707D4":  "Section 8: Prejudice",
  "5451081F":  "Juiced 2: Hot Import Nights",
  "5451082D":  "Warhammer 40,000: Dawn of War II",
  "54510837":  "Red Faction: Guerrilla",
  "54510868":  "Warhammer 40,000: Dawn of War II: Chaos Rising",
  "54510871":  "Saints Row 2",
  "54510872":  "S.T.A.L.K.E.R.",
  "5451087F":  "Dawn of War",
  "54510880":  "Warhammer 40,000: Dawn of War: Dark Crusade",
  "54510881":  "Supreme Commander",
  "54510882":  "Supreme Commander: Forged Alliance",
  "5451882F":  "Dawn of War II",
  "5454083B":  "Grand Theft Auto IV",
  "5454085C":  "BioShock 2",
  "5454086E":  "Grand Theft Auto: Episodes from Liberty City",
  "5454086F":  "BioShock 2",
  "54540871":  "BioShock 2 (JP)",
  "54540873":  "Borderlands",
  "54540874":  "Sid Meier\u0027s Civilization IV: Complete",
  "54540876":  "Grand Theft Auto: San Andreas",
  "54540877":  "Grand Theft Auto: Vice City",
  "54540878":  "Max Payne 2",
  "54540879":  "Max Payne",
  "5454087B":  "BioShock",
  "54540880":  "Bully Scholarship Ed.",
  "54540881":  "Grand Theft Auto III",
  "54590FA0":  "Rift",
  "54590FA1":  "Rift: Collector\u0027s Edition",
  "54590FA2":  "Rift: Ashes of History Edition",
  "554C0FA0":  "4 Elements",
  "554C0FA1":  "Gardenscapes",
  "554C0FA2":  "Call of Atlantis",
  "554C0FA3":  "Around the World in 80",
  "554C0FA4":  "Fishdom: Spooky Splash",
  "55530855":  "Prince of Persia: The Forgotten Sands",
  "55530856":  "Assassin\u0027s Creed II",
  "55530857":  "Tom Clancy\u0027s Splinter Cell: Conviction",
  "55530859":  "Prince of Persia: Warrior Within",
  "5553085A":  "Prince of Persia: The Sands of Time",
  "5553085B":  "The Settlers 7: Paths to a Kingdom",
  "5553085E":  "Assassin\u0027s Creed",
  "5553085F":  "World In Conflict",
  "55530860":  "Dawn of Discovery Gold",
  "55530861":  "Prince of Persia",
  "55530862":  "Tom Clancy\u0027s Rainbow Six: Vegas 2",
  "55530864":  "Tom Clancy\u0027s Ghost Recon: Advanced Warfighter 2",
  "55530865":  "Far Cry 2",
  "55530866":  "Silent Hunter 5",
  "55530FA0":  "Prince of Persia: The Two Thrones",
  "55530FA1":  "Tom Clancy\u0027s H.A.W.X. 2",
  "55530FA2":  "Shaun White Skate",
  "55530FA3":  "Assassin\u0027s Creed: Brotherhood",
  "55530FA4":  "Assassin\u0027s Creed: Brotherhood Deluxe",
  "55530FA6":  "From Dust",
  "57520806":  "F.E.A.R. 2",
  "57520808":  "LEGO Batman",
  "57520809":  "LEGO Harry Potter: Years 1-4",
  "57520FA0":  "Batman: Arkham City",
  "57520FA1":  "LEGO Universe",
  "57520FA2":  "Mortal Kombat: Arcade Kollection",
  "57520FA3":  "Gotham City Impostors",
  "584109EB":  "Tinker",
  "584109F0":  "World of Goo",
  "584109F1":  "Mahjong Wisdom",
  "58410A01":  "Where\u0027s Waldo",
  "58410A10":  "Osmos",
  "58410A1C":  "CarneyVale: Showtime",
  "58410A6D":  "Blacklight: Tango Down",
  "585207D1":  "G4W-LIVE System",
  "5A450FA0":  "Battle vs. Chess",
  "5A450FA1":  "Two Worlds II",
  "5A500FA1":  "Kona\u0027s Crate"
}
'@
#endregion

# Initialize a static title map from JSON
$TitleMap = [Collections.Generic.Dictionary[string,string]]::new()
$(ConvertFrom-Json $TitleMapJson).PSObject.Properties | ForEach-Object {
  $TitleMap[$_.Name] = $_.Value
}
Set-Variable -Name TitleMap -Value $TitleMap -Option ReadOnly

# Ensure the static title map is initialized
if ($TitleMap.Count -eq 0) {
  if ($AllowWebLookup) {
    Write-Verbose 'Title map is empty, but web lookup (via the -AllowWebLookup parameter) is enabled. Will attempt to fetch title names.'
  } else {
    Write-Warning 'Title map is empty and web lookup (via the -AllowWebLookup parameter) is disabled. No title names will be available.'
  }
} else {
  Write-Verbose "Initialized title map with $($TitleMap.Count) entries."
}

# Function to extract the product key from an encrypted Token.bin file
# Returns null if the key is invalid or decryption fails
function Get-GFWLProductKey {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory, Position = 0, HelpMessage = 'The ID of the title to recover the product key for (e.g., 4D5308B1).')]
    [ValidateScript({ $_ -match $script:TitleIdPattern })]
    [string]$TitleId,

    [Parameter(Mandatory, Position = 1, HelpMessage = 'Path to the Token.bin file for the title.')]
    [ValidateNotNullOrEmpty()]
    [string]$TokenPath
  )

  if (-not (Test-Path $TokenPath -PathType Leaf)) {
    Write-Verbose "Skipping title with ID '$TitleId': Token.bin not found. Title is likely not activated."
    return $null
  }

  try {
    $allBytes = [System.IO.File]::ReadAllBytes($TokenPath)
    # The first 4 bytes of Token.bin are a header and should be skipped; the remainder is the DPAPI-encrypted key
    $TokenHeaderSize = 4
    $cipherBytes = $allBytes[$TokenHeaderSize..($allBytes.Length - 1)]
    $plainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
      $cipherBytes,
      $null,
      [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )

    # Decode the bytes to a string, removing any leading/trailing nulls and ensuring a trimmed, uppercase string
    $key = [System.Text.Encoding]::ASCII.GetString($plainBytes).Trim([char]0).Trim().ToUpperInvariant()

    # Validate the key matches the expected 5×5 alphanumeric pattern
    if ($key -cnotmatch $script:ProductKeyPattern) {
      Write-Warning "Skipping title with ID '$TitleId': Decryption succeeded, but the product key format is invalid: '$key'. Expected format is five groups of five alphanumeric characters (e.g., XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)."
      return $null
    }

    return $key
  }
  catch {
    Write-Warning "Skipping title with ID '$TitleId': Failed to decrypt Token.bin at '$TokenPath'. The file is possibly corrupted or inaccessible for your current user context."
    Write-Verbose "Decryption error details: $_"
    return $null
  }
}

<#
.SYNOPSIS
  Retrieves the friendly name for a title by ID, using an in-memory map first, then an API if allowed.

.PARAMETER TitleId
  Required. An 8-character hexadecimal string identifying the title to get the name for (e.g., 4D5308B1).

.EXAMPLE
  Get-TitleName -TitleId '4D5308B1'

.NOTES
  Respects $AllowWebLookup for API fallback. Ensure $script:TitleMap and $script:AllowWebLookup are defined before calling.
#>
function Get-TitleName {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory, Position = 0, HelpMessage = 'The ID of the title to get the name for (e.g., 4D5308B1).')]
    [ValidateScript({ $_ -match $script:TitleIdPattern })]
    [string]$TitleId
  )

  begin {
    $upperId = $TitleId.ToUpperInvariant()
    [string]$titleName = $null
  }

  process {
    # Attempt to retrieve the title name from the static map
    if ($script:TitleMap -and $script:TitleMap.Count -gt 0 -and $script:TitleMap.TryGetValue($upperId, [ref]$titleName)) {
      return $titleName
    }
  
    # If web lookup is enabled, attempt to fetch the title name from the Dbox API
    if ($script:AllowWebLookup) {
      return Get-DboxTitleName -TitleId $upperId
    }
  
    Write-Verbose "Unable to get the name for title with ID '$upperId'."
    return $null
  }
}

<#
.SYNOPSIS
  Fetches a title name by ID from the Dbox API.

.PARAMETER TitleId
  Required. An 8-character hexadecimal string identifying the title to fetch the name for (e.g., 4D5308B1).

.PARAMETER BaseUri
  Optional. The base URI of the Dbox API. Defaults to https://dbox.tools.

.EXAMPLE
  Get-DboxTitleName -TitleId '4D5308B1'
#>
function Get-DboxTitleName {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory, Position = 0, HelpMessage = 'The ID of the title to fetch the name for (e.g., 4D5308B1).')]
    [ValidateScript({ $_ -match $script:TitleIdPattern })]
    [string]$TitleId,

    [Parameter(Position = 1, HelpMessage = 'The base URI of the Dbox API. Defaults to https://dbox.tools.')]
    [ValidateNotNullOrEmpty()]
    [string]$BaseUri = 'https://dbox.tools'
  )

  begin {
    $upperId    = $TitleId.ToUpperInvariant()
    $requestUri = '{0}/api/title_ids/{1}' -f $BaseUri.TrimEnd('/'), $upperId
    $headers    = @{ Accept = 'application/json' }
  }

  process {
    Write-Verbose "Sending GET $requestUri"
    try {
      $response = Invoke-RestMethod -Uri $requestUri -Method Get -Headers $headers -ErrorAction Stop
      if ($response.name) {
        return $response.name
      }
      Write-Warning "API returned no name for title with ID '$upperId'."
      return $null
    }
    catch {
      Write-Warning "API lookup failed for title with ID '$upperId': $_"
      return $null
    }
  }
}

Write-Verbose "STEP 3: Processing titles in '$BasePath'..."

# Validate the base path contains valid GFWL title subdirectories
$allSubdirs = Get-ChildItem -Path $BasePath -Directory
$validDirs = $allSubdirs | Where-Object { $_.Name -match $script:TitleIdPattern }

if ($validDirs.Count -eq 0) {
  Write-Warning @"
No valid GFWL title subdirectories detected at path: $BasePath

Expected each subdirectory name to follow the 8-digit hexadecimal title ID format (e.g., 4D5308B1).
This typically occurs when the script is pointed at the wrong directory.

Check your directory and try again.
"@
  exit 0
}

# Iterate over each valid title subdirectory and attempt to recover the product key
$results = $validDirs | ForEach-Object {
  $titleId = $_.Name.ToUpperInvariant()

  Write-Verbose "Processing title: $titleId"

  $tokenBin = Join-Path $_.FullName 'Token.bin'
  $key      = Get-GFWLProductKey -TitleId $titleId -TokenPath $tokenBin

  if ($key) {
    Write-Verbose "Recovered product key for title with ID '$titleId'."
    [PSCustomObject]@{
      TitleId    = $titleId
      ProductKey = $key
      TitleName  = Get-TitleName -TitleId $titleId
    }
  }
} | Where-Object { $_ }

Write-Verbose 'STEP 4: Outputting results...'

# Output summary information and results in table format (if any)
if ($results.Count -eq 0) {
  Write-Warning @"
No GFWL product keys were recovered.

This is expected if:
  - No GFWL titles have been activated under the current Windows user account
  - The scanned path doesn't contain any activation data (e.g., Token.bin files)

Checked path: $BasePath

For debugging or additional details, re-run the script with -Verbose.
"@
  exit 0
}

Write-Host "`nRecovered $($results.Count) GFWL product keys" -ForegroundColor Green
$results | Format-Table @{Name = 'Title ID'; Expression = { $_.TitleId.PadRight(10) } },
                        @{Name = 'Product Key'; Expression = { $_.ProductKey.PadRight(31) } },
                        @{Name = 'Title Name'; Expression = { $_.TitleName } }

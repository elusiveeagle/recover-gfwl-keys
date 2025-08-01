<#
.SYNOPSIS
  Recover product keys of previously activated Games for Windows LIVE (GFWL) titles.

.DESCRIPTION
  This script recovers product keys for previously activated Games for Windows LIVE (GFWL) titles
  by locating and decrypting each title’s activation data.

  The script performs the following actions:
    - Scans the default GFWL titles directory or a user-specified root path
    - Identifies valid title-specific subdirectories containing "Token.bin" activation files
    - Decrypts each product key using Windows Data Protection API (DPAPI)
    - Validates the format and logs warnings for any decryption issues
    - Outputs the recovered product keys alongside their corresponding title IDs

  Note: Use https://dbox.tools/titles/gfwl/ to match title IDs to title names.

  Example output:

  Recovered 2 GFWL product keys

  Title ID   Product Key
  --------   -----------
  4D5308B1   ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
  4E4D07D2   ZYXWV-UTSRQ-PONML-KJIHG-FEDCB

.PARAMETER BasePath
  Optional. Specifies the root path to scan for GFWL titles. Defaults to "%LOCALAPPDATA%\Microsoft\XLive\Titles".

.INPUTS
  None. This script does not accept pipeline input.

.OUTPUTS
  [PSCustomObject] with 'Title ID' and 'Product Key' properties, or formatted table to the console.

.EXAMPLE
  .\Recover-GFWLKeys.ps1
  Scans the default GFWL titles directory and outputs recovered product keys.

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

.LINK
  https://github.com/elusiveeagle/recover-gfwl-keys
  https://dbox.tools/titles/gfwl/

.LIMITATIONS
  Product keys can only be recovered for the current Windows user account, due to Windows Data Protection API (DPAPI) restrictions.
  This means you must run this script as each Windows user that may have activated any titles.

.PRIVACY
  This script does not transmit any data over the network. All operations are performed locally.

.VERSION
  1.0.0
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
  [ValidateScript({ Test-Path $_ -PathType Container })]
  [string]$BasePath = "$env:LOCALAPPDATA\Microsoft\XLive\Titles",

  [Alias('?', 'h')]
  [switch]$Help
)

if ($Help) {
  Get-Help -Detailed $MyInvocation.MyCommand.Path
  exit 0
}

# Product key regex pattern (5×5 alphanumeric groups)
# Matches GFWL product keys in the format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX (5 groups of 5 alphanumeric characters).
New-Variable -Name ProductKeyPattern -Value '^([0-9A-Z]{5}-){4}[0-9A-Z]{5}$' -Scope Script -Option Constant

# Title ID regex pattern (8 hex digits)
# Matches GFWL Title IDs, which are always 8-character hexadecimal strings (e.g., 4D5308B1).
New-Variable -Name TitleIdPattern -Value '^[0-9a-fA-F]{8}$' -Scope Script -Option Constant

Write-Verbose 'STEP 1: Verifying requirements...'

# Verify GFWL titles directory exists
if (-not (Test-Path $BasePath)) {
  Write-Error "FATAL: GFWL titles path not found: '$BasePath'."
  exit 1
}

# Attempt to load the required .NET assemblies
try {
  Add-Type -AssemblyName System.Security -ErrorAction Stop
  Write-Verbose 'Successfully loaded System.Security assembly.'
}
catch {
  Write-Error "FATAL: Failed to load Data Protection API types. Ensure you have the System.Security assembly available."
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

function Get-GFWLProductKey {
  [OutputType([string])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TitleId,

    [Parameter(Mandatory)]
    [string]$TokenPath
  )

  if (-not (Test-Path $TokenPath)) {
    Write-Warning "Skipping title '$TitleId': Token.bin not found. Title is likely not activated."
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
    $key = [System.Text.Encoding]::ASCII.GetString($plainBytes).Trim([char]0).Trim().ToUpper()

    # Validate the key matches the expected 5×5 alphanumeric pattern
    if ($key -notmatch $script:ProductKeyPattern) {
      Write-Warning "Skipping title '$TitleId': Invalid product key format: '$key'. Expected format is five groups of five alphanumeric characters (e.g., XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)."
      return $null
    }

    return $key
  }
  catch {
    Write-Warning "Skipping title '$TitleId': Failed to decrypt product key: $_."
    return $null
  }
}

Write-Verbose "STEP 2: Processing titles in '$BasePath'..."

# Iterate over each title subdirectory and attempt to recover the product key
$results = Get-ChildItem -Path $BasePath -Directory | ForEach-Object {
  $titleIdRaw = $_.Name

  Write-Verbose "Processing title: $titleIdRaw"

  if ($titleIdRaw -notmatch $script:TitleIdPattern) {
    Write-Warning "Skipping title '$titleIdRaw': Invalid title ID format. Expected format is 8 hexadecimal characters (e.g., 4D5308B1)."
    return
  }
  $titleId  = $titleIdRaw.ToUpper()
  $tokenBin = Join-Path $_.FullName 'Token.bin'
  $key      = Get-GFWLProductKey -TitleId $titleId -TokenPath $tokenBin

  if ($key) {
    Write-Verbose "Recovered product key for title '$titleId'."
    [PSCustomObject]@{
      'Title ID'    = $titleId
      'Product Key' = $key
    }
  }
} | Where-Object { $_ }

Write-Verbose "STEP 3: Output results..."

# Output summary information and results in table format (if any)
if ($results.Count -eq 0) {
  Write-Host "`nNo GFWL product keys were recovered.`n" -ForegroundColor Yellow
  exit 0
}

Write-Host "`nRecovered $($results.Count) GFWL product keys" -ForegroundColor Green
$results | Format-Table -AutoSize
Write-Host 'To look up title IDs and match them to title names, search by title ID at the following URL:' -ForegroundColor Yellow
Write-Host "`nhttps://dbox.tools/titles/gfwl/`n" -ForegroundColor Cyan

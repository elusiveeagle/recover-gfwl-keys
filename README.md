# recover-gfwl-keys

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple PowerShell script that recovers product keys from previously activated *Games for Windows LIVE* titles.

## 🔧 What It Does

This script recovers product keys for previously activated Games for Windows LIVE (GFWL) titles by locating and decrypting each title's activation data.

The script performs the following actions:
- Scans the default GFWL titles directory (or a user-specified root path)
- Identifies valid title-specific subdirectories containing `Token.bin` activation files
- Decrypts each product key using Windows Data Protection API (DPAPI)
- Validates the product key format and logs warnings for any decryption issues
- Outputs the recovered product keys alongside their corresponding title IDs and names

## 📋 Requirements

- Windows system
- PowerShell 5.1 or later (preinstalled on Windows 10 / Server 2016+)  
  *(Compatible with Windows PowerShell 5.1, PowerShell Core 6.x, and PowerShell 7+)*

## 💡 Example Output

```
Recovered 2 GFWL product keys

Title ID  Product Key                    Title Name
--------  -----------                    ----------
4D5307D6  ABCDE-FGHIJ-KLMNO-PQRST-UVWXY  Shadowrun
4E4D0FA1  ZYXWV-UTSRQ-PONML-KJIHG-FEDCB  Dark Souls: Prepare to Die Edition
```

## 🔍 Notes & Troubleshooting

- Keys can only be recovered for GFWL titles activated under the **current Windows user account**.
- If no keys are found, it likely means no GFWL titles were activated on this account.
- Some titles use [Server-Side Activation (SSA)](https://www.pcgamingwiki.com/wiki/Games_for_Windows_-_LIVE#Server-Side_Activation_.28SSA.29), which may result in masked keys (e.g., `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`) or no key being available at all.
- The script identifies most GFWL titles using its built-in cache. To improve coverage, you can optionally enable web lookups. See [🌐 Allow Web Lookup](#-allow-web-lookup).
- Title names are sourced from Games for Windows/Xbox marketplace data (via dbox.tools). Variations in punctuation or naming may occur.
- For diagnostics and scan details, use the `-Verbose` switch. See [🧪 Debugging](#-debugging).

## 🚀 Typical Usage

1. Sign in to the Windows user account originally used to activate your GFWL titles.

2. Download the script to a known location:  
   - 🔍 [View on GitHub](https://github.com/elusiveeagle/recover-gfwl-keys/blob/main/Recover-GFWLKeys.ps1)  
   - 📥 [Download Raw .ps1](https://raw.githubusercontent.com/elusiveeagle/recover-gfwl-keys/refs/heads/main/Recover-GFWLKeys.ps1)

3. Open PowerShell:
   1. Press **Win + R** to open the Run dialog.
   2. Type `powershell` and press **Enter**.

4. Run the script:
   Most systems restrict running downloaded scripts for safety. You can either:

   🔹 **Recommended (no system changes):** Temporarily bypass restrictions just for this PowerShell session:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File 'C:\Path\To\Recover-GFWLKeys.ps1'
   ```

   🔹 **Advanced users only:** If you've previously configured PowerShell to allow script execution (e.g., using `Set-ExecutionPolicy Bypass`), you can run it directly:

   ```powershell
   & 'C:\Path\To\Recover-GFWLKeys.ps1'
   ```

   > 💡 *If you see an error like `running scripts is disabled on this system` or `The file C:\Path\To\Recover-GFWLKeys.ps1 is not digitally signed`, don't worry—it's just your system being cautious. The first method above will safely bypass that.*

## 🌐 Allow Web Lookup

Use the `-AllowWebLookup` switch to let the script optionally fetch data from the internet.

Currently, this enables fetching title names from the [Dbox API](https://dbox.tools/api/docs) when a title name isn't found in the script's local cache. For details on what data is (and isn't) transmitted when using this option, see [🔒 Privacy & Security](#-privacy--security).

### One-time override (no prior setup)

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& 'C:\Path\To\Recover-GFWLKeys.ps1' -AllowWebLookup"
```

### Policy-enabled run (requires execution policy)

```powershell
& 'C:\Path\To\Recover-GFWLKeys.ps1' -AllowWebLookup
```

## 📚 View Usage

Use the `-Help` switch to display parameters and usage:

### One-time override (no prior setup)

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& 'C:\Path\To\Recover-GFWLKeys.ps1' -Help"
```

### Policy-enabled run (requires execution policy)

```powershell
& 'C:\Path\To\Recover-GFWLKeys.ps1' -Help
```

## 🧪 Debugging

Enable verbose output for diagnostics and scan details with the `-Verbose` switch:

### One-time override (no prior setup)

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& 'C:\Path\To\Recover-GFWLKeys.ps1' -Verbose"
```

### Policy-enabled run (requires execution policy)

```powershell
& 'C:\Path\To\Recover-GFWLKeys.ps1' -Verbose
```

## 🔒 Privacy & Security

By default, this script performs all operations locally and does **not** transmit any data over the network.

If you choose to use the `-AllowWebLookup` parameter, the script will attempt to fetch title names from the [Dbox API](https://dbox.tools/api/docs) **only** for titles not found in the local cache. No other data is sent or received. See [🌐 Allow Web Lookup](#-allow-web-lookup) for usage details.

You're encouraged to review the [open-source code](https://github.com/elusiveeagle/recover-gfwl-keys/blob/main/Recover-GFWLKeys.ps1) to verify its behavior and ensure you trust the source before running it.

## 🙏 Credits & Attribution

This script uses title data from dbox.tools (https://dbox.tools/titles/gfwl/)  and its API (https://dbox.tools/api/docs). All rights to that data remain with dbox.tools.

## 📝 Latest Changes

See [CHANGELOG.md](./CHANGELOG.md) for full version history.

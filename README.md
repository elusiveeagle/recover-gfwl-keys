# recover-gfwl-keys

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://docs.microsoft.com/powershell/)  
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple PowerShell script that recovers product keys from previously activated *Games for Windows LIVE* titles.

## 🔧 What It Does
This script recovers product keys for previously activated Games for Windows LIVE (GFWL) titles by locating and decrypting each title’s activation data.

The script performs the following actions:
- Scans the default GFWL titles directory (or a user-specified root path)
- Identifies valid title-specific subdirectories containing `Token.bin` activation files
- Decrypts each product key using Windows Data Protection API (DPAPI)
- Validates the product key format and logs warnings for any decryption issues
- Outputs the recovered product keys alongside their corresponding title IDs

> **Note:** Use https://dbox.tools/titles/gfwl/ to match title IDs to title names.

## 📋 Requirements

- PowerShell 5.1 or later (available by default on Windows 10 and newer)

## 💡 Example Output

```
Recovered 2 GFWL product keys

Title ID   Product Key
--------   -----------
4D5308B1   ABCDE-FGHIJ-KLMNO-PQRST-UVWXY
4E4D07D2   ZYXWV-UTSRQ-PONML-KJIHG-FEDCB
```

## 🔍 Notes & Troubleshooting

- Only product keys for GFWL titles activated under the **current Windows user account** can be recovered.
- If the script returns zero product keys, it likely means no GFWL titles were activated on this account.
- Use the `-Verbose` switch for diagnostics and scan details. See [Debugging](#-debugging).

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

   🔹 **Advanced users only:** If you’ve previously configured PowerShell to allow script execution (e.g., using `Set-ExecutionPolicy Bypass`), you can run it directly:

   ```powershell
   & 'C:\Path\To\Recover-GFWLKeys.ps1'
   ```

   💡 *If you see an error like `running scripts is disabled on this system` or `The file C:\Path\To\Recover-GFWLKeys.ps1 is not digitally signed`, don’t worry—it’s just your system being cautious. The first method above will safely bypass that.*

## 📚 View Usage

Use the `-Help` switch to display parameters and examples:

One-time override:

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& 'C:\Path\To\Recover-GFWLKeys.ps1' -Help"
```

Policy-enabled run:

```powershell
& 'C:\Path\To\Recover-GFWLKeys.ps1' -Help
```

## 🧪 Debugging

Enable verbose output for diagnostics and scan details with the `-Verbose` switch:

One-time override:

```powershell
powershell.exe -ExecutionPolicy Bypass -Command "& 'C:\Path\To\Recover-GFWLKeys.ps1' -Verbose"
```

Policy-enabled run:

```powershell
& 'C:\Path\To\Recover-GFWLKeys.ps1' -Verbose
```

## 🔒 Privacy & Security

This script performs all operations locally and does not connect to the internet or transmit any data externally.

You’re invited to review the [open-source code](https://github.com/elusiveeagle/recover-gfwl-keys/blob/main/Recover-GFWLKeys.ps1) to verify there are no hidden behaviors before running it.

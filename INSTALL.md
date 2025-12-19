# Getting Started: Getting helloGMP into Roblox Studio/Luau
**HelloGMP** is distributed as source code and is not directly importable into Roblox Studio.

To use helloGMP, you must manually recreate the library's `src/` directory structure inside your Roblox project and copy the corresponding source files into ModuleScripts. This includes all submodules, extensions,and optional components present in the repository.


> **Rule:** The folder and ModuleScript structure inside Roblox Studio
> must exactly match the structure of the `src/` directory in the repository.

## 🧱 Partial Import: Core Integer Support
This section describes how to import only the minimum subset of files required for arbitrary-precision integer arithmetic (`hello_mpz`).

### Required Source Files
From the repository:
- `src/helloGMP/hello_mpz.lua`
- `src/helloGMP/base_settings.lua`

### Procedure
1. **Create a folder** under `ReplicatedStorage` and name it `helloGMP`.

    ![](./assets/install-images/install-step-1.png)  
    *Create the `helloGMP` folder inside ReplicatedStorage.*

2. **Create two ModuleScripts** inside the `helloGMP` folder and name them `hello_mpz` and `base_settings`.

    ![](./assets/install-images/install-step-2.png)  
    *Add two ModuleScripts named `hello_mpz` and `base_settings`.*

3. **Navigate the matching source file names** in the Github repository and open one of them (`src/helloGMP/hello_mpz.lua` or `base_settings.lua`), select the entire code, then copy the code into the clipboard.

    ![](./assets/install-images/install-step-3a.png)  
    *Open the source file on GitHub.*

4. **Paste the code** into the corresponding ModuleScript in Roblox Studio.

    ![](./assets/install-images/install-step-3b.png)  
    *Paste the code into your ModuleScript.*

5. **Repeat the process** for the remaining ModuleScript by opening its matching source file on GitHub and pasting its code into Studio.

### ⚠️ Common Issues
- Ensure the folder is named exactly `helloGMP` (case-sensitive).
- Ensure the ModuleScripts are named `hello_mpz` and `base_settings`.
- Do not place the scripts directly under `ReplicatedStorage`
  without the `helloGMP` folder.

### ✅ Partial Import Verification
To check if you have followed the steps correctly, add a Server Script, parent it under `ServerScriptService` and then paste this code into the script.
If this script prints the expected result, the core `hello_mpz` module has been imported successfully.

```lua
local hello_mpz = require(game.ReplicatedStorage.helloGMP.hello_mpz)

local a = hello_mpz.fromString("437189043214321")
local b = hello_mpz.fromString("43718904328195321")

local result = a * b -- multiplication
print(result) -- 19113425953622149599590952392041
```
You may stop here if you only require arbitrary-precision integers. To install the full helloGMP system, continue below.

## 🧩 Complete Import: Full helloGMP Library
This section describes how to import the entire helloGMP system by mirroring the full `src/` directory structure inside Roblox Studio.

### Directory Structure (Illustrative)

This example omits some files for brevity. Refer to the repository’s `src/` directory as the authoritative source.

Recreate the following structure inside `ReplicatedStorage`:

ReplicatedStorage/
└── helloGMP/
    ├── hello_mpz
    ├── hello_mpq
    ├── hello_mpf
    ├── base_settings
    ├── extensions/
    │   ├── hello_complex
    │   ├── hello_datetime
    │   └── etc...

### Source File Mapping
The table below shows common mappings. Not all files are listed.

| Roblox ModuleScript Path | Source File |
|--------------------------|-------------|
| helloGMP/base_settings | src/helloGMP/base_settings.lua |
| helloGMP/hello_mpf | src/helloGMP/hello_mpf.lua |
| helloGMP/hello_mpq | src/helloGMP/hello_mpq.lua |
| helloGMP/hello_mpz | src/helloGMP/hello_mpz.lua |
| helloGMP/extensions/hello_complex | src/extensions/hello_complex.lua |
| helloGMP/extensions/hello_datetime | src/extensions/hello_datetime.lua |
| helloGMP/extensions/hello_evaluator | src/extensions/hello_evaluator.lua |

### Procedure
1. Starting from the existing `helloGMP` folder created earlier, create additional folders and ModuleScripts so that the hierarchy matches the repository’s `src/` directory exactly.

2. For each ModuleScript:
   - Open the corresponding source file in the GitHub repository.
   - Copy the entire contents.
   - Paste it into the matching ModuleScript in Roblox Studio.

3. Repeat this process until all source files under `src/` have been mirrored inside the `helloGMP` folder.

### ⚠️ Common Issues
- Folder and ModuleScript names are case-sensitive.
- The internal structure must match the repository exactly.
- Do not rename files unless you also update `require` paths.
- All modules should be parented under the same `helloGMP` root folder.

### ✅ Complete Import Verification
After completing the full import, you should be able to require any helloGMP module without errors.
Create a Server Script if you don't have one and parent it under `ServerScriptService`, and then paste the code into the script.
```lua
local a = "WIP"
```
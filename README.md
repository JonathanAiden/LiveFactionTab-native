# Live Faction Tab - native part (FactionMatrixNative)

Source of `FactionMatrixNative/dlls/main.dll` from the Nexus mod
[Faction Relations - Live PDA Tab](https://www.nexusmods.com/stalker2heartofchornobyl/mods/2557).

A small UE4SS C++ mod. It reads the faction relations straight from the game
and adds the PDA tab. The Lua part of the mod (`main.lua`) calls it through the
Lua function `FMTXNative()`. It does not write files, open network connections
or touch anything outside the game process.

## Build

Requirements: Visual Studio 2022 (C++ build tools), CMake 3.22+, Ninja, Rust
(needed by RE-UE4SS), and GitHub access to the EpicGames organization
(RE-UE4SS pulls Epic's UEPseudo submodule).

```
git clone https://github.com/UE4SS-RE/RE-UE4SS.git
cd RE-UE4SS
git checkout 527a483b63b4dd0104fe1ca1a3934a06b87fcfb2
git submodule update --init --recursive
cd ..
```

Place the cloned `RE-UE4SS` folder next to `CMakeLists.txt` and `FMTXNative`, then in a
"x64 Native Tools Command Prompt for VS 2022":

```
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Game__Shipping__Win64
cmake --build build --target FactionMatrixNative
```

The result is `build/FMTXNative/FactionMatrixNative.dll`. It goes to
`Stalker2/Binaries/Win64/ue4ss/Mods/FactionMatrixNative/dlls/main.dll`.

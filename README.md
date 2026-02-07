# CuesTerminalGame

A CMD/PowerShell-only terminal idle game with local saves and ASCII graphics.

## Run (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File .\CuesTerminalGame.ps1
```

## Run (CMD)
```cmd
powershell -ExecutionPolicy Bypass -File .\CuesTerminalGame.ps1
```

## Controls
- **M**: Mine 1 credit manually
- **D**: Buy a drone (idle income)
- **R**: Buy a refinery (higher idle income)
- **S**: Save
- **Q**: Quit

The game auto-saves every 5 seconds and stores progress in `save.json`.

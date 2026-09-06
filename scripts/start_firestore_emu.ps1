# start_firebase.ps1
# Script to check if Firebase emulator is running on a specified host/port,
# start it if not detected, and handle data import/export.

param(
# Parameter for the port number to check. Defaults to 8080.
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,65535)]
    [int]$port = 8080,

# Parameter for the hostname or IP address to check. Defaults to localhost.
    [Parameter(Mandatory=$false)]
    [string]$hostname = "localhost",

# Parameter for the data directory. Defaults relative to script location.
    [Parameter(Mandatory=$false)]
    [string]$datadir = "..\..\temp\emulator_data"
)

Write-Host "Checking if Firebase emulator is running on '$($hostname):$port'..."

$portIsOpen = Test-NetConnection -ComputerName $hostname -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue

if ($portIsOpen) {
    Write-Host "Firebase emulators appear to be running (Port $port on $hostname is open)."
    Write-Host "Note: If started manually, data export on exit might not be configured."
} else {
    Write-Host "Firebase emulators not detected (Port $port on $hostname seems closed)."

    # Ensure the data directory exists before trying to import/export
    $FullDataDirPath = Resolve-Path -Path $datadir # Get absolute path for clarity if needed
    if (-not (Test-Path -Path $datadir -PathType Container)) {
        Write-Host "Creating emulator data directory: '$($FullDataDirPath)'"
        New-Item -ItemType Directory -Force -Path $datadir | Out-Null
    }

    # Start emulators with import/export flags
    Write-Host "Starting emulators. Importing from and exporting to: '$($FullDataDirPath)'"
    # IMPORTANT: Ensure you run this script from the correct directory (apps/bessie) for relative paths to work.
    firebase emulators:start --import $datadir --export-on-exit $datadir
}

# Optional: Pause at the end if running by double-click
# Read-Host -Prompt "Press Enter to exit"
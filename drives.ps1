#Parameters
param (
    [Parameter(Mandatory = $true)]
    [string]
    $drive
)

# log directory

if ($PSVersionTable.Platform -eq 'Unix') {
    $logPath = '/tmp'
}
else {
    $logPath = 'C:/Logs'
}
$logFile = "$logPath\driveCheck.log" #logFile

#verify if the log directory exists

try {
    if(-not (Test-Path -Path $logPath -ErrorAction Stop)) {
        # output dir is not found. Create the dir
        New-Item -ItemType directory -Path $logPath -ErrorAction Stop | Out-Null
        New-Item -ItemType directory -Path $logFile -ErrorAction Stop | Out-Null
    }
}
catch {
    throw
}

Add-Content -Path $logFile -Value "[INFO] Running $PSCommandPath"

#verify poshgram is installed

if(-not (Get-Module -Name PoshGram -ListAvailable)) {
    Add-Content -Path $logFile -Value "[ERROR] PoshGram is not installed."
    throw
}
else {
    Add-Content -Path $logFile -Value "[INFO] PoshGram is installed."
}

# get hdd info
try {
    if ($PSVersionTable.Platform -eq 'Unix') {
        #Linux
        #used
        #free
        $volume = Get-PSDrive -Name $Drive -ErrorAction Stop
        #verify volume exists
        if ($volume) {
            $total = $volume.Used + $volume.free
            $percentFree = [int](($volume.free / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%"
    
        }
        else {
            Add-Content -Path $logFile -Value "[ERROR] $drive Not Found."
            throw
        }
    }
    else {
        #Windows
        $volume = Get-Volume -ErrorAction | Where-Object {$_.DriveLetter -eq $drive}
        if ($volume) {
            $total = $volume.size
            $percentFree = [int](($volume.SizeRemaining / $total) * 100)
            Add-Content -Path $logFile -Value "[INFO] Percent Free: $percentFree%"
    
        }
        else {
            Add-Content -Path $logFile -Value "[ERROR] $drive Not Found."
            throw
        }
    }
}
catch {
    Add-Content -Path $logFile -Value "[ERROR] Unable to retrieve volume information"
    Add-Content -Path $logFile -Value $_
    throw

}
$logFile = "$logPath\driveCheck.log" #logFile

# send telegram message
if ($percentFree -le 20) {
    try {
        Import-Module -Name PoshGram -ErrorAction Stop
        Add-Content -Path $logFile -Value "[INFO] Imported PoshGram successfully"
    }
    catch {
        Add-Content -Path $logFile -Value "[ERROR] PoshGram could not be imported"
        Add-Content -Path $logFile -Value $_
    }
    Add-Content -Path $logFile -Value "[INFO] Sending Telegram Notification"
}
<# Need to look up how to get this set up with email and not TeleGram
   Not wanting to use Telegram currently
$botToken =
$chat = 

$sendTelegramTextMessageSplat = @{
    BotToken  = $botToken
    ChatID    = $chat
    Message   = '[LOW SPACE] Drive at $percentfree%'
    ErrorAction = 'Stop'
}
try {
    Send-TelegramTextMessage @sendTelegramTextMessageSplat
    Add-Content -Path $logFile -Value "[INFO] Message sent successfully"
}
catch {
    Add-Content -Path $logFile -Value "[ERROR] Error encountered sendign message"
    Add-Content -Path $logFile -Value $_
    throw
}
#>


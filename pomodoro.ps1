# Requires BurnToast: https://github.com/Windos/BurntToast
# To install: Install-Module -Name BurntToast

$PSVersion = $PSVersionTable.PSVersion
$Version71 = ($PSVersion.Major -ge 7) -and ($PSVersion.Minor -ge 1)
Write-Host "Running with PowerShell version ${PSVersion}..."
if (${Version71}) {
    Write-Host "=> We can use events in ToastNotifications!"
}
else {
    Write-Host "=> Unfortunately, we cannot use events in ToastNotifications :("
}
Write-Host ""


$ToastID = 'PomodoroToast'
$PTHeader = New-BTHeader -Id '314159' -Title 'Pomodoro Timer'

$TomatoPath = "./tomato.png"
$ImageTomato = New-BTImage -Source $TomatoPath -AppLogoOverride -Crop Circle
$AudioDflt = New-BTAudio -Source 'ms-winsoundevent:Notification.Default'


$5Min = New-BTSelectionBoxItem -Id 5 -Content '5 minutes'
$10Min = New-BTSelectionBoxItem -Id 10 -Content '10 minutes'

$Items = $5Min, $10Min



function Show-PTNotification {
    <#
        .SYNOPSIS
        Display activity based on string passed and default time

        .DESCRIPTION
        Show a Notification with action to perform (e.g. Work or Rest) and a Timer.

        .INPUTS
        Activity, as text
        Timing in minutes

        .OUTPUTS
        None

        .EXAMPLE
        $PTNotification "Working"

        This example displays a notification for Working
    #>
    param (
        # [Parameter(Mandatory)]
        [string] $Activity,
        [int16] $Timing
    )

    $TextPT = New-BTText -Content $Activity
    $BindingPT = New-BTBinding -Children $TextPT -AppLogoOverride $ImageTomato
    $VisualPT = New-BTVisual -BindingGeneric $BindingPT

    $SelectionBoxPT = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId $Timing -Items $Items
    $SnoozeButton = New-BTButton -Snooze -Content "Go" -Id 'SnoozeTime'
    $DismissButton = New-BTButton -Dismiss -Content "Stop Timer"

    $ActionPT = New-BTAction -Buttons $SnoozeButton, $DismissButton -Inputs $SelectionBoxPT
    $ContentPT = New-BTContent -Visual $VisualPT -Audio $AudioDflt -Actions $ActionPT -Header $PTHeader

    Submit-BTNotification -Content $ContentPT
}



$CurrentTimer = @{
    Activity = "Some Activity"
    Duration = 0
    StartPoint = (New-TimeSpan)
}

$Resume = {
    Write-Host "$(Get-Date): Resumed Timer"
    Start-PTActivity @CurrentTimer
}

$Pause = {
    Write-Host "$(Get-Date): Paused Timer"
    $ToastSplat = @{
        Text             = 'Paused', 'Click to resume'
        UniqueIdentifier = $ToastID
        Header           = $PTHeader
        AppLogo          = $TomatoPath
    }
    New-BurntToastNotification @ToastSplat -ActivatedAction $Resume
}

function New-PTNotif {
    [CmdletBinding()]
    param (
        [string] $Activity,
        [string] $Elapsed = "Not Started",
        [string] $Remaining = "N/A",
        [string] $Percent = 0
    )

    $Progress = New-BTProgressBar -Status 'Elapsed' -Value 'Percent'
    # $PauseBtn = New-BTButton -Snooze -Content "Pause"
    $StopBtn = New-BTButton -Dismiss -Content "Stop Timer"

    $DataBinding = @{
        Activity  = $Activity
        Remaining = $Remaining
        Elapsed   = $Elapsed
        Percent   = $Percent
    }
    $ToastSplat = @{
        Text             = 'Activity', 'Remaining'
        UniqueIdentifier = $ToastID
        DataBinding      = $DataBinding
        Header           = $PTHeader
        Button           = $StopBtn
        ProgressBar      = $Progress
        AppLogo          = $TomatoPath
    }
    if ($Version71) {
        New-BurntToastNotification @ToastSplat -ActivatedAction $Pause
        # New-BurntToastNotification @ToastSplat
    }
    else {
        New-BurntToastNotification @ToastSplat
    }

    # $TextActivity = New-BTText -Content 'Activity'
    # $TextRemaining = New-BTText -Content 'Remaining'
    # $BindingPT = New-BTBinding -Children $TextActivity, $TextRemaining -AppLogoOverride $ImageTomato
    # $VisualPT = New-BTVisual -BindingGeneric $BindingPT

    # $ActionPT = New-BTAction -Buttons $StopBtn
    # $ContentPT = New-BTContent -Visual $VisualPT -Audio $AudioDflt -Actions $ActionPT -Header $PTHeader
    # Submit-BTNotification -Content $ContentPT -DataBinding $DataBinding
}


New-PTNotif -Activity "Pomodoro Timer"

function Start-PTActivity {
    <#
        .SYNOPSIS
        Pomodoro Timer for a given activity

        .DESCRIPTION
        Launch a Pomodoro Timer for a given activity for a given duration

        .INPUTS
        Activity, as text
        Duration, in minutes
        StartPoint (TimeSpan): the starting time to be able to start in the middle

        .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param (
        [string] $Activity,
        [int16] $Duration,
        [TimeSpan]$StartPoint = (New-TimeSpan)
    )

    New-PTNotif -Activity ($Activity + " starting soon...") -Remaining "Prepare Yourself!"
    Start-Sleep -Seconds 5

    $StartTime = Get-Date
    if ($StartPoint) {
        # If we start in the middle (maybe there is a better way to compute)
        $VirtualStartTime = $StartTime.AddSeconds(-1 * $StartPoint.Seconds)
        $VirtualStartTime = $VirtualStartTime.AddMinutes(-1 * $StartPoint.Minutes)
    } else {
        $VirtualStartTime = $StartTime
    }
    $EndTime = $VirtualStartTime.AddMinutes($Duration)
    # $EndTime = $VirtualStartTime.AddSeconds($Duration)  # For DEBUG

    if ($StartPoint.TotalSeconds) {
        Write-Host "${StartTime}: Started ${Activity} ... at time ${StartPoint}"
    }
    else {
        Write-Host "${StartTime}: Started ${Activity}"
    }
    $TotalSeconds = (New-TimeSpan -Start $VirtualStartTime -End $EndTime).TotalSeconds

    $Global:CurrentTimer = @{
        Activity = $Activity
        Duration = $Duration
    }

    Do {
        $Now = Get-Date
        $Elapsed = (New-TimeSpan -Start $VirtualStartTime -End $Now)
        $Global:CurrentTimer["StartPoint"] = $Elapsed
        $Remaining = (New-TimeSpan -Start $Now -End $EndTime)

        # We will Display remaining seconds at the end
        if ($Remaining.TotalSeconds -le 60) {
            $RemainingStr = '{0:n0} min {1:n0} sec remaining' -f $Remaining.Minutes, $Remaining.Seconds
        }
        else {
            $MiniTime = '{0:d2}:{1:d2}' -f $EndTime.Hour, $EndTime.Minute
            $RemainingStr = '{0:n0} min remaining (ends at {1})' -f $Remaining.Minutes, $MiniTime
        }

        $DataBindingUpdate = @{
            Activity  = $Activity
            Remaining = $RemainingStr
            Elapsed   = '{0:n0} min {1:n0} sec' -f $Elapsed.Minutes, $Elapsed.Seconds
            Percent   = $Elapsed.TotalSeconds / $TotalSeconds
        }
        $Status = Update-BTNotification -UniqueIdentifier $ToastID -DataBinding $DataBindingUpdate

        if (($Status -ne "Succeeded") -and (!$Version71)) {
            Write-Host "Pomodoro Timer has been ended"
            exit
        }

        if ($Elapsed -lt $Duration) {
            Start-Sleep -Seconds 10
        }
    } Until ($Now -ge $EndTime)

    # At the end, we re-emit the Notification to have it on Top
    Write-Host "${StartTime}: Finished ${Activity}"
    $NotifData = @{
        Activity  = $Activity + " FINISHED!"
        Remaining = 'Finished'
        Elapsed   = '{0:n0} minutes' -f $Duration
        Percent   = 1.0
    }
    New-PTNotif @NotifData
    Start-Sleep -Seconds 5
}


$Cycle = @(
    @("Working", 25),
    @("Rest", 5),
    @("Working", 25),
    @("Rest", 5),
    @("Working", 25),
    @("Rest", 5),
    @("Working", 25),
    @("Rest", 15)
)

while (1) {
    foreach ($action in $Cycle) {
        Start-PTActivity -Activity $action[0] -Duration $action[1]
    }
}

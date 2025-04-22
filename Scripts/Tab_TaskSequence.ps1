param(
    [System.Windows.Controls.TabItem]$TabItem
)

#Wczytanie kontroli z XAML
$AddButton = $TabItem.FindName('AddButton')
$EditButton = $TabItem.FindName('EditButton')
$RemoveButton = $TabItem.FindName('RemoveButton')
$TaskSequenceList = $TabItem.FindName('TaskSequenceList')

# Path to the configuration folder and file
$ConfigPath      = ".\Config"
$SftpConfigPath  = Join-Path -Path $ConfigPath -ChildPath "SFTP_Config.xml"

# Load SFTP configuration from XML
[xml]$config = Get-Content $SftpConfigPath -Raw
$SftpServerIp   = $config.Configuration.SftpSettings.ServerIP
$SftpPort       = $config.Configuration.SftpSettings.Port
$SftpUsername   = $config.Configuration.SftpSettings.Username
$SftpPassword   = $config.Configuration.SftpSettings.Password

# --- Ustawienia SFTP ---
$securePass = ConvertTo-SecureString $SftpPassword -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential($SftpUsername, $securePass)

#Connection to Sftp Server
$session = New-SFTPSession -ComputerName $SftpServerIp -Credential $Cred -Port $SftpPort -AcceptKey 

# Path to the task sequence folder 
$remotePath = '/TaskSequences'

# --- Sprawdź, czy katalog istnieje ---
try {
    # próbujemy uzyskać listing katalogu
    Get-SFTPChildItem -SessionId $session.SessionId `
                      -Path      $remotePath `
                      -ErrorAction Stop | Out-Null

    Write-Host "Katalog '$remotePath' już istnieje na serwerze SFTP."
}
catch {
    # jeśli wyrzuci błąd, to katalog nie istnieje – tworzymy go
    Write-Host "Tworzę katalog '$remotePath' na serwerze SFTP..."
    New-SFTPItem -SessionId $session.SessionId `
                 -Path      $remotePath `
                 -ItemType  Directory
    Write-Host "Katalog utworzony."
}

# Function to refresh the folder list
function Refresh_TaskSequenceList {
    # czyścimy listę w UI
    $TaskSequenceList.Items.Clear()

    try {
        # pobieramy wpisy zdalne i filtrujemy tylko katalogi
        $dirs = Get-SFTPChildItem -SessionId $session.SessionId `
                                  -Path      $remotePath `
                                  -ErrorAction Stop |
                Where-Object { $_.IsDirectory }

        foreach ($d in $dirs) {
            $TaskSequenceList.Items.Add($d.Name)
        }
    }
    catch {
        Write-Warning "Nie udało się pobrać listy z '$remotePath' na serwerze SFTP: $_"
    }
}

# "Add New" button event handler
$AddButton.Add_Click({
    & "$PSScriptRoot\AddTaskSequence.ps1" -TaskSequencesPath $TaskSequencesPath -OSxmlFilePath $xmlOSFilePath
    Refresh_TaskSequenceList
})

# Initial population of the list
Refresh_TaskSequenceList

# --- Zakończenie sesji ---
#Remove-SFTPSession -SessionId $session.SessionId
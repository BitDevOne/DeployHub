# Definicja TabItem z deklaracją xmlns:x
$XamlTab = @"
<TabItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
         xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
         Header="Task Sequences">
        <Grid Margin="10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
                <StackPanel Orientation="Horizontal" Grid.Row="0">
                    <Button x:Name="AddButton" Content="Add New"/>
                    <Button x:Name="EditButton" Content="Edit"/>
                    <Button x:Name="RemoveButton" Content="Remove"/>
                </StackPanel>
            <ListBox x:Name="TaskSequenceList" Grid.Row="1" Height="400"/>
        </Grid>
</TabItem>
"@

# Parsowanie XAML i stworzenie obiektu
[xml]$XmlTab = $XamlTab
$ReaderTab = New-Object System.Xml.XmlNodeReader $XmlTab
$TabItem = [Windows.Markup.XamlReader]::Load($ReaderTab)

#Wczytanie kontroli z XAML
$AddButton = $TabItem.FindName('AddButton')
$EditButton = $TabItem.FindName('EditButton')
$RemoveButton = $TabItem.FindName('RemoveButton')
$TaskSequenceList = $TabItem.FindName('TaskSequenceList')

# Path to the configuration folder and file
$ConfigPath      = ".\Config"
$SftpConfigPath  = Join-Path -Path $ConfigPath -ChildPath "SFTP_Config.xml"

# Function to load SFTP configuration from XML
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

# --- Zakończenie sesji ---
Remove-SFTPSession -SessionId $session.SessionId

# Zwrócenie obiektu TabItem do Start.ps1
return $TabItem

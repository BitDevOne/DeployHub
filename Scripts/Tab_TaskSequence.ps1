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
function Load_SftpConfig {
    if (Test-Path $SftpConfigPath) {
        try {
            [xml]$config = Get-Content $SftpConfigPath
            $SftpServerIp.Text = $config.Configuration.SftpSettings.ServerIP
            $SftpPort.Text     = $config.Configuration.SftpSettings.Port
            $SftpUsername.Text = $config.Configuration.SftpSettings.Username
            $SftpPassword.Text = $config.Configuration.SftpSettings.Password
        }
        catch {
            Write-Host "❌ Error loading SFTP configuration: $_" -ForegroundColor Red
        }
    }
}

$Cred = New-Object System.Management.Automation.PSCredential($SftpUsername, $SftpPassword)

#Connection to Sftp Server
$session = New-SFTPSession -ComputerName $SftpServerIp `
                           -Credential   $Cred `
                           -Port         $SftpPort `
                           -ErrorAction  Stop



# Zwrócenie obiektu TabItem do Start.ps1
return $TabItem

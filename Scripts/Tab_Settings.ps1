# Definition of the TabItem with xmlns declarations
$XamlTab = @"
<TabItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
         xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
         Header="Settings">
    <Grid Margin="10">
        <GroupBox Header="SFTP Configuration">
            <StackPanel Margin="10">
                <Label Content="SFTP Server IP:" FontWeight="Bold"/>
                <TextBox x:Name="SftpServerIp" Margin="0,0,0,10"/>
                
                <Label Content="SFTP Port:" FontWeight="Bold"/>
                <TextBox x:Name="SftpPort" Margin="0,0,0,10" Text="22"/>
                
                <Label Content="SFTP Username:" FontWeight="Bold"/>
                <TextBox x:Name="SftpUsername" Margin="0,0,0,10"/>
                
                <Label Content="SFTP Password:" FontWeight="Bold"/>
                <PasswordBox x:Name="SftpPassword" Margin="0,0,0,10"/>
                
                <Button Content="Save SFTP Settings" 
                        x:Name="SaveSftpSettings" 
                        HorizontalAlignment="Right" 
                        Margin="0,10,0,0" 
                        Padding="20,5"/>
            </StackPanel>
        </GroupBox>
    </Grid>
</TabItem>
"@

# Parse the XAML and create the TabItem object
[xml]$XmlTab = $XamlTab
$ReaderTab = New-Object System.Xml.XmlNodeReader $XmlTab
$TabItem = [Windows.Markup.XamlReader]::Load($ReaderTab)

# Load controls from the XAML
$SftpServerIp    = $TabItem.FindName('SftpServerIp')
$SftpPort        = $TabItem.FindName('SftpPort')
$SftpUsername    = $TabItem.FindName('SftpUsername')
$SftpPassword    = $TabItem.FindName('SftpPassword')
$SaveSftpSettings= $TabItem.FindName('SaveSftpSettings')

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
            # We intentionally do not load the password for security reasons
        }
        catch {
            Write-Host "❌ Error loading SFTP configuration: $_" -ForegroundColor Red
        }
    }
}

# Handle the Save button click to write settings back to XML
$SaveSftpSettings.Add_Click({
    # Ensure the Config folder exists
    if (-not (Test-Path $ConfigPath)) {
        New-Item -ItemType Directory -Path $ConfigPath | Out-Null
    }

    $serverIP = $SftpServerIp.Text
    $port     = $SftpPort.Text
    $username = $SftpUsername.Text
    $password = $SftpPassword.Password

    try {
        # Build or update the XML document
        $xml = [xml]@"
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
    <SftpSettings>
        <ServerIP>$serverIP</ServerIP>
        <Port>$port</Port>
        <Username>$username</Username>
        <Password>$password</Password>
    </SftpSettings>
</Configuration>
"@

        # Save the XML to disk
        $xml.Save($SftpConfigPath)

        [System.Windows.MessageBox]::Show(
            "SFTP settings have been saved successfully.",
            "Success",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        )
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Error saving SFTP settings: $_",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
})

# Load the configuration when the tab is first shown
Load_SftpConfig

# Return the constructed TabItem to the host script
return $TabItem

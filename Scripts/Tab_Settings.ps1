param(
    [System.Windows.Controls.TabItem]$TabItem
)

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
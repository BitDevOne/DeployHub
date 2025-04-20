Add-Type -AssemblyName PresentationFramework

# Main window XAML
$XamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Deploy HUB" Height="600" Width="800"
        Background="#F0F0F0">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="MinWidth" Value="120"/>
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="ListBox">
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Background" Value="White"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Margin" Value="5"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Padding" Value="10,5"/>
        </Style>
    </Window.Resources>
    <TabControl x:Name="MainTabControl"/>
</Window>
"@

# Parse the XAML
[xml]$XmlMain   = $XamlMain
$ReaderMain     = New-Object System.Xml.XmlNodeReader $XmlMain
$WindowMain     = [Windows.Markup.XamlReader]::Load($ReaderMain)

# Folder where your Tab_*.ps1 scripts live
$folder = Join-Path $PSScriptRoot 'Scripts'

# Define the exact order of your tab scripts
$order = @(
    'Tab_TaskSequence.ps1'
    'Tab_Settings.ps1'
)

# Load each tab in the specified order
foreach ($fileName in $order) {
    $path = Join-Path $folder $fileName
    if (Test-Path $path) {
        # Dot-source the script to get back a TabItem object
        $tab = . $path
        # Add it to the TabControl
        $WindowMain.FindName('MainTabControl').Items.Add($tab)
    }
    else {
        Write-Warning "Tab script not found: $path"
    }
}

# Show the window
$WindowMain.ShowDialog()

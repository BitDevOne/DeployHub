param (
    [string]$FolderPath
)

Add-Type -AssemblyName PresentationFramework

# GUI definition in XAML
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Application Search (Chocolatey)"
        Height="200" Width="400" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Margin="10" FontSize="14" Text="Enter application name:"/>
        <TextBox Grid.Row="1" Name="txtSearchTerm" Margin="10" Height="25"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="10">
            <Button Name="btnSearch" Width="80" Height="30" Margin="5" Content="Search"/>
            <Button Name="btnCancel" Width="80" Height="30" Margin="5" Content="Cancel"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load GUI from XAML
[xml]$XamlObject = $Xaml
$Reader = (New-Object System.Xml.XmlNodeReader $XamlObject)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Get controls
$txtSearchTerm = $Window.FindName("txtSearchTerm")
$btnSearch = $Window.FindName("btnSearch")
$btnCancel = $Window.FindName("btnCancel")

# Event handler for "Search" button
$btnSearch.Add_Click({
    $global:SearchTerm = $txtSearchTerm.Text
    if ([string]::IsNullOrWhiteSpace($global:SearchTerm)) {
        [System.Windows.MessageBox]::Show("Please enter an application name!", "Error", "OK", "Error")
        return
    }
    $Window.Close()
})

# Event handler for "Cancel" button
$btnCancel.Add_Click({
    $global:SearchTerm = $null
    $Window.Close()
})

# Display GUI window
$Window.ShowDialog() | Out-Null

# If the user canceled the search
if ($null -eq $global:SearchTerm) {
    Write-Host "Operation canceled."
    exit
}

# Search for applications using Chocolatey
$results = choco search $global:SearchTerm --limit-output | ForEach-Object {
    if ($_ -match "^(?<Name>[^|]+)\|(?<Version>[^|]+)$") {
        [PSCustomObject]@{
            Name    = $matches.Name.Trim()
            Version = $matches.Version.Trim()
        }
    }
} | Where-Object { $_ -ne $null }

if ($results.Count -eq 0) {
    Write-Host "No results found for query: $global:SearchTerm"
    exit
}

# Display results in GUI and allow application selection
$selection = $results | Out-GridView -Title "Select an application" -OutputMode Single

if ($null -eq $selection) {
    [System.Windows.MessageBox]::Show("No application selected.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    exit
}

# Path to XML file
$outputPath = "$FolderPath\ApplicationsChoco.xml"

# Load or create XML document
if (Test-Path $outputPath) {
    $xml = New-Object System.Xml.XmlDocument
    $xml.Load($outputPath)
} else {
    $xml = New-Object System.Xml.XmlDocument
    $root = $xml.CreateElement("Applications")
    $xml.AppendChild($root)
}

# Check if the application already exists
$existingApp = $xml.SelectSingleNode("//Application[@Id='$($selection.Name)']")
if ($existingApp) {
    [System.Windows.MessageBox]::Show("The application $($selection.Name) has already been added", "Information", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
} else {
    # Create a new application entry
    $appElement = $xml.CreateElement("Application")
    $appElement.SetAttribute("Name", $selection.Name)
    $appElement.SetAttribute("Version", $selection.Version)
    $xml.DocumentElement.AppendChild($appElement)
    
    # Save XML file
    try {
        $xml.Save($outputPath)
        [System.Windows.MessageBox]::Show("Application has been saved", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        [System.Windows.MessageBox]::Show("Error while saving to XML file: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

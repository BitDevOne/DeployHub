# Ścieżka bazowa dla TaskSequences
param (
    [string]$TaskSequencesPath
)

Add-Type -AssemblyName PresentationFramework

# Szkic okna
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="New TaskSequence" Height="150" Width="300" WindowStartupLocation="CenterScreen">
    <StackPanel>
        <TextBox x:Name="FolderNameTextBox" Margin="10" />
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="10">
            <Button x:Name="SaveButton" Content="Save" Width="75" Margin="5" />
            <Button x:Name="CancelButton" Content="Cancel" Width="75" Margin="5" />
        </StackPanel>
    </StackPanel>
</Window>
"@

[xml]$XamlReaderMain = $xaml
$ReaderMain = (New-Object System.Xml.XmlNodeReader $XamlReaderMain)
$WindowAdd = [Windows.Markup.XamlReader]::Load($ReaderMain)

# Referencje do kontrolek
$FolderNameTextBox = $WindowAdd.FindName("FolderNameTextBox")
$SaveButton  = $WindowAdd.FindName("SaveButton")
$CancelButton = $WindowAdd.FindName("CancelButton")

# Obsługa przycisków
$SaveButton.Add_Click({
    $FolderName = $FolderNameTextBox.Text.Trim()
    if (-not [string]::IsNullOrEmpty($FolderName)) {
        $NewFolderPath = Join-Path -Path $TaskSequencesPath -ChildPath $FolderName
        if (-not (Test-Path $NewFolderPath)) {
            New-Item -ItemType Directory -Path $NewFolderPath | Out-Null
            $DefaultXmlPath = Join-Path -Path $TaskSequencesPath -ChildPath "TaskSequencesTemplate.xml"
            $NewXmlPath = Join-Path -Path $NewFolderPath -ChildPath "TaskSequences.xml"
            if (Test-Path $DefaultXmlPath) {
                Copy-Item -Path $DefaultXmlPath -Destination $NewXmlPath
            }
            [System.Windows.MessageBox]::Show("Folder and XML file created successfully.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } else {
            [System.Windows.MessageBox]::Show("Folder already exists.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    } else {
        [System.Windows.MessageBox]::Show("Please enter a valid folder name.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
    $WindowAdd.Close()
})

$CancelButton.Add_Click({
    $WindowAdd.Close()
})

# Wyświetlenie głównego okna
$WindowAdd.ShowDialog()

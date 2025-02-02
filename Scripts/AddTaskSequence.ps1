# Ścieżka bazowa dla TaskSequences
param (
    [string]$TaskSequencesPath,
    [string]$OSxmlFilePath
)

Add-Type -AssemblyName PresentationFramework

# Szkic okna
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="New Task Sequence" Height="210" Width="350" WindowStartupLocation="CenterScreen">
    <StackPanel Margin="10">
        
        <!-- Label and TextBox for Task Sequence Name -->
        <Label Content="Name of Task Sequence:"/>
        <TextBox x:Name="FolderNameTextBox" Margin="0,5,0,10"/>
        
        <!-- Label and ComboBox for OS Selection -->
        <Label Content="Select Operating System:"/>
        <ComboBox x:Name="OSComboBox" Margin="0,5,0,10"/>
        
        <!-- Buttons Panel -->
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="SaveButton" Content="Save" Width="75" Margin="5"/>
            <Button x:Name="CancelButton" Content="Cancel" Width="75" Margin="5"/>
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
$ComboBoxVersion = $WindowAdd.FindName("OSComboBox")

# Load ComboBox
[xml]$xmlData = Get-Content $OSxmlFilePath
foreach ($os in $xmlData.OSChoices.OS) {
    $ComboBoxVersion.Items.Add($os.Name)
}

# Obsługa przycisków
# Obsługa przycisku "Save"
$SaveButton.Add_Click({
    $FolderName = $FolderNameTextBox.Text.Trim()
    $SelectedOS = $ComboBoxVersion.SelectedItem

    if (-not [string]::IsNullOrEmpty($FolderName) -and -not [string]::IsNullOrEmpty($SelectedOS)) {
        $NewFolderPath = Join-Path -Path $TaskSequencesPath -ChildPath $FolderName
        if (-not (Test-Path $NewFolderPath)) {
            # Tworzenie folderu
            New-Item -ItemType Directory -Path $NewFolderPath | Out-Null

            # Ścieżki do plików XML
            $DefaultXmlPath = Join-Path -Path $TaskSequencesPath -ChildPath "TaskSequencesTemplate.xml"
            $NewXmlPath = Join-Path -Path $NewFolderPath -ChildPath "TaskSequences.xml"

            if (Test-Path $DefaultXmlPath) {
                # Kopiowanie pliku XML
                Copy-Item -Path $DefaultXmlPath -Destination $NewXmlPath

                # Wczytanie XML i modyfikacja
                [xml]$xmlDoc = Get-Content $NewXmlPath
                $FileNameNode = $xmlDoc.SelectSingleNode("//TaskSequence/Step/FileName")
                if ($FileNameNode -ne $null) {
                    $FileNameNode.InnerText = $SelectedOS
                    $xmlDoc.Save($NewXmlPath)
                }

                [System.Windows.MessageBox]::Show("Folder and XML file created successfully with updated OS value.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            }
        } else {
            [System.Windows.MessageBox]::Show("Folder already exists.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    } else {
        [System.Windows.MessageBox]::Show("Please enter a valid folder name and select an OS.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }

    $WindowAdd.Close()
})

$CancelButton.Add_Click({
    $WindowAdd.Close()
})

# Wyświetlenie głównego okna
$WindowAdd.ShowDialog()

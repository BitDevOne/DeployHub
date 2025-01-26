﻿Add-Type -AssemblyName PresentationFramework

# Główne GUI
$XamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Aplikacja GUI" Height="Auto" Width="400">
    <Grid>
        <TabControl>
            <TabItem Header="Task Sequences">
                <Grid>
                    <Button x:Name="AddButton" Content="Add New" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="75"/>
                    <Button x:Name="EditButton" Content="Edit" HorizontalAlignment="Left" Margin="95,10,0,0" VerticalAlignment="Top" Width="75"/>
                    <Button x:Name="RemoveButton" Content="Remove" HorizontalAlignment="Left" Margin="180,10,0,0" VerticalAlignment="Top" Width="75"/>
                    <ListBox x:Name="TaskSequenceList" HorizontalAlignment="Left" Margin="10,45,0,0" VerticalAlignment="Top" Width="360" Height="200"/>
                </Grid>
            </TabItem>
            <TabItem Header="Monitoring">
                <Grid>
                    
                </Grid>
            </TabItem>
            <TabItem Header="Settings">
                <Grid>
                    
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

[xml]$XamlReaderMain = $XamlMain
$ReaderMain = (New-Object System.Xml.XmlNodeReader $XamlReaderMain)
$WindowMain = [Windows.Markup.XamlReader]::Load($ReaderMain)

# Referencje do kontrolek
$AddButton = $WindowMain.FindName("AddButton")
$EditButton = $WindowMain.FindName("EditButton")
$RemoveButton = $WindowMain.FindName("RemoveButton")
$TaskSequenceList = $WindowMain.FindName("TaskSequenceList")

# Lokalizacja folderów Task Sequences
$TaskSequencesPath = "$PSScriptRoot\TaskSequences"
if (-not (Test-Path $TaskSequencesPath)) {
    New-Item -ItemType Directory -Path $TaskSequencesPath | Out-Null
}

# Funkcja odświeżania listy folderów
function Refresh_TaskSequenceList {
    $TaskSequenceList.Items.Clear()
    Get-ChildItem -Path $TaskSequencesPath -Directory | ForEach-Object {
        $TaskSequenceList.Items.Add($_.Name)
    }
}

# Obsługa przycisku "Add New"
$AddButton.Add_Click({
    & "$PSScriptRoot\Scripts\AddTaskSequence.ps1" -TaskSequencesPath $TaskSequencesPath
    Refresh_TaskSequenceList
})

# Obsługa przycisku "Edit"
$EditButton.Add_Click({
    if ($TaskSequenceList.SelectedIndex -ne -1) {
        $SelectedFolder = $TaskSequenceList.SelectedItem.ToString()
        $FolderPath = Join-Path -Path $TaskSequencesPath -ChildPath $SelectedFolder
        $XmlFilePath = Join-Path -Path $FolderPath -ChildPath "TaskSequences.xml"

        if (Test-Path $XmlFilePath) {
            & "$PSScriptRoot\Scripts\EditTaskSequence.ps1" -FolderPath $FolderPath -XmlFilePath $XmlFilePath
        } else {
            [System.Windows.MessageBox]::Show("Plik config.xml nie istnieje w wybranym folderze.", "Błąd", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})

# Obsługa przycisku "Remove"
$RemoveButton.Add_Click({
    if ($TaskSequenceList.SelectedIndex -ne -1) {
        $SelectedFolder = $TaskSequenceList.SelectedItem.ToString()
        $FolderPath = Join-Path -Path $TaskSequencesPath -ChildPath $SelectedFolder
        if (Test-Path $FolderPath) {
            Remove-Item -Path $FolderPath -Recurse -Force
            Refresh_TaskSequenceList
        }
    }
})

# Inicjalne wypełnienie listy
Refresh_TaskSequenceList

# Wyświetlenie głównego okna
$WindowMain.ShowDialog()

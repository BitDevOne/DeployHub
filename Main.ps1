Add-Type -AssemblyName PresentationFramework

# Main GUI
$XamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Deploy HUB" Height="400" Width="470">
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
            <TabItem Header="Applications">
                <Grid>
                    <!-- Define columns in the grid -->
                    <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <!-- Winget Section -->
                    <Label Content="Winget:" Grid.Column="0"/>
                    <Button x:Name="WingetAddButton" Content="Add New Winget Application" HorizontalAlignment="Left" Margin="10,30,0,0" VerticalAlignment="Top" Width="200"/>
                    <ListBox x:Name="WingetApplicationsList" HorizontalAlignment="Left" Margin="10,65,0,0" VerticalAlignment="Top" Width="200" Height="200"/>
                    <Button x:Name="WingetRemoveButton" Content="Remove Selected Winget Application" HorizontalAlignment="Left" Margin="10,280,0,0" VerticalAlignment="Top" Width="200"/>

                    <!-- Chocolatey Section -->
                    <Label Content="Chocolatey:" Grid.Column="1" Margin="20,0,0,0"/>
                    <Button x:Name="ChocoAddButton" Content="Add New Chocolatey Application" Grid.Column="1" Margin="30,30,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Width="200"/>
                    <ListBox x:Name="ChocoApplicationsList" Grid.Column="1" Margin="30,65,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Width="200" Height="200"/>
                    <Button x:Name="ChocoRemoveButton" Content="Remove Selected Chocolatey App" Grid.Column="1" Margin="30,280,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Width="200"/>
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

# References to controls
$AddButton = $WindowMain.FindName("AddButton")
$EditButton = $WindowMain.FindName("EditButton")
$RemoveButton = $WindowMain.FindName("RemoveButton")
$TaskSequenceList = $WindowMain.FindName("TaskSequenceList")
$WingetAddButton = $WindowMain.FindName("WingetAddButton")
$WingetRemoveButton = $WindowMain.FindName("WingetRemoveButton")
$WingetApplicationsList = $WindowMain.FindName("WingetApplicationsList")
$ChocoAddButton = $WindowMain.FindName("ChocoAddButton")
$ChocoRemoveButton = $WindowMain.FindName("ChocoRemoveButton")
$ChocoApplicationsList = $WindowMain.FindName("ChocoApplicationsList")

# Task Sequences folder location
$TaskSequencesPath = "$PSScriptRoot\TaskSequences"
if (-not (Test-Path $TaskSequencesPath)) {
    New-Item -ItemType Directory -Path $TaskSequencesPath | Out-Null
}

# Function to refresh the folder list
function Refresh_TaskSequenceList {
    $TaskSequenceList.Items.Clear()
    Get-ChildItem -Path $TaskSequencesPath -Directory | ForEach-Object {
        $TaskSequenceList.Items.Add($_.Name)
    }
}

# "Add New" button event handler
$AddButton.Add_Click({
    & "$PSScriptRoot\Scripts\AddTaskSequence.ps1" -TaskSequencesPath $TaskSequencesPath
    Refresh_TaskSequenceList
})

# "Edit" button event handler
$EditButton.Add_Click({
    if ($TaskSequenceList.SelectedIndex -ne -1) {
        $SelectedFolder = $TaskSequenceList.SelectedItem.ToString()
        $FolderPath = Join-Path -Path $TaskSequencesPath -ChildPath $SelectedFolder
        $XmlFilePath = Join-Path -Path $FolderPath -ChildPath "TaskSequences.xml"

        if (Test-Path $XmlFilePath) {
            & "$PSScriptRoot\Scripts\EditTaskSequence.ps1" -FolderPath $FolderPath -XmlFilePath $XmlFilePath
        } else {
            [System.Windows.MessageBox]::Show("The file TaskSequences.xml does not exist in the selected folder.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
})

# "Remove" button event handler
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

# Initial population of the list
Refresh_TaskSequenceList


# Applications Tabtest

# Winget applications folder location
$WingetApplicationsPath = "$PSScriptRoot\Config\Applications\Winget"

# Function to refresh the Winget applications list
function Refresh_WingetApplicationsList {
    $WingetApplicationsList.Items.Clear()
    Get-ChildItem -Path $WingetApplicationsPath -File -Filter "*.xml" | ForEach-Object {
        $WingetApplicationsList.Items.Add($_.BaseName)
    }
}

# "Add New" button event handler for Winget
$WingetAddButton.Add_Click({
    & "$PSScriptRoot\Scripts\WingetAppSearch.ps1" -FolderPath $WingetApplicationsPath
    Refresh_WingetApplicationsList
})

# "Remove" button event handler for Winget
$WingetRemoveButton.Add_Click({
    if ($WingetApplicationsList.SelectedIndex -ne -1) {
        $SelectedFolder = $WingetApplicationsList.SelectedItem.ToString()
        $FolderPath = Join-Path -Path $WingetApplicationsPath -ChildPath "$SelectedFolder.xml"
        if (Test-Path $FolderPath) {
            Remove-Item -Path $FolderPath -Recurse -Force
            Refresh_WingetApplicationsList
        }
    }
})

# Initial population of the Winget applications list
Refresh_WingetApplicationsList

# Chocolatey applications folder location
$ChocoApplicationsPath = "$PSScriptRoot\Config\Applications\Choco"

# Function to refresh the Chocolatey applications list
function Refresh_ChocoApplicationsList {
    $ChocoApplicationsList.Items.Clear()
    Get-ChildItem -Path $ChocoApplicationsPath -File -Filter "*.xml" | ForEach-Object {
        $ChocoApplicationsList.Items.Add($_.BaseName)
    }
}

# "Add New" button event handler for Chocolatey
$ChocoAddButton.Add_Click({
    & "$PSScriptRoot\Scripts\ChocoAppSearch.ps1" -FolderPath $ChocoApplicationsPath
    Refresh_ChocoApplicationsList
})

# "Remove" button event handler for Chocolatey
$ChocoRemoveButton.Add_Click({
    if ($ChocoApplicationsList.SelectedIndex -ne -1) {
        $SelectedFolder = $ChocoApplicationsList.SelectedItem.ToString()
        $FolderPath = Join-Path -Path $ChocoApplicationsPath -ChildPath "$SelectedFolder.xml"
        if (Test-Path $FolderPath) {
            Remove-Item -Path $FolderPath -Recurse -Force
            Refresh_ChocoApplicationsList
        }
    }
})

# Initial population of the Chocolatey applications list
Refresh_ChocoApplicationsList

# Display the main window
$WindowMain.ShowDialog()

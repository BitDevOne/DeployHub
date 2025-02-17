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
            <TabItem Header="Operating System">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <!-- Etykieta -->
                    <Label Content="List of Imported Systems:" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="2" Margin="5"/>

                    <!-- Lista systemów -->
                    <ListBox x:Name="ImportedSystemList" Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Margin="5" Height="250" VerticalAlignment="Top"/>

                    <!-- Przyciski -->
                    <Button x:Name="ImportOperatingSystem" Content="Import Operating System" Grid.Row="2" Grid.Column="0" Margin="5" Width="200" HorizontalAlignment="Left"/>
                    <Button x:Name="RemoveOperatingSystem" Content="Remove Selected Operating System" Grid.Row="2" Grid.Column="1" Margin="5" Width="200" HorizontalAlignment="Right"/>
                </Grid>
            </TabItem>

<TabItem Header="Monitoring">
    <Grid Margin="10">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="2*"/> <!-- Lewa strona (lista) -->
            <ColumnDefinition Width="3*"/> <!-- Prawa strona (edycja) -->
        </Grid.ColumnDefinitions>

        <!-- Lista komputerów -->
        <StackPanel Grid.Column="0" HorizontalAlignment="Stretch" VerticalAlignment="Stretch">
            <ListBox x:Name="ComputerDropdown" Height="300" Width="200" Margin="5"/>
        </StackPanel>

        <!-- Prawa strona - szczegóły wybranego komputera -->
        <StackPanel Grid.Column="1" Margin="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Computer Name -->
                <Label Content="Computer Name:" Grid.Row="0" Grid.Column="0" Margin="5"/>
                <TextBox x:Name="ComputerNameBox" Grid.Row="0" Grid.Column="1" Width="250" Margin="5"/>

                <!-- Service Tag -->
                <Label Content="Service Tag:" Grid.Row="1" Grid.Column="0" Margin="5"/>
                <TextBox x:Name="ServiceTagBox" Grid.Row="1" Grid.Column="1" Width="250" Margin="5" IsReadOnly="True"/>

                <!-- Task Selection -->
                <Label Content="Select Task:" Grid.Row="2" Grid.Column="0" Margin="5"/>
                <ComboBox x:Name="TaskDropdown" Grid.Row="2" Grid.Column="1" Width="250" Margin="5"/>

                <!-- Task Sequences -->
                <Label Content="Task Sequences:" Grid.Row="3" Grid.Column="0" Margin="5"/>
                <ComboBox x:Name="TaskSequencesDropdown" Grid.Row="3" Grid.Column="1" Width="250" Margin="5"/>

                <!-- Task Sequence Steps -->
                <Label Content="Task Sequence Steps:" Grid.Row="4" Grid.Column="0" Margin="5"/>
                <TextBox x:Name="TaskSequenceStepsBox" Grid.Row="4" Grid.Column="1" Width="250" Margin="5" IsReadOnly="True"/>

                <!-- Save Button -->
                <Button x:Name="StartButton" Content="Start" Grid.Row="5" Grid.Column="0" Grid.ColumnSpan="2" Width="100" Margin="5" HorizontalAlignment="Center"/>
            </Grid>
        </StackPanel>
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
$ImportedSystemList = $WindowMain.FindName("ImportedSystemList")
$ImportOperatingSystem = $WindowMain.FindName("ImportOperatingSystem")
$RemoveOperatingSystem = $WindowMain.FindName("RemoveOperatingSystem")
$ComputerDropdown = $WindowMain.FindName("ComputerDropdown")
$ComputerNameBox = $WindowMain.FindName("ComputerNameBox")
$ServiceTagBox = $WindowMain.FindName("ServiceTagBox")
$TaskDropdown = $WindowMain.FindName("TaskDropdown")
$TaskSequencesList = $WindowMain.FindName("TaskSequencesList")
$TaskSequenceStepsBox = $WindowMain.FindName("TaskSequenceStepsBox")
$StartButton = $WindowMain.FindName("StartButton")

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
    & "$PSScriptRoot\Scripts\AddTaskSequence.ps1" -TaskSequencesPath $TaskSequencesPath -OSxmlFilePath $xmlOSFilePath
    Refresh_TaskSequenceList
})

# "Edit" button event handler
$EditButton.Add_Click({
    if ($TaskSequenceList.SelectedIndex -ne -1) {
        $SelectedFolder = $TaskSequenceList.SelectedItem.ToString()
        $FolderPath = Join-Path -Path $TaskSequencesPath -ChildPath $SelectedFolder
        $XmlFilePath = Join-Path -Path $FolderPath -ChildPath "TaskSequences.xml"

        if (Test-Path $XmlFilePath) {
            & "$PSScriptRoot\Scripts\EditTaskSequence.ps1" -FolderPath $FolderPath -XmlFilePath $XmlFilePath -OsChoicesXmlFilePath $xmlOSFilePath
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


# Applications Tab

# Winget applications folder location
$WingetApplicationsPath = "$PSScriptRoot\Config\Applications\Winget"

# Function to refresh the Winget applications list
function Refresh_WingetApplicationsList {
    $WingetApplicationsList.Items.Clear()
    if (Test-Path "$WingetApplicationsPath\ApplicationsWinget.xml") {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load("$WingetApplicationsPath\ApplicationsWinget.xml")
        $xml.SelectNodes("//Application") | ForEach-Object {
            $WingetApplicationsList.Items.Add($_.GetAttribute("Name"))
        }
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
        $SelectedApp = $WingetApplicationsList.SelectedItem.ToString()
        if (Test-Path "$WingetApplicationsPath\ApplicationsWinget.xml") {
            $xml = New-Object System.Xml.XmlDocument
            $xml.Load("$WingetApplicationsPath\ApplicationsWinget.xml")
            $appNode = $xml.SelectSingleNode("//Application[@Name='$SelectedApp']")
            if ($appNode) {
                $xml.DocumentElement.RemoveChild($appNode)
                $xml.Save("$WingetApplicationsPath\ApplicationsWinget.xml")
                Refresh_WingetApplicationsList
            }
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
    if (Test-Path "$ChocoApplicationsPath\ApplicationsChoco.xml") {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load("$ChocoApplicationsPath\ApplicationsChoco.xml")
        $xml.SelectNodes("//Application") | ForEach-Object {
            $ChocoApplicationsList.Items.Add($_.GetAttribute("Name"))
        }
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
        $SelectedApp = $ChocoApplicationsList.SelectedItem.ToString()
        if (Test-Path "$ChocoApplicationsPath\ApplicationsChoco.xml") {
            $xml = New-Object System.Xml.XmlDocument
            $xml.Load("$ChocoApplicationsPath\ApplicationsChoco.xml")
            $appNode = $xml.SelectSingleNode("//Application[@Name='$SelectedApp']")
            if ($appNode) {
                $xml.DocumentElement.RemoveChild($appNode)
                $xml.Save("$ChocoApplicationsPath\ApplicationsChoco.xml")
                Refresh_ChocoApplicationsList
            }
        }
    }
})

# Initial population of the Chocolatey applications list
Refresh_ChocoApplicationsList

# Operating System Tab

# Path to os xml file
$xmlOSFilePath = "$PSScriptRoot\Config\Operating Systems\Operating_Systems.xml"

# Path to os import folder

$ImportOSPath = "$PSScriptRoot\Operating Systems"

# Load System list from xml
function Refresh_OSList {
    [xml]$xmlDataOS = Get-Content $xmlOSFilePath
    $ImportedSystemList.Items.Clear()
    
    foreach ($os in $xmlDataOS.OSChoices.OS) {
        $ImportedSystemList.Items.Add("$($os.Name)")
    }
}

# Import button event handler
$ImportOperatingSystem.Add_Click({
    & "$PSScriptRoot\Scripts\OSImport.ps1" -xmlFolderPath $xmlOSFilePath -OSFolderPath $ImportOSPath
    Refresh_OSList
})

# Remove Button event handler
$RemoveOperatingSystem.Add_Click({
    $SelectedItemOS = $ImportedSystemList.SelectedItem
    if (-not $SelectedItemOS) {
        [System.Windows.MessageBox]::Show("Please select an OS to remove.", "Error", "OK", "Error")
        return
    }
    
    # Pobranie nazwy wybranego systemu operacyjnego i usunięcie zbędnych spacji
    $osName = $SelectedItemOS.Trim()

    # Wczytanie XML i znalezienie elementu do usunięcia
    [xml]$xmlDataOS = Get-Content $xmlOSFilePath
    $osList = $xmlDataOS.OSChoices.OS  # Pobieramy listę elementów

    # Znalezienie elementu na podstawie nazwy
    $osToRemove = $osList | Where-Object { $_.Name -eq $osName }

    if ($osToRemove) {
        # Pobranie ścieżki pliku do usunięcia
        $osPath = $osToRemove.Path

        # Sprawdzenie, czy element rzeczywiście istnieje w XML
        if ($osToRemove.ParentNode -ne $null) {
            # Usunięcie elementu XML
            $osToRemove.ParentNode.RemoveChild($osToRemove) | Out-Null  

            # Zapisanie zmian do pliku XML
            $xmlDataOS.Save($xmlOSFilePath)

            # Sprawdzenie, czy plik istnieje i usunięcie go
            if (Test-Path $osPath) {
                try {
                    Remove-Item -Path $osPath -Force -ErrorAction Stop
                    [System.Windows.MessageBox]::Show("Operating System and associated file removed successfully.", "Success", "OK", "Information")
                } catch {
                    [System.Windows.MessageBox]::Show("Failed to remove OS file: $_", "Error", "OK", "Error")
                }
            } else {
                [System.Windows.MessageBox]::Show("Operating System entry removed from XML, but file not found.", "Warning", "OK", "Warning")
            }

            Refresh_OSList
        } else {
            [System.Windows.MessageBox]::Show("ParentNode is null. OS not removed.", "Error", "OK", "Error")
        }
    } else {
        [System.Windows.MessageBox]::Show("Operating System not found.", "Error", "OK", "Error")
    }
})


# Initial population of OS list
Refresh_OSList

# Monitoring Tab

# Directory Path where each computer has its own folder
$ComputersDirectoryPath = "$PSScriptRoot\Computers"
$TaskSequencesConfigPath = "$PSScriptRoot\Config\TaskSequences.xml"

# Function to load computer list from individual XML files in directories
function Load_ComputerList {
    $ComputerDropdown.Items.Clear()
    
    if (Test-Path $ComputersDirectoryPath) {
        Get-ChildItem -Path $ComputersDirectoryPath -Directory -Recurse | ForEach-Object {
            $computerXmlPath = "$($_.FullName)\ComputerConfiguration.xml"
            if (Test-Path $computerXmlPath) {
                [xml]$xmlData = Get-Content $computerXmlPath
                $xmlData.ComputerConfiguration.Computer | ForEach-Object {
                    $ComputerDropdown.Items.Add($_.ComputerName)
                }
            }
        }
    }
}

# Tworzymy globalny słownik do przechowywania powiązań (ComputerName -> ServiceTag)
$ComputerMapping = @{}

# Function to load task sequences from XML
function Load_ComputerList {
    $ComputerDropdown.Items.Clear()
    $ComputerMapping.Clear()

    if (Test-Path $ComputersDirectoryPath) {
        Get-ChildItem -Path $ComputersDirectoryPath -Directory | ForEach-Object {
            $computerXmlPath = "$($_.FullName)\ComputerConfiguration.xml"

            if (Test-Path $computerXmlPath) {
                [xml]$xmlData = Get-Content -Path $computerXmlPath -Raw

                if ($xmlData.ComputerConfiguration -and $xmlData.ComputerConfiguration.Computer) {
                    $xmlData.ComputerConfiguration.Computer | ForEach-Object {
                        # Dodajemy do listy tylko ComputerName
                        $ComputerDropdown.Items.Add($_.ComputerName)

                        # Przechowujemy Service Tag dla tego komputera w słowniku
                        $ComputerMapping[$_.ComputerName] = $_.ServisTag
                    }
                }
            }
        }
    }
}



# Function to update UI when a computer is selected
$ComputerDropdown.Add_SelectionChanged({
    $SelectedComputer = $ComputerDropdown.SelectedItem
    if (-not $SelectedComputer) { return }

    # Pobieramy Service Tag z naszego słownika
    if ($ComputerMapping.ContainsKey($SelectedComputer)) {
        $SelectedServiceTag = $ComputerMapping[$SelectedComputer]
    } else {
        Write-Host "⚠ Nie znaleziono Service Tag dla komputera: $SelectedComputer" -ForegroundColor Yellow
        return
    }

    Write-Host "Wybrano komputer: $SelectedComputer, Service Tag: $SelectedServiceTag" -ForegroundColor Cyan

    # Budujemy ścieżkę do pliku XML na podstawie Service Tag
    $computerXmlPath = Join-Path -Path $ComputersDirectoryPath -ChildPath "$SelectedServiceTag\ComputerConfiguration.xml"

    if (Test-Path $computerXmlPath) {
        try {
            $xmlContent = Get-Content -Path $computerXmlPath -Raw
            [xml]$xmlData = $xmlContent

            $SelectedNode = $xmlData.ComputerConfiguration.Computer

            if ($SelectedNode) {
                # Wypełniamy pola formularza (z obsługą null)
                if ($ComputerNameBox) { $ComputerNameBox.Text = $SelectedNode.ComputerName }
                if ($ServiceTagBox) { $ServiceTagBox.Text = $SelectedNode.ServisTag }
                if ($TaskDropdown -and $SelectedNode.Task) { $TaskDropdown.SelectedItem = $SelectedNode.Task }
                if ($TaskSequencesList -and $SelectedNode.TaskSequences) { $TaskSequencesList.SelectedItem = $SelectedNode.TaskSequences }
                if ($TaskSequenceStepsBox -and $SelectedNode.TaskSequencesStep) { $TaskSequenceStepsBox.Text = $SelectedNode.TaskSequencesStep }

                Write-Host "✔ Formularz wypełniony poprawnie!" -ForegroundColor Green
            } else {
                Write-Host "⚠ Nie znaleziono danych w XML dla: $SelectedServiceTag" -ForegroundColor Red
            }
        } catch {
            Write-Host "❌ Błąd parsowania XML: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Plik XML nie istnieje: $computerXmlPath" -ForegroundColor Red
    }
})

# Start button event handler
$StartButton.Add_Click({
    $SelectedComputer = $ComputerDropdown.SelectedItem
    $SelectedTask = $TaskDropdown.SelectedItem
    $SelectedTaskSequence = $TaskSequencesList.SelectedItem
    
    if (-not $SelectedComputer -or -not $SelectedTask -or -not $SelectedTaskSequence) {
        [System.Windows.MessageBox]::Show("Please select all required fields before starting.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    # Save selected options to XML
    $computerXmlPath = "$ComputersDirectoryPath\$SelectedComputer\ComputerConfiguration.xml"
    if (Test-Path $computerXmlPath) {
        [xml]$xmlData = Get-Content $computerXmlPath
        $SelectedNode = $xmlData.ComputerConfiguration.Computer | Where-Object { $_.ComputerName -eq $SelectedComputer }
        
        if ($SelectedNode) {
            $SelectedNode.ComputerName = $ComputerNameBox.Text
            $SelectedNode.Task = $SelectedTask
            $SelectedNode.TaskSequences = $SelectedTaskSequence
            $xmlData.Save($computerXmlPath)
        }
    }
    
    [System.Windows.MessageBox]::Show("Starting task: $SelectedTask for computer: $SelectedComputer with sequence: $SelectedTaskSequence", "Information", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

# Function to monitor directory for new or changed XML files every 30 seconds
function Monitor_XMLChanges {
    $lastModified = Get-ChildItem -Path $ComputersDirectoryPath -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty LastWriteTime
    while ($true) {
        Start-Sleep -Seconds 30
        $currentModified = Get-ChildItem -Path $ComputersDirectoryPath -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty LastWriteTime
        if ($currentModified -ne $lastModified) {
            $lastModified = $currentModified
            Load_ComputerList
        }
    }
}

# Check if monitoring job is already running
$jobName = "MonitorXMLJob"
$existingJob = Get-Job -Name $jobName -ErrorAction SilentlyContinue
if (-not $existingJob) {
    # Start monitoring XML file in the background with job name if it doesn't exist
    Start-Job -Name $jobName -ScriptBlock {
        param($path)
        function Monitor_XMLChanges {
            $lastModified = Get-ChildItem -Path $path -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty LastWriteTime
            while ($true) {
                Start-Sleep -Seconds 30
                $currentModified = Get-ChildItem -Path $path -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty LastWriteTime
                if ($currentModified -ne $lastModified) {
                    $lastModified = $currentModified
                    Load_ComputerList
                }
            }
        }
        Monitor_XMLChanges
    } -ArgumentList $ComputersDirectoryPath
}

# Stop jobs when the script exits
$global:scriptExitHandler = {
    Get-Job -Name $jobName -ErrorAction SilentlyContinue | Stop-Job -Force
    Get-Job -Name $jobName -ErrorAction SilentlyContinue | Remove-Job -Force
}

Register-EngineEvent -SourceIdentifier "PowerShell.Exiting" -Action $scriptExitHandler

# Initialize lists
Load_ComputerList
Load_TaskSequencesList

# Display the main window
$WindowMain.ShowDialog()

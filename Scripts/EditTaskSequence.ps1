param (
    [string]$FolderPath,       # Ścieżka do folderu z XML
    [string]$XmlFilePath,       # Pełna ścieżka do pliku XML
    [string]$OsChoicesXmlFilePath # Pełna ścieżka do drugiego pliku XML (z OSChoices)
)

Add-Type -AssemblyName PresentationFramework, System.Xml.Linq

# Definicja XAML dla interfejsu użytkownika
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Advanced Task Sequence Creator" Height="600" Width="900">
    <DockPanel>
        <Menu DockPanel.Dock="Top">
            <MenuItem Header="_Add">
                <MenuItem Header="Install OS" Name="InstallOSMenu"/>
                <MenuItem Header="Run Command Line" Name="RunCommandLineMenu"/>
                <MenuItem Header="Run PowerShell Script" Name="RunPowershellScriptMenu"/>
                <MenuItem Header="Install Application" Name="InstallApplicationMenu"/>
            </MenuItem>
            <MenuItem Header="_Remove" Name="RemoveMenu"/>
            <MenuItem Header="_Up" Name="UPMenu"/>
            <MenuItem Header="_Down" Name="DOWNMenu"/>
        </Menu>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" DockPanel.Dock="Bottom" Margin="10">
            <Button Content="Save All" Name="SaveAllButton" Margin="5"/>
            <Button Content="Cancel" Name="CancelButton" Margin="5"/>
        </StackPanel>
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="3*"/>
                <ColumnDefinition Width="2*"/>
            </Grid.ColumnDefinitions>
            <TreeView Name="CommandTree" Margin="10">
                <TreeView.ItemTemplate>
                    <HierarchicalDataTemplate ItemsSource="{Binding Items}">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="{Binding Description}" />
                        </StackPanel>
                    </HierarchicalDataTemplate>
                </TreeView.ItemTemplate>
            </TreeView>
            <StackPanel Grid.Column="1" Margin="10" Name="DetailsPanel" Visibility="Collapsed">
                <Label Content="Type:"/>
                <TextBox Name="CommandType" Margin="0,5" IsReadOnly="True"/>
                <Label Content="Name:"/>
                <TextBox Name="CommandName" Margin="0,5"/>
                <Label Content="Command:" Name="CommandLabel" Visibility="Collapsed"/>
                <TextBox Name="CommandContent" Margin="0,5" AcceptsReturn="True" Visibility="Collapsed"/>
                <Label Content="OS Version:" Name="OsVersionLabel" Visibility="Collapsed"/>
                <ComboBox Name="OsVersionDropdown" Margin="0,5" Visibility="Collapsed"/>
                <Label Content="Application:" Name="ApplicationLabel" Visibility="Collapsed"/>
                <ComboBox Name="ApplicationDropdown" Margin="0,5" Visibility="Collapsed"/>
                <Button Content="Save" Name="SaveButton" Margin="0,10,0,0"/>
            </StackPanel>
        </Grid>
    </DockPanel>
</Window>

"@

# Implementacja logiki dla interfejsu użytkownika
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Znalezienie kontrolek
$commandTree = $window.FindName("CommandTree")
$commandType = $window.FindName("CommandType")
$commandName = $window.FindName("CommandName")
$commandContent = $window.FindName("CommandContent")
$commandLabel = $window.FindName("CommandLabel")
$detailsPanel = $window.FindName("DetailsPanel")
$saveButton = $window.FindName("SaveButton")
$saveAllButton = $window.FindName("SaveAllButton")
$cancelButton = $window.FindName("CancelButton")
$runCommandLineMenu = $window.FindName("RunCommandLineMenu")
$runPowershellScriptMenu = $window.FindName("RunPowershellScriptMenu")
$installApplicationMenu = $window.FindName("InstallApplicationMenu")
$installOSMenu = $window.FindName("InstallOSMenu")
$removeMenu = $window.FindName("RemoveMenu")
$upMenu = $window.FindName("UPMenu")
$downMenu = $window.FindName("DOWNMenu")
$osVersionLabel = $window.FindName("OsVersionLabel")
$osVersionDropdown = $window.FindName("OsVersionDropdown")
$applicationLabel = $window.FindName("ApplicationLabel")
$applicationDropdown = $window.FindName("ApplicationDropdown")

# Sprawdzenie, czy plik XML istnieje
if (-not (Test-Path $XmlFilePath)) {
    [System.Windows.MessageBox]::Show("Nie znaleziono pliku XML: $XmlFilePath", "Błąd", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    exit
}

# Wczytanie pliku XML
$xmlContent = [xml](Get-Content $XmlFilePath)

# Wczytanie dostępnych wersji OS z XML (jeśli istnieją w XML)
$osVersions = $xmlContent.TaskSequence.Step | Where-Object { $_.Type -eq "Apply System Image" } | Select-Object -ExpandProperty FileName -Unique
if ($osVersions.Count -eq 0) {
    $osVersions = @("Windows 10", "Windows 11", "Windows Server 2019")  # Domyślne wartości
}

if (-not (Test-Path $OsChoicesXmlFilePath)) {
    [System.Windows.MessageBox]::Show("Nie znaleziono pliku XML: $OsChoicesXmlFilePath", "Błąd", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    exit
}

# Wczytaj plik XML
$osChoicesXml = [xml](Get-Content $OsChoicesXmlFilePath)

# Pobierz nazwy systemów operacyjnych z OSChoices XML jako LISTĘ
$osChoices = @()
if ($osChoicesXml.OSChoices.OS) {
    $osChoicesXml.OSChoices.OS | ForEach-Object { $osChoices += $_.Name }
}

# Połącz OSVersions z pierwszego XML i OSChoices z drugiego XML, usuwając duplikaty
$allOsVersions = @($osVersions) + $osChoices | Sort-Object -Unique

# Wyczyść dropdown
$osVersionDropdown.Items.Clear()

# DEBUG: Sprawdź, co faktycznie mamy w allOsVersions
Write-Host "OS Versions: $allOsVersions"

# Wypełnienie listy rozwijanej OS
foreach ($os in $allOsVersions) {
    $osVersionDropdown.Items.Add($os)
}

# Ustaw domyślną wartość jako pierwsza z listy
if ($osVersionDropdown.Items.Count -gt 0) {
    $osVersionDropdown.SelectedItem = $osVersionDropdown.Items[0]
}


# Struktura danych do przechowywania hierarchii komend
$rootItems = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
$xmlContent.TaskSequence.Step | ForEach-Object {
    $rootItems.Add([PSCustomObject]@{
        Description = $_.Type
        Type = $_.Type
        Name = $_.Name
        Command = $_.Command
        OSVersion = if ($_.FileName) { $_.FileName } else { "" } # Pobieramy FileName jako OSVersion
    })
}
# Funkcja do odświeżania TreeView
function RefreshTreeView {
    $commandTree.Items.Clear()
    for ($i = 0; $i -lt $rootItems.Count; $i++) {
        $item = $rootItems[$i]
        $treeItem = New-Object System.Windows.Controls.TreeViewItem
        $treeItem.Header = "[$($i + 1)] $($item.Name)"
        $treeItem.Tag = $item
        $commandTree.Items.Add($treeItem)
    }
}

# Obsługa zapisywania wszystkich kroków do XML
$saveAllButton.Add_Click({
    $xmlContent = New-Object System.Xml.XmlDocument
    $rootElement = $xmlContent.CreateElement("TaskSequence")
    $xmlContent.AppendChild($rootElement) | Out-Null

    for ($i = 0; $i -lt $rootItems.Count; $i++) {
        $item = $rootItems[$i]
        $stepElement = $xmlContent.CreateElement("Step")

        $numberElement = $xmlContent.CreateElement("Number")
        $numberElement.InnerText = ($i + 1).ToString()
        $stepElement.AppendChild($numberElement) | Out-Null

        $typeElement = $xmlContent.CreateElement("Type")
        $typeElement.InnerText = $item.Type
        $stepElement.AppendChild($typeElement) | Out-Null

        $nameElement = $xmlContent.CreateElement("Name")
        $nameElement.InnerText = $item.Name
        $stepElement.AppendChild($nameElement) | Out-Null

        if ($item.Type -eq "Run Command Line" -or $item.Type -eq "Run PowerShell Script") {
            $commandElement = $xmlContent.CreateElement("Command")
            $commandElement.InnerText = $item.Command
            $stepElement.AppendChild($commandElement) | Out-Null
        }

        # 🔹 Poprawka: dodaj obsługę zapisu FileName dla Install OS (Apply System Image)
        if ($item.Type -eq "Apply System Image") {
            $fileNameElement = $xmlContent.CreateElement("FileName")
            $fileNameElement.InnerText = $item.OSVersion  # Używamy OSVersion jako FileName
            $stepElement.AppendChild($fileNameElement) | Out-Null
        }

        $rootElement.AppendChild($stepElement) | Out-Null
    }

    $xmlContent.Save($XmlFilePath)
    $window.Close()
})

# Obsługa anulowania i zamknięcia okna
$cancelButton.Add_Click({
    $window.Close()
})

# Obsługa zdarzeń Menu
$runCommandLineMenu.Add_Click({
    $newItem = [PSCustomObject]@{
        Description = "Run Command Line"
        Type = "Run Command Line"
        Name = "New Command Line Step"
        Command = ""
    }
    $rootItems.Add($newItem)
    RefreshTreeView
})

$runPowershellScriptMenu.Add_Click({
    $newItem = [PSCustomObject]@{
        Description = "Run PowerShell Script"
        Type = "Run PowerShell Script"
        Name = "New PowerShell Script Step"
        Command = ""
    }
    $rootItems.Add($newItem)
    RefreshTreeView
})

$installApplicationMenu.Add_Click({
    $newItem = [PSCustomObject]@{
        Description = "Install Application"
        Type = "Install Application"
        Name = "New Application Installation Step"
        Command = ""
    }
    $rootItems.Add($newItem)
    RefreshTreeView
})

$installOSMenu.Add_Click({
    $newItem = [PSCustomObject]@{
        Description = "Install OS"
        Type = "Apply System Image"
        Name = "Install OS"
        OSVersion = ""
    }
    $rootItems.Add($newItem)
    RefreshTreeView
})

$removeMenu.Add_Click({
    if ($commandTree.SelectedItem -ne $null) {
        $selectedItem = $commandTree.SelectedItem
        $rootItems.Remove($selectedItem.Tag)
        RefreshTreeView
    }
})

$upMenu.Add_Click({
    if ($commandTree.SelectedItem -ne $null) {
        $selectedItem = $commandTree.SelectedItem.Tag
        $index = $rootItems.IndexOf($selectedItem)
        if ($index -gt 0) {
            $rootItems.RemoveAt($index)
            $rootItems.Insert($index - 1, $selectedItem)
            RefreshTreeView
        }
    }
})

$downMenu.Add_Click({
    if ($commandTree.SelectedItem -ne $null) {
        $selectedItem = $commandTree.SelectedItem.Tag
        $index = $rootItems.IndexOf($selectedItem)
        if ($index -lt ($rootItems.Count - 1)) {
            $rootItems.RemoveAt($index)
            $rootItems.Insert($index + 1, $selectedItem)
            RefreshTreeView
        }
    }
})

# Obsługa szczegółów dla wybranych elementów w TreeView
$commandTree.add_SelectedItemChanged({
    if ($commandTree.SelectedItem -ne $null) {
        $selectedItem = $commandTree.SelectedItem.Tag
        $commandType.Text = $selectedItem.Type
        $commandName.Text = $selectedItem.Name

        # Ukryj wszystkie dodatkowe pola
        $commandLabel.Visibility = "Collapsed"
        $commandContent.Visibility = "Collapsed"
        $osVersionLabel.Visibility = "Collapsed"
        $osVersionDropdown.Visibility = "Collapsed"
        $applicationLabel.Visibility = "Collapsed"
        $applicationDropdown.Visibility = "Collapsed"

        # Pokaż odpowiednie pola na podstawie typu
        if ($selectedItem.Type -eq "Run Command Line" -or $selectedItem.Type -eq "Run PowerShell Script") {
            $commandContent.Text = $selectedItem.Command
            $commandLabel.Visibility = "Visible"
            $commandContent.Visibility = "Visible"
        } elseif ($selectedItem.Type -eq "Apply System Image") {
            $osVersionLabel.Visibility = "Visible"
            $osVersionDropdown.Visibility = "Visible"
            # Jeśli `OSVersion` istnieje w kroku, ustaw jako domyślnie wybrany
            if ($selectedItem.PSObject.Properties['OSVersion']) {
                if ($osVersionDropdown.Items.Contains($selectedItem.OSVersion)) {
                    $osVersionDropdown.SelectedItem = $selectedItem.OSVersion
                } else {
                    # Jeśli `OSVersion` nie pasuje do listy, wybierz pierwszą dostępną opcję
                    if ($osVersionDropdown.Items.Count -gt 0) {
                        $osVersionDropdown.SelectedItem = $osVersionDropdown.Items[0]
                    }
                }
            }
        } elseif ($selectedItem.Type -eq "Install Application") {
            $applicationLabel.Visibility = "Visible"
            $applicationDropdown.Visibility = "Visible"
        }

        $detailsPanel.Visibility = "Visible"
    } else {
        $detailsPanel.Visibility = "Collapsed"
    }
})

# Obsługa zapisywania zmienionej nazwy i komendy
$saveButton.Add_Click({
    if ($commandTree.SelectedItem -ne $null) {
        $selectedItem = $commandTree.SelectedItem.Tag
        $selectedItem.Name = $commandName.Text
        
        if ($selectedItem.Type -eq "Run Command Line" -or $selectedItem.Type -eq "Run PowerShell Script") {
            $selectedItem.Command = $commandContent.Text
        } elseif ($selectedItem.Type -eq "Apply System Image") {
            $selectedItem.OSVersion = $osVersionDropdown.SelectedItem
        } elseif ($selectedItem.Type -eq "Install Application") {
            $selectedItem.Application = $applicationDropdown.SelectedItem.Content
        }

        RefreshTreeView
    }
})

# Inicjalizacja widoku
RefreshTreeView

# Wyświetlenie okna
$window.ShowDialog() | Out-Null

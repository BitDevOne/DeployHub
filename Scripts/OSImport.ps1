param (
    [string]$xmlFolderPath,
    [string]$OSFolderPath
)
# Definicja XAML dla GUI
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="MDT OS Importer" Height="350" Width="450" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Grid Background="#F0F0F0">
        
        <!-- Step 1: Select ISO File -->
        <StackPanel x:Name="step1" Visibility="Visible" Margin="15">
            <GroupBox Header="Step 1: Select ISO File" Padding="10">
                <StackPanel>
                    <Label Content="Choose an ISO file:"/>
                    <DockPanel>
                        <TextBox x:Name="textBoxISO" Width="280" Margin="0,5,5,5"/>
                        <Button x:Name="buttonBrowse" Content="Browse" Width="80" Margin="0,5,5,5"/>
                    </DockPanel>
                    <Label Content="This may take a while..." FontStyle="Italic" Foreground="Gray"/>
                    <Button x:Name="buttonNext" Content="Next" HorizontalAlignment="Left" Width="80" Margin="0,5,5,5"/>
                </StackPanel>
            </GroupBox>
        </StackPanel>

        <!-- Step 2: Select OS Version -->
        <StackPanel x:Name="step2" Visibility="Collapsed" Margin="15">
            <GroupBox Header="Step 2: Select OS Version" Padding="10">
                <StackPanel>
                    <Label Content="Select OS version:"/>
                    <ComboBox x:Name="comboBoxVersion" Width="300" Margin="0,5,0,5"/>
                    <Button x:Name="buttonImport" Content="Import" HorizontalAlignment="Left" Width="80" Margin="0,5,5,5"/>
                </StackPanel>
            </GroupBox>
        </StackPanel>

        <!-- Step 3: Confirm File Name -->
        <StackPanel x:Name="step3" Visibility="Collapsed" Margin="15">
            <GroupBox Header="Step 3: Confirm File Name" Padding="10">
                <StackPanel>
                    <Label Content="File Name:"/>
                    <TextBox x:Name="textBoxFileName" Width="300" Margin="0,5,0,5"/>
                    <Label Content="This may take a while..." FontStyle="Italic" Foreground="Gray"/>
                    <Button x:Name="buttonConfirm" Content="Confirm" HorizontalAlignment="Left" Width="80" Margin="0,5,5,5"/>
                </StackPanel>
            </GroupBox>
        </StackPanel>
    </Grid>
</Window>
"@

# Załadowanie XAML
Add-Type -AssemblyName PresentationFramework
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Przypisanie kontrolek do zmiennych
$step1 = $window.FindName("step1")
$step2 = $window.FindName("step2")
$step3 = $window.FindName("step3")
$textBoxISO = $window.FindName("textBoxISO")
$buttonBrowse = $window.FindName("buttonBrowse")
$buttonNext = $window.FindName("buttonNext")
$comboBoxVersion = $window.FindName("comboBoxVersion")
$buttonImport = $window.FindName("buttonImport")
$textBoxFileName = $window.FindName("textBoxFileName")
$buttonConfirm = $window.FindName("buttonConfirm")

# Zmienna globalna do przechowywania wybranej wersji systemu
$global:selectedVersion = $null

# Funkcja do przeglądania pliku ISO
$buttonBrowse.Add_Click({
    $fileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $fileDialog.Filter = "Pliki ISO (*.iso)|*.iso"
    if ($fileDialog.ShowDialog() -eq $true) {
        $textBoxISO.Text = $fileDialog.FileName
    }
})

# Funkcja do przejścia do kroku 2
$buttonNext.Add_Click({
    $isoPath = $textBoxISO.Text
    if (-not (Test-Path $isoPath)) {
        [System.Windows.MessageBox]::Show("Nieprawidłowa ścieżka ISO!", "Błąd")
        return
    }

    # Montowanie ISO
    $driveLetter = (Mount-DiskImage -ImagePath $isoPath -PassThru | Get-Volume).DriveLetter
    $wimPath = "$driveLetter`:\sources\install.wim"

    if (-not (Test-Path $wimPath)) {
        [System.Windows.MessageBox]::Show("Plik install.wim nie został znaleziony!", "Błąd")
        Dismount-DiskImage -ImagePath $isoPath
        return
    }

    # Pobieranie listy wersji systemu
    $images = dism /Get-ImageInfo /ImageFile:$wimPath
    $versions = @()
    foreach ($line in $images) {
        if ($line -match "Index : (\d+)") {
            $index = $matches[1]
        }
        if ($line -match "Name : (.+)") {
            $name = $matches[1]
            $versions += "$index - $name"
        }
    }

    # Wypełnienie listy rozwijanej
    $comboBoxVersion.Items.Clear()
    foreach ($version in $versions) {
        $comboBoxVersion.Items.Add($version) | Out-Null
    }

    # Odmontowanie ISO
    Dismount-DiskImage -ImagePath $isoPath

    # Przejście do kroku 2
    $step1.Visibility = "Collapsed"
    $step2.Visibility = "Visible"
})

# Funkcja do przejścia do kroku 3
$buttonImport.Add_Click({
    $global:selectedVersion = $comboBoxVersion.SelectedItem
    #Write-Log "Wybrana wersja systemu: $global:selectedVersion"

    if (-not $global:selectedVersion) {
        [System.Windows.MessageBox]::Show("Nie wybrano wersji systemu!", "Błąd")
        return
    }

    # Ustawienie domyślnej nazwy pliku
    $fileName = ($global:selectedVersion -replace " - ", "_") -replace " ", "_"
    $textBoxFileName.Text = "$fileName.wim"

    # Przejście do kroku 3
    $step2.Visibility = "Collapsed"
    $step3.Visibility = "Visible"
})

# Ścieżka do logu
#$logPath = "import_log.txt"

# Funkcja do logowania
#function Write-Log {
#    param ([string]$message)
#    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#    "$timestamp - $message" | Out-File -Append -FilePath $logPath
#}

# Funkcja do potwierdzenia nazwy pliku i importowania
$buttonConfirm.Add_Click({
    #Write-Log "===== Rozpoczynanie importu systemu ====="

    $fileName = $textBoxFileName.Text.Trim()

    # Pobranie indeksu wersji
    $index = $global:selectedVersion -replace " - .+", ""
    #Write-Log "Wybrany indeks systemu: $index"

    if (-not $index) {
        [System.Windows.MessageBox]::Show("Nie można pobrać indeksu systemu!", "Błąd")
        Write-Log "Błąd: Nie można pobrać indeksu systemu"
        return
    }

    # Montowanie ISO
    $isoPath = $textBoxISO.Text
    #Write-Log "Montowanie ISO: $isoPath"

    try {
        $driveLetter = (Mount-DiskImage -ImagePath $isoPath -PassThru | Get-Volume).DriveLetter
        $wimPath = "$driveLetter`:\sources\install.wim"
        #Write-Log "Plik WIM: $wimPath"

        if (-not (Test-Path $wimPath)) {
            throw "Nie znaleziono pliku install.wim w ISO!"
        }
    } catch {
        [System.Windows.MessageBox]::Show("Błąd montowania ISO lub brak install.wim!", "Błąd")
        #Write-Log "Błąd: $_"
        return
    }

    # Ścieżka do zapisu obrazu
    $extractPath = $OSFolderPath
    if (-not (Test-Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath | Out-Null
        #Write-Log "Utworzono katalog: $extractPath"
    }

    # Pełna ścieżka do tymczasowego pliku WIM
    $tempWim = "$extractPath\temp_$index.wim"

    #Write-Log "Eksportowanie obrazu DISM do tymczasowego pliku: $tempWim"

    # Ekstrakcja obrazu
    try {
        dism /export-image /SourceImageFile:$wimPath /SourceIndex:$index /DestinationImageFile:$tempWim /Compress:max /CheckIntegrity
        #Write-Log "Eksport ukończony pomyślnie"
    } catch {
        [System.Windows.MessageBox]::Show("Błąd podczas eksportowania obrazu!", "Błąd")
        #Write-Log "Błąd eksportowania: $_"
        Dismount-DiskImage -ImagePath $isoPath
        return
    }

    # Odmontowanie ISO
    Dismount-DiskImage -ImagePath $isoPath
    #Write-Log "ISO odmontowane"

    # Teraz zmiana nazwy pliku
    #Write-Log "Zmiana nazwy pliku na: $fileName"

    # Sprawdzenie, czy nazwa pliku nie jest pusta
    if (-not $fileName) {
        [System.Windows.MessageBox]::Show("Nazwa pliku nie może być pusta!", "Błąd")
        #Write-Log "Błąd: Pusta nazwa pliku"
        return
    }

    # Sprawdzenie, czy nazwa pliku zawiera niedozwolone znaki
    if ($fileName -match '[\\/:*?"<>|]') {
        [System.Windows.MessageBox]::Show("Nazwa pliku zawiera niedozwolone znaki!", "Błąd")
        #Write-Log "Błąd: Niedozwolone znaki w nazwie pliku"
        return
    }

    # Dodanie rozszerzenia .wim, jeśli użytkownik go nie podał
    if (-not $fileName.ToLower().EndsWith(".wim")) {
        $fileName += ".wim"
    }

    # Pełna ścieżka do nowego pliku WIM
    $destinationWim = "$extractPath\$fileName"

    # Sprawdzenie, czy plik już istnieje
    if (Test-Path $destinationWim) {
        $result = [System.Windows.MessageBox]::Show("Plik '$fileName' już istnieje. Czy chcesz go zastąpić?", "Potwierdzenie", "YesNo", "Warning")
        if ($result -ne "Yes") {
            #Write-Log "Użytkownik anulował nadpisanie pliku: $destinationWim"
            return
        }
    }

    # Przeniesienie pliku do nowej nazwy
    try {
        Move-Item -Path $tempWim -Destination $destinationWim -Force
        #Write-Log "Zmieniono nazwę pliku na: $destinationWim"
    } catch {
        [System.Windows.MessageBox]::Show("Błąd podczas zmiany nazwy pliku!", "Błąd")
        #Write-Log "Błąd zmiany nazwy: $_"
        return
    }

    # Zapisanie wyboru do pliku XML
    $xmlPath = $xmlOSFilePath
    if (-not (Test-Path $xmlPath)) {
        $xml = New-Object System.Xml.XmlDocument
        $root = $xml.CreateElement("OSChoices")
        $xml.AppendChild($root)
    } else {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($xmlPath)
    }

    $osElement = $xml.CreateElement("OS")
    $osElement.SetAttribute("Index", $index)
    $osElement.SetAttribute("Name", $fileName)
    $osElement.SetAttribute("Path", $destinationWim)
    $xml.DocumentElement.AppendChild($osElement)
    $xml.Save($xmlPath)

    [System.Windows.MessageBox]::Show("Wersja systemu została zaimportowana i zapisana jako '$fileName'!", "Sukces")
    #Write-Log "Import ukończony sukcesem"
    $window.Close()
})

# Wyświetlenie okna
$window.ShowDialog() | Out-Null
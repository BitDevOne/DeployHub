param (
    [string]$FolderPath
)

Add-Type -AssemblyName PresentationFramework

# Definicja GUI w XAML
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Wyszukiwanie aplikacji"
        Height="200" Width="400" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Margin="10" FontSize="14" Text="Podaj nazwę aplikacji:"/>
        <TextBox Grid.Row="1" Name="txtSearchTerm" Margin="10" Height="25"/>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="10">
            <Button Name="btnSearch" Width="80" Height="30" Margin="5" Content="Szukaj"/>
            <Button Name="btnCancel" Width="80" Height="30" Margin="5" Content="Anuluj"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Wczytaj GUI z XAML
[xml]$XamlObject = $Xaml
$Reader = (New-Object System.Xml.XmlNodeReader $XamlObject)
$Window = [Windows.Markup.XamlReader]::Load($Reader)

# Pobierz kontrolki
$txtSearchTerm = $Window.FindName("txtSearchTerm")
$btnSearch = $Window.FindName("btnSearch")
$btnCancel = $Window.FindName("btnCancel")

# Obsługa zdarzenia przycisku "Szukaj"
$btnSearch.Add_Click({
    $global:SearchTerm = $txtSearchTerm.Text
    if ([string]::IsNullOrWhiteSpace($global:SearchTerm)) {
        [System.Windows.MessageBox]::Show("Proszę podać nazwę aplikacji!", "Błąd", "OK", "Error")
        return
    }
    $Window.Close()
})

# Obsługa zdarzenia przycisku "Anuluj"
$btnCancel.Add_Click({
    $global:SearchTerm = $null
    $Window.Close()
})

# Wyświetl okno GUI
$Window.ShowDialog() | Out-Null

# Jeśli użytkownik anulował wyszukiwanie
if ($null -eq $global:SearchTerm) {
    Write-Host "Operacja anulowana."
    exit
}

# Wyszukiwanie aplikacji za pomocą winget
$results = winget search $global:SearchTerm | ForEach-Object {
    if ($_ -match "^\S+\s+\S+\s+.*") {
        $fields = ($_ -split '\s{2,}')
        [PSCustomObject]@{
            Name    = $fields[0]
            Id      = $fields[1]
            Version = if ($fields.Count -ge 3) { $fields[2] } else { "" }
        }
    }
} | Where-Object { $_ -ne $null }

if ($results.Count -eq 0) {
    Write-Host "Brak wyników dla zapytania: $global:SearchTerm"
    exit
}

# Wyświetlanie wyników w GUI i umożliwienie wyboru aplikacji
$selection = $results | Out-GridView -Title "Wybierz aplikację" -OutputMode Single

if ($null -eq $selection) {
    [System.Windows.MessageBox]::Show("Nie wybrano żadnej aplikacji.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    exit
}

# Wyświetlenie ID wybranej aplikacji
#Write-Host "Wybrano aplikację: $($selection.Name)"
#Write-Host "ID: $($selection.Id)"

# Ścieżka do pliku XML
$outputPath = "$FolderPath\$($selection.Name).xml"

# Sprawdzenie, czy plik XML istnieje
if (Test-Path $outputPath) {
    [System.Windows.MessageBox]::Show("Aplikacja $($selection.Name) juz została dodana", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
} else {
    # Tworzenie nowego dokumentu XML
    $xml = New-Object System.Xml.XmlDocument
    $root = $xml.CreateElement("Application")
    $xml.AppendChild($root) | Out-Null

    $nameNode = $xml.CreateElement("Name")
    $nameNode.InnerText = $selection.Name
    $root.AppendChild($nameNode) | Out-Null

    $idNode = $xml.CreateElement("ID")
    $idNode.InnerText = $selection.Id
    $root.AppendChild($idNode) | Out-Null

    # Zapis pliku XML
    try {
        $xml.Save($outputPath)
        #Write-Host "Utworzono i zapisano nowy plik XML dla aplikacji: $outputPath"
        [System.Windows.MessageBox]::Show("Aplikacja została zapisana", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        #Write-Host "Błąd podczas zapisu do pliku XML: $_"
    }
}

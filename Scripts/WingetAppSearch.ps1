function Search-App {
    param (
        [string]$SearchTerm
    )

    # Wyszukiwanie aplikacji za pomocą winget
    $results = winget search $SearchTerm | ForEach-Object {
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
        Write-Host "Brak wyników dla zapytania: $SearchTerm"
        return
    }

    # Wyświetlanie wyników w GUI i umożliwienie wyboru aplikacji
    $selection = $results | Out-GridView -Title "Wybierz aplikację" -OutputMode Single

    if ($null -eq $selection) {
        Write-Host "Nie wybrano żadnej aplikacji."
        return
    }

    # Wyświetlenie ID wybranej aplikacji
    Write-Host "Wybrano aplikację: $($selection.Name)"
    Write-Host "ID: $($selection.Id)"

    # Ścieżka do pliku XML
    $outputPath = "./SelectedApps.xml"

    # Wczytanie lub utworzenie pliku XML
    [xml]$xml
    if (Test-Path $outputPath) {
        try {
            $xml = [xml](Get-Content $outputPath)
        } catch {
            Write-Host "Błąd podczas wczytywania pliku XML: $_"
            return
        }
    } else {
        $xml = New-Object -TypeName System.Xml.XmlDocument
        $root = $xml.CreateElement("Applications")
        $xml.AppendChild($root) | Out-Null
    }

    # Upewnienie się, że element Applications istnieje i jest węzłem
    if (-not $xml.DocumentElement -or $xml.DocumentElement.LocalName -ne "Applications") {
        $root = $xml.CreateElement("Applications")
        $xml.AppendChild($root) | Out-Null
    }

    # Sprawdzenie, czy aplikacja już istnieje
    $appExists = $xml.SelectNodes("//Applications/Application") | Where-Object {
        $_.Name -eq $selection.Name -and $_.ID -eq $selection.Id
    }

    if ($appExists) {
        Write-Host "Aplikacja już istnieje w pliku XML. Nie dodano ponownie."
        return
    }

    # Dodanie nowego wpisu
    $appNode = $xml.CreateElement("Application")

    $nameNode = $xml.CreateElement("Name")
    $nameNode.InnerText = $selection.Name
    $appNode.AppendChild($nameNode) | Out-Null

    $idNode = $xml.CreateElement("ID")
    $idNode.InnerText = $selection.Id
    $appNode.AppendChild($idNode) | Out-Null

    # Dodanie nowego węzła do Applications
    $xml.DocumentElement.AppendChild($appNode) | Out-Null

    # Zapis pliku XML
    try {
        $xml.Save($outputPath)
        Write-Host "Dodano nową aplikację do pliku XML: $outputPath"
    } catch {
        Write-Host "Błąd podczas zapisu do pliku XML: $_"
    }
}

# Zapyta użytkownika o aplikację do wyszukania
$searchTerm = Read-Host "Podaj nazwę aplikacji do wyszukania"

# Uruchomienie funkcji wyszukiwania
Search-App -SearchTerm $searchTerm

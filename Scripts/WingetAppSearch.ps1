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
    $outputPath = "./Config/Applications/$($selection.Name).xml"

    # Sprawdzenie, czy plik XML istnieje
    if (Test-Path $outputPath) {
        Write-Host "Plik XML dla aplikacji $($selection.Name) już istnieje."
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
            Write-Host "Utworzono i zapisano nowy plik XML dla aplikacji: $outputPath"
        } catch {
            Write-Host "Błąd podczas zapisu do pliku XML: $_"
        }
    }
}

# Zapyta użytkownika o aplikację do wyszukania
$searchTerm = Read-Host "Podaj nazwę aplikacji do wyszukania"

# Uruchomienie funkcji wyszukiwania
Search-App -SearchTerm $searchTerm

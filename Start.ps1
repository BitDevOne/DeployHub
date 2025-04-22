Add-Type -AssemblyName PresentationFramework

# 1) Wczytaj główny XAML okna
$uiXamlPath   = Join-Path $PSScriptRoot 'UI.xml'
[xml]$xmlMain = Get-Content $uiXamlPath -Raw
$readerMain   = New-Object System.Xml.XmlNodeReader $xmlMain
$windowMain   = [Windows.Markup.XamlReader]::Load($readerMain)

# 2) Lista par: XAML i odpowiadający mu skrypt code‑behind
$tabs = @(
    @{ Xaml='Scripts\Tab_TaskSequence.xml'; Script='Scripts\Tab_TaskSequence.ps1' }
    @{ Xaml='Scripts\Tab_Settings.xml';     Script='Scripts\Tab_Settings.ps1' }
)

foreach ($t in $tabs) {
    # 2a) wczytaj XAML zakładki
    $xamlPath = Join-Path $PSScriptRoot $t.Xaml
    [xml]$xmlTab = Get-Content $xamlPath -Raw
    $readerTab  = New-Object System.Xml.XmlNodeReader $xmlTab
    $tabItem    = [Windows.Markup.XamlReader]::Load($readerTab)

    # 2b) uruchom skrypt, przekazując wczytany TabItem
    #    (skrypt nie powinien niczego zwracać na wyjście poza ewentualnym Out-Null)
    . (Join-Path $PSScriptRoot $t.Script) -TabItem $tabItem

    # 2c) dodaj do TabControl
    $windowMain.FindName('MainTabControl').Items.Add($tabItem)
}

# 3) wyświetl okno
$windowMain.ShowDialog()

Add-Type -AssemblyName PresentationFramework

# Main GUI
$XamlMain = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Deploy HUB" Height="600" Width="800"
        Background="#F0F0F0">
        <TabControl>
            <TabItem Header="Task Sequences">
            </TabItem>
        </TabControl>
</Window>
"@


[xml]$XamlReaderMain = $XamlMain
$ReaderMain = (New-Object System.Xml.XmlNodeReader $XamlReaderMain)
$WindowMain = [Windows.Markup.XamlReader]::Load($ReaderMain)

# Display the main window
$WindowMain.ShowDialog()
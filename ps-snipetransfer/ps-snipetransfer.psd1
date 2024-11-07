# PS-SnipeTransfer.psd1
@{
    # Module metadata
    ModuleVersion = '1.0.4'
    GUID = '8e1b265f-fefa-4b65-9eda-1fb393ce5dad'
    Author = 'something_amusing'
    Description = 'Cmdlets to transfer assets and accessories in Snipe-IT between users, locations, and assets.'

    # Required PowerShell version
    PowerShellVersion = '5.1'

    # The root module (the .psm1 file)
    RootModule = 'ps-snipetransfer.psm1'

    # Functions to export
    FunctionsToExport = @('Initialize-SnipeConnection', 'New-SnipeTransferAll', 'New-SnipeTransfer', 'New-SnipeCheckout', 'New-SnipeCheckin')

    # Module dependencies
    RequiredModules = @()

    # The file to load for module initialization (optional)
    # ScriptFile = 'init.ps1'
}
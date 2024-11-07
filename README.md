# ps-snipetransfer

Powershell cmdlets to transfer assets from one user to another.

> [!IMPORTANT]
> References to IDs (asset IDs, User IDs, etc.) are references to the database IDs. You can find these in the URL when looking at a user, asset, etc. This is **NOT** the asset tag or the username.

> [!CAUTION]
> If you are using a CSV or other bulk method for processing transfers, you may want to add a sleep timer between users you are processing. Lots of transfers in a short time will exceed the API rate limit and you will start seeing a lot of errors. Alternatively, if you are hosting your own Snipe-IT server, you can change the API rate limit.

## Future Updates

* Add additional help to modules with more examples.
* Add additional functions as needed (display list of assets for a user, etc.)

## Quickstart

1. Install the module from Powershell Gallery `Install-Module -name PS-SnipeTransfer`
2. Run the initialization cmdlet to collect your connection info: `Initialize-SnipeConnection`
3. Provide your URL and API Personal Access Token (<https://snipe-it.readme.io/reference/generating-api-tokens>)
4. Run the cmdlets as needed. See examples below.

## Available Cmdlets

* Initialize-SnipeConnection - Set connection variables for other modules.
* New-SnipeTransferAll - Transfer all assets and accessories from one user to another.
* New-SnipeTransfer - Transfer an asset or accessory from one user, location, or asset to another.
* New-SnipeCheckout - Check out an asset or accessory. Intended to be used by the Transfer functions, but you can also use it directly.
* New-SnipeCheckin - Check in an asset or accessory. Intended to be used by the Transfer functions, but you can also use it directly.

## Help

You can run get-help on any of the cmdlets to get more information.

## Examples

### Transfer everything

```powershell
New-SnipeTransferAll -FromID <OldUserID> -ToID <NewUserID>
```

### Transfer one asset from a user to another user

```powershell
New-SnipeTransfer -TransferID <Asset ID> -ToID <User ID>
```

### Transfer one accessory from a user to another user

```powershell
New-SnipeTransfer -TransferType 'accessory' -TransferID <accessory+user Pivot ID> -AccessoryID <Accessory ID> -ToID <User ID>
```

### Transfer one asset from a user to an asset

```powershell
New-SnipeTransfer -TransferID <Asset ID> -ToType 'asset' -ToID <Asset ID>

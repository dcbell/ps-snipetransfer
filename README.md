# ps-snipetransfer

Powershell function to transfer assets from one user to another.

> [!IMPORTANT]
> References to IDs (asset IDs, User IDs, etc.) are references to the database IDs. You can find these in the URL when looking at a user, asset, etc. This is **NOT** the asset tag or the username.

> [!CAUTION]
> If you are using a CSV or other bulk method for processing transfers, you may want to add a sleep timer between users you are processing. Lots of transfers in a short time will exceed the API rate limit and you will start seeing a lot of errors. Alternatively, if you are hosting your own Snipe-IT server, you can change the API rate limit.

## Future Updates

* Build the necessary files to make the functions here into cmdlets.
* Add additional functions as needed (display list of assets for a user, etc.)

## Quickstart

You can either paste the entire code into a PowerShell terminal and then execute functions as needed, or build out a main script below the functions.

## Examples

### Transfer everything

To transfer everything from one user or another:

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

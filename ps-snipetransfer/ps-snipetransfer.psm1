function Initialize-SnipeConnection {
	[CmdletBinding()]
	<#
		.SYNOPSIS
		Set connection variables for other modules.

		.DESCRIPTION
		Set connection variables for other modules.

		.PARAMETER SnipeURL
		[string] Required. URL of your Snipe-IT instance with no trailing slash. i.e. "https://org.snipe-it.io"

		.PARAMETER ApiKey
		[string] Required. API Personal Access Token for your Snipe-IT instance. For help go here https://snipe-it.readme.io/reference/generating-api-tokens
	#>

	param (
		[Parameter(Mandatory=$true)]
		[string]$SnipeURL,

		[Parameter(Mandatory=$True)]
		[string]$ApiKey
	)

	$script:SnipeURL = $SnipeURL
	$script:ApiKey = $ApiKey
	$script:ConnectionTested = $false
	
	# Validate connection
	$response = $null
	$headers=@{}
	$headers.Add("accept", "application/json")
	$headers.Add("Authorization", "Bearer $script:ApiKey")
	$ApiUrl = "$script:SnipeURL/api/v1/user?limit=5" 
	$response = Invoke-WebRequest -Uri $ApiUrl -Method GET -Headers $headers

	if($response.Count -gt 0) { 
		Write-Host "Connection verified." 
		$script:ConnectionTested = $true
	} else { Throw "Connection failure. Verify URL and API key and make sure at least 1 user exists in Snipe-IT." }
}

function New-SnipeCheckin {
	[CmdletBinding()]
	<#
		.SYNOPSIS
		Check in an asset or accessory.

		.DESCRIPTION
		Check in an asset or accessory.

		.PARAMETER CheckinType
		[string] Optional. Defaults to 'asset'. Type of object (asset or accessory) to check in.

		.PARAMETER CheckinID
		[int] Required. ID of the asset or accessory+user (not accessory ID) to check in.
	#>

	param (
		[Parameter(Mandatory=$false)]
		[string]$CheckinType="asset",

        [Parameter(Mandatory=$true)]
        [int]$CheckinID
	)

	if($script:ConnectionTested -eq $false) { Throw "Connection not established. Please run Initialize-SnipeConnection first." }

	# Set API headers
	$headers=@{}
	$headers.Add("accept", "application/json")
	$headers.Add("Authorization", "Bearer $script:ApiKey")

	switch ($CheckinType) {
		"asset" { 
			$headers.Add("content-type", "application/json")
			$ApiUrl = "$script:SnipeURL/api/v1/hardware/$CheckinID/checkin" 
			$response = Invoke-WebRequest -Uri $ApiUrl -Method POST -Headers $headers -ContentType 'application/json' -Body "{ `"status_id`":null}" | ConvertFrom-Json
		}
		"accessory" { 
			$ApiUrl = "$script:SnipeURL/api/v1/accessories/$CheckinID/checkin"
			$response = Invoke-WebRequest -Uri $ApiUrl -Method POST -Headers $headers | ConvertFrom-Json
		}
		Default { Throw "Invalid object type. Value must be 'asset' or 'accessory'. Value provided was $CheckinType." }
	}

	if ($response.status -eq "error") { Throw "Check in failed. Error: $($response.messages)" }
}

function New-SnipeCheckout {
	[CmdletBinding()]
	<#
		.SYNOPSIS
		Check out an asset or accessory.

		.DESCRIPTION
		Check out an asset or accessory.

		.PARAMETER CheckoutType
		[string] Optional. Defaults to 'asset'. Type of object (asset or accessory) to check out.

		.PARAMETER CheckoutID
		[int] Required. ID of the asset or accessory+user (not accessory ID) to check out.

		.PARAMETER CheckoutToType
		[string] Optional. Defaults to 'user'. Type of object (user, location, or asset) to check out the object to.

		.PARAMETER CheckoutToID
		[int] Required. ID to check out the object to.
	#>

	param (
		[Parameter(Mandatory=$false)]
		[string]$CheckoutType="asset",

        [Parameter(Mandatory=$true)]
        [int]$CheckoutID,

		[Parameter(Mandatory=$false)]
		[string]$CheckoutToType="user",

		[Parameter(Mandatory=$true)]
		[int]$CheckoutToID
	)

	if($script:ConnectionTested -eq $false) { Throw "Connection not established. Please run Initialize-SnipeConnection first." }

	# Check the CheckoutToType
	if ($CheckoutType -eq "asset" -and $CheckoutToType -notin @("user", "location", "asset")) { throw "Invalid type to check out to. Value must be 'user', 'location', or 'asset'." }
	if ($CheckoutType -eq "accessory" -and $CheckoutToType -notin @("user")) { throw "Invalid type to check out to. Accessories can only be checked out to 'user'. This is a Snipe-IT limitation." }

	# Set API headers
	$headers=@{}
	$headers.Add("accept", "application/json")
	$headers.Add("Authorization", "Bearer $script:ApiKey")
	$headers.Add("content-type", "application/json")

	switch ($CheckoutType) {
		"asset" { 
			$ApiUrl = "$script:SnipeURL/api/v1/hardware/$CheckoutID/checkout" 
			$response = Invoke-WebRequest -Uri $ApiUrl -Method POST -Headers $headers -ContentType 'application/json' -Body "{ `"checkout_to_type`":`"$CheckoutToType`", `"assigned_$CheckoutToType`":$CheckoutToID }" | ConvertFrom-Json
		}
		"accessory" { 
			$ApiUrl = "$script:SnipeURL/api/v1/accessories/$CheckoutID/checkout"
			$response = Invoke-WebRequest -Uri $ApiUrl -Method POST -Headers $headers -ContentType 'application/json' -Body "{ `"checkout_qty`":1,`"assigned_$CheckoutToType`":$CheckoutToID }" | ConvertFrom-Json
		}
		Default { Throw "Invalid object type. Value must be 'asset' or 'accessory'. Value provided was $CheckoutType." }
	}

	if ($response.status -eq "error") { Throw "Check out failed. Error: $($response.messages)" }
}

function New-SnipeTransfer {
	[CmdletBinding()]
	<#
		.SYNOPSIS
		Transfer an asset or accessory from one user, location, or asset to another.

		.DESCRIPTION
		Transfer an asset or accessory from one user, location, or asset to another.

		.PARAMETER ToType
		[string] Optional. Defaults to 'user'. Specifies what to transfer to (user, location, or asset). If transferring an accessory, must be a user.

		.PARAMETER ToID
		[int] Required. ID of the object to transfer to.

		.PARAMETER TransferType
		[string] Optional. Defaults to 'asset'. Specifies what to transfer (asset or accessory).

		.PARAMETER TransferID
		[int] Required. ID of the object to transfer. If transferring an accessory, this will be the accessory+user pivot id.

		.PARAMETER AccessoryID
		[int] Optional. Only used if transferring an accessory since checkin uses the accessory+user pivot id (TransferID) and the checkout uses the accessory ID.
	#>

	param (
		[Parameter(Mandatory=$false)]
        [string]$ToType='user',

        [Parameter(Mandatory=$true)]
        [int]$ToID,

		[Parameter(Mandatory=$false)]
        [string]$TransferType='asset',

        [Parameter(Mandatory=$true)]
        [int]$TransferID,

		[Parameter(Mandatory=$false)]
		[int]$AccessoryID
    )

	if($script:ConnectionTested -eq $false) { Throw "Connection not established. Please run Initialize-SnipeConnection first." }

	# Check in the object
	Write-Host "Checking in $TransferType $TransferID"
	New-SnipeCheckin -CheckinType $TransferType -CheckinID $TransferID

	# Check out the object
	switch ($TransferType) {
		"asset" { 
			Write-Host "Checking out $TransferType $TransferID to $ToType $ToID"
			New-SnipeCheckout -CheckoutType $TransferType -CheckoutID $TransferID -CheckoutToType $ToType -CheckoutToID $ToID 
		}
		"accessory" { 
			Write-Host "Checking out $TransferType $AccessoryID to $ToType $ToID"
			New-SnipeCheckout -CheckoutType $TransferType -CheckoutID $AccessoryID -CheckoutToType $ToType -CheckoutToID $ToID 
		}
		Default { Throw "Error checking out object. Invalid object type. Value must be 'asset' or 'accessory'. Value provided was $CheckoutType." }
	}	
}

function New-SnipeTransferAll {
	[CmdletBinding()]
	<#
		.SYNOPSIS
		Transfer all assets and accessories from one user to another.

		.DESCRIPTION
		Transfer all assets and accessories from one user to another. The API doesn't support pulling a list of everything checked out to an asset or location, but transferring everything from an asset or location could be added here if those functions are added to the API.

		.PARAMETER FromID
		[int] Required. ID of the object to transfer from.

		.PARAMETER ToID
		[int] Required. ID of the object to transfer to.
	#>

	param (
        [Parameter(Mandatory=$true)]
        [int]$FromID,

		[Parameter(Mandatory=$true)]
        [int]$ToID
    )

	if($script:ConnectionTested -eq $false) { Throw "Connection not established. Please run Initialize-SnipeConnection first." }

	#Forcing FromType and ToType If they add pulling all checked out assets/accessories to locations and assets, this will become a parameter.
	$FromType="user"
	$ToType = "user"

	# Set API headers
	$headers=@{}
	$headers.Add("accept", "application/json")
	$headers.Add("Authorization", "Bearer $script:ApiKey")

	$AssetsToTransfer=@()
	$AccessoryIDs=@()

	switch ($FromType) {
		"user" {
			Write-Host "Fetching assets and accessories assigned to $FromType $FromID"
			$ApiUrl = "$script:SnipeURL/api/v1/users/$FromID/assets"
			$AssetsToTransfer = (Invoke-WebRequest -Uri $ApiUrl -Method GET -Headers $headers  | ConvertFrom-Json).rows
			$ApiUrl = "$script:SnipeURL/api/v1/users/$FromID/accessories"
			$AccessoryIDs = (Invoke-WebRequest -Uri $ApiUrl -Method GET -Headers $headers  | ConvertFrom-Json).rows
			$AccessoryIDs = $AccessoryIDs | Sort-Object id | Select-Object -Unique id
		 }
		Default { Throw "Error starting transfer. Invalid object type. Value must be 'user', 'location', or 'asset'. Value provided was $CheckoutType." }
	}

	# Iterate through the Accessory IDs and find the accessory+user pivot IDs to be able to check them in.
	$AccessoriesToTransfer = @()
	$AccessoryIDs | foreach-object {
		$TempAssetID = $_.id
		# get a list of all checked out instances of this accessory
		$ApiUrl = "$script:SnipeURL/api/v1/accessories/$($_.id)/checkedout"
		$response = (Invoke-WebRequest -Uri $ApiUrl -Method GET -Headers $headers  | ConvertFrom-Json).rows
		# check each checked out instance to see if the user matches the FromID
		$response | foreach-object {
			if($($_.assigned_to.id) -eq $FromID) { 
				$row = [PSCustomObject]@{
					PivotID = $_.id
					AssetID = $TempAssetID
				}
				$AccessoriesToTransfer += $row 
			}
		}
	}

	# If the From object had any assets, transfer them.
	if ($AssetsToTransfer.Count -gt 0){
		$AssetsToTransfer | foreach-object { 
			Write-Host "Transferring asset $($_.id) from $FromType $FromID to $ToType $ToID"
			New-SnipeTransfer -ToID $ToID -TransferID $_.id 
		}
	} else { Write-Host "No assets assigned to $FromType $FromID" }

	# If the From object had any accessories, transfer them.
	if ($AccessoriesToTransfer.Count -gt 0){
		$AccessoriesToTransfer | foreach-object { 
			Write-Host "Tranferring accessory $_ from $FromType $FromID to $ToType $ToID"
			New-SnipeTransfer -TransferType 'accessory' -ToID $ToID -TransferID $_.PivotID -AccessoryID $_.AssetID
		}
	} else { Write-Host "No accessories assigned to $FromType $FromID" }
}
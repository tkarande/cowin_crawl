[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


function Get-Usage
{
	"========================================================================================================"
    "This utility only searches for jab availability, you need to reserve slot from cowin / aarogyasetu app "
    "Utility Notifies with BEEP until it finds selected criteria"
    "District option only works for Maharashtra, PIN option should work for India"
    "Utility shows availability for either 18 or 45 at a time"
	"Usage: PowerShell ./crawl_cowin.ps1 [18|45] [PIN NO.|district]"
	"EX1 : PowerShell ./crawl_cowin.ps1 45 district"
	"EX2 : PowerShell ./crawl_cowin.ps1 18 411027"
    "EX2 : PowerShell ./crawl_cowin.ps1 45 411045"
    "EX2 : PowerShell ./crawl_cowin.ps1 18 411017"
    "Note : use PIN If you are sure about health center available for respective PIN"
	"========================================================================================================="
    exit
}

$age_limit = $args[0]

$option = $null

#validation for district
if ($args[1] -eq "district")
{
	$option = "district"
}
#validation for PIN
elseif ($args[1].Length -eq 6 -and $args[1] -match '^\d+$' )
{
	
	$option = $args[1]
}
else
{
    Get-Usage
}

if  ( ($age_limit -eq 18 -or $age_limit -eq 45) -and ( -not [string]::IsNullOrEmpty($option)))
{
	if ($option -eq "district")
	{
		#URI to fetch MH dictricts and ids
		$uri1 = "https://cdn-api.co-vin.in/api/v2/admin/location/districts/21"
	
		$districts_obj = Invoke-RestMethod  -Method GET  -Uri $uri1 -ContentType "application/json"
		" "
		"======================"
		"District-->District_id"
		"======================"
		" "
		foreach ($district in $districts_obj.districts )
		{
			$district.district_name,$district.district_id -join "-->"
		}

		#prompt user to select district ID
		" "
		$district_id = Read-Host -Prompt "Select District ID:"
	}
	$attempt = 0;
    $week = 1
	while ($true)
	{
		$day=Get-Date -Format "dd-MM-yyyy"
        
        #calculate week and days 
        switch ( $week % 5)
        {
            0 {$week = 1}
            2 {$day = (Get-Date).AddDays(7).ToString("dd-MM-yyyy")}
            3 {$day = (Get-Date).AddDays(14).ToString("dd-MM-yyyy")}
            4 {$day = (Get-Date).AddDays(21).ToString("dd-MM-yyyy")}
            #default {$week = 1}
        }
        
        $week++

		if ($attempt -ne 0)
		{
			" "
			"sleeping for 5 seconds..."	
			Start-Sleep -s 5
		} 
		
		$attempt++
        
		"attempt [$attempt] : connecting with server to fetch details for $option from $day to next 6 days"
        "  "
		"I'll beep if I find details.."


		if ($option -eq "district")
		{
			$uri2 = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$district_id&date=$day"
		}
		else
		{
            $uri2 = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByPin?pincode=$option&date=$day"
		}

        #print in json file
		#$json_file = Invoke-RestMethod  -Method GET  -Uri $uri -ContentType "application/json"| ConvertTo-Json -Depth 5 
		$obj = Invoke-RestMethod  -Method GET  -Uri $uri2 -ContentType "application/json" 

		$counter =0
		foreach( $center in $obj.centers)
		{   
			foreach ($session in $center.sessions)
			{
			
                #sessions avaiable for age 18 or age 45
				if ($session.available_capacity -ne 0 -and $session.min_age_limit -eq  $age_limit )
				{
					$counter++
					[console]::beep(2000, 1000)
					" "
					"Center no: "+$counter
        			"============= "
         			"Center Name: "+$center.name
					"Center Type(free/Paid): "+$center.fee_type
					"Center Addr: " +$center.address
					"Center PIN: "+$center.pincode
					"No of jabs available: " +$session.available_capacity					 
		 			"Date: "+$session.date
					"Age Avaiability: "+$session.min_age_limit
					"Vaccine avaiable: "+$session.vaccine
				}
			
			}
	
		}

	}
}
else
{
    Get-Usage
}


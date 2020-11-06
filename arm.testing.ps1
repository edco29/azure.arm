<#
 .DESCRIPTION
    This scrip Test Azure ARM Template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group. 

 .PARAMETER resourceGroupLocation
    A resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing. This 
    location is only for the resource group, the parameters/template file have their own location setting. This is for Cloud Slice so that you can have
    your resources in a different location that the resource group

 .PARAMETER mainFileTemplate
    The Main Azure ARM Template

 .PARAMETER parametersFileName
    Optional, The Parameters file 

 .EXAMPLE 
    ./arm-test.ps1 abcdefgh-yyyy-xxxx-zzzz-123456789123 abcdefgh-1234-5678-1234-123456789123 linuxdemoargosv2 southcentralus linux.deploy.demo.json 
    ./arm-test.ps1 abcdefgh-yyyy-xxxx-zzzz-123456789123 abcdefgh-1234-5678-1234-123456789123 linuxdemoargosv2 southcentralus linux.deploy.demo.json linux.parameters.json
#>


param (
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $subscriptionId,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $tenantId,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupName,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $resourceGroupLocation,
    
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$mainFileTemplate ,
    
    [Parameter(Mandatory=$false)]
    [string] $parametersFileName

)

Write-Host "
________              _____ _____                         _______                                    _______ ________ ______  ___
___  __/_____ __________  /____(_)_______ _______ _       ___    |__________  _______________        ___    |___  __ \___   |/  /
__  /   _  _ \__  ___/_  __/__  / __  __ \__  __ `/       __  /| |___  /_  / / /__  ___/_  _ \       __  /| |__  /_/ /__  /|_/ / 
_  /    /  __/_(__  ) / /_  _  /  _  / / /_  /_/ /        _  ___ |__  /_/ /_/ / _  /    /  __/       _  ___ |_  _, _/ _  /  / /  
/_/     \___/ /____/  \__/  /_/   /_/ /_/ _\__, /         /_/  |_|_____/\__,_/  /_/     \___/        /_/  |_|/_/ |_|  /_/  /_/   
                                          /____/                                                                                
" -ForegroundColor Magenta

$ErrorActionPreference = "Stop"
$currentDirectory      =Get-Location ;
$messageGeneric        ="[DATG-AZURE.ARM]"
$messageTestTemplate   ="[DATG-AZURE.ARM-TEST.TEMPLATE]"
$messageWhatIf         ="[DATG-AZURE.ARM-TEST.WHATIF]"
$messageError          ="[DATG-AZURE.ARM-ERROR]"
$templatePath          ="$currentDirectory/azure-templates/$mainFileTemplate"
$templateParamsPath    ="$currentDirectory/azure-templates/$parametersFileName"
$errorFlag             =$false
$CurrentContext        =Get-AzContext

# Global Validation (avoid " ")
if ([string]::IsNullOrWhitespace($mainFileTemplate))      {Write-Error "$messageError  Don't allow WhiteSpace value for mainFileTemplate parameter" }
if ([string]::IsNullOrWhitespace($resourceGroupName))     {Write-Error "$messageError  Don't allow WhiteSpace value for WhiteSpace resourceGroupName parameter "}
if ([string]::IsNullOrWhitespace($subscriptionId))        {Write-Error "$messageError  Don't allow WhiteSpace value for WhiteSpace subscriptionId parameter" }
if ([string]::IsNullOrWhitespace($resourceGroupLocation)) {Write-Error "$messageError  Don't allow WhiteSpace value for WhiteSpace resourceGroupLocation parameter" }
if ([string]::IsNullOrWhitespace($tenantId))              {Write-Error "$messageError  Don't allow WhiteSpace value for WhiteSpace tenantId parameter" }

#set correct subscriptionID
if ($CurrentContext.Subscription.Id -ne $SubscriptionId) {
    $CurrentContext = Set-AzContext -Subscription $SubscriptionId -Tenant $TenantId
}
#check to see if the resource group exists
Write-Host "Checking Azure Resource Group $resourceGroupName." -ForegroundColor Yellow
$checkforResourceGroup = Get-AzResourceGroup  | Where-Object ResourceGroupName -Like $resourceGroupName
#Create or check for existing resource group
if(!$checkforResourceGroup){
    Write-Host "$messageGeneric Resource group '$resourceGroupName' does not exist." -ForegroundColor Red 
    Write-Host "$messageGeneric Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'" -ForegroundColor Red 
    New-AzResourceGroup  -Name $resourceGroupName -Location $resourceGroupLocation }
else{
    Write-Host "$messageGeneric Using existing resource group '$resourceGroupName.ResourceGroupName'" -ForegroundColor Yellow}


    
# Global Functions 
function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}


##
#VALIDATE TEMPLATE
##

Write-Host "`r`n$messageTestTemplate Determine whether an Azure resource group deployment template and its parameter values are valid." -ForegroundColor DarkCyan
$ErrorActionPreference = "Continue"

if (!([string]::IsNullOrEmpty($parametersFileName)) -or [string]::IsNullOrWhiteSpace(($parametersFileName))){
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment  -ResourceGroupName $resourceGroupName  -TemplateFile $templatePath -TemplateParameterFile $templateParamsPath )
    }
else { 
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment  -ResourceGroupName $resourceGroupName  -TemplateFile $templatePath )  
    }
                                         
if ($ErrorMessages) {
    Write-Error "$messageError Template is invalid , Validation returned the following errors:`r`n$ErrorMessages`r`n"
    $errorFlag=$true}
else {
    Write-Host "$messageTestTemplate Template is valid.`r`n" -ForegroundColor DarkCyan } 

##
#WHAT IF
##

Write-Host "$messageWhatIf Preview the changes that will happen(What-If)" -ForegroundColor Green
$ErrorActionPreference = "Continue"

try {
    if (!([string]::IsNullOrEmpty($parametersFileName)) -or [string]::IsNullOrWhiteSpace(($parametersFileName))) {
        New-AzResourceGroupDeployment -WhatIf  -ResourceGroupName $resourceGroupName -TemplateFile $templatePath -TemplateParameterFile $templateParamsPath -WhatIfResultFormat FullResourcePayloads -Mode Incremental -SkipTemplateParameterPrompt
    } else {New-AzResourceGroupDeployment -WhatIf -ResourceGroupName $resourceGroupName -TemplateFile $templatePath   }  
}
catch {
    $errorFlag=$true
    Write-Error "`r`n$messageError Evaluation returned the following errors: " 
    Write-Error $messageError $_. 
}

$ErrorActionPreference = "Stop"
if ($errorFlag) {
    Write-Error "TESTS FAILED"
}

Write-Host " ########################## TESTS PASSED ##########################" -ForegroundColor Magenta


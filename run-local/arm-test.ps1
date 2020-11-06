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
"



### Global Variables 
$ErrorActionPreference ='Stop'
$date                  =Get-Date -Format "yyyyMMddTHHmmssffff"
$currentDirectory      =Get-Location ;
$messageGeneric        ="[DATG-AZURE.ARM]"
$messageBestPr         ="[DATG-AZURE.ARM-BEST.PRACTICES]"
$messageWhatIf         ="[DATG-AZURE.ARM-WHAT.IF]"
$messageTestTemplate   ="[DATG-AZURE.ARM-TEST.TEMPLATE]"
$messageError          ="[DATG-AZURE.ARM-ERROR]"
$templatePath          ="$currentDirectory/$mainFileTemplate"
$templateParamsPath    ="$currentDirectory/$parametersFileName"
$errorFlag             =$false
$CurrentContext        =Get-AzContext

# Global Validation

if ([string]::IsNullOrWhitespace($mainFileTemplate))      {Write-Host "$messageError WhiteSpace ERROR for mainFileTemplate variable" ; exit 1}
if ([string]::IsNullOrWhitespace($resourceGroupName))     {Write-Host "$messageError WhiteSpace ERROR for resourceGroupName variable " ; exit 1}
if ([string]::IsNullOrWhitespace($subscriptionId))        {Write-Host "$messageError WhiteSpace ERROR for subscriptionId variable" ; exit 1}
if ([string]::IsNullOrWhitespace($resourceGroupLocation)) {Write-Host "$messageError WhiteSpace ERROR for resourceGroupLocation variable" ; exit 1}


#Loggin to Azure account,
if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) 
{  Connect-AzAccount -Tenant $tenantId -Subscription $SubscriptionId -UseDeviceAuthentication
    $CurrentContext = Get-AzContext}

if ($CurrentContext.Subscription.Id -ne $SubscriptionId) {
    $CurrentContext = Set-AzContext -Subscription $SubscriptionId -Tenant $TenantId
}

#Verify Current Subscription 
Write-Host "$messageGeneric Subscription details "
Get-AzSubscription -SubscriptionId $subscriptionId -TenantId $tenantId

#check to see if the resource group exists
$checkforResourceGroup = Get-AzResourceGroup  | Where-Object ResourceGroupName -Like $resourceGroupName
#Create or check for existing resource group
if(!$checkforResourceGroup){
    Write-Host "$messageGeneric Resource group '$resourceGroupName' does not exist.";
    Write-Host "$messageGeneric Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzResourceGroup  -Name $resourceGroupName -Location $resourceGroupLocation }
else{
    Write-Host "$messageGeneric Using existing resource group '$resourceGroupName.ResourceGroupName'";}


    
# Global Functions 
function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}


Write-Host "
+-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+   +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+
|V| |A| |L| |I| |D| |A| |T| |E|   |A| |Z| |U| |R| |E|     |A| |R| |M|   |B| |E| |S| |T|   |P| |R| |A| |C| |T| |I| |C| |E| |S|
+-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+   +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+
"
Write-Host "$messageGeneric Configuring ARM-TTK Module"
Write-Host "$messageGeneric Clonning ARM-TTK from Github"
git clone https://github.com/Azure/arm-ttk.git /tmp/azurettk$date
Write-Host "$messageGeneric Importing ARM-TTK Module"
Import-Module "/tmp/azurettk$date/arm-ttk/arm-ttk.psd1"

$TestResults = Test-AzTemplate -TemplatePath $templatePath 
$TestFailures =  $TestResults | Where-Object { -not $_.Passed }

if ($TestFailures) {
 Write-Host "$messageError One or more templates did not pass the selected tests , check $templatePath"
 $errorFlag=$true} 
else { Write-Output "$messageBestPr All files passed!" , "$TestResults"}

Write-Host "$messageBestPr Test details :"
Test-AzTemplate -TemplatePath $templatePath 

#Removing arm-ttk <Only Local Environment>
Remove-Module arm-ttk 
Remove-Item -Recurse -Force -Path "/tmp/azurettk$date/"


Write-Host "
+-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+
|V| |A| |L| |I| |D| |A| |T| |E|   |A| |Z| |U| |R| |E|     |A| |R| |M|   |T| |E| |M| |P| |L| |A| |T| |E|
+-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+     +-+s +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+
"

if (!([string]::IsNullOrEmpty($parametersFileName)) -or [string]::IsNullOrWhiteSpace(($parametersFileName))) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment  -ResourceGroupName $resourceGroupName `
                                                                              -TemplateFile $templatePath `
                                                                              -TemplateParameterFile $templateParamsPath ) }
else { $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment  -ResourceGroupName $resourceGroupName  -TemplateFile $templatePath )  }
                                         
if ($ErrorMessages) {
    Write-Host "$messageError Validation returned the following errors:"
    Write-Host  @($ErrorMessages)
    Write-Host "$messageError Template is invalid."
    $errorFlag=$true}
else {
    Write-Host "$messageTestTemplate Template is valid."}



Write-Host "
+-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+   +-+ +-+ +-+ +-+
|E| |V| |A| |L| |U| |A| |T| |E|   |A| |Z| |U| |R| |E|     |A| |R| |M|   |P| |L| |A| |N|
+-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+   +-+ +-+ +-+ +-+
"
try {
    if (!([string]::IsNullOrEmpty($parametersFileName)) -or [string]::IsNullOrWhiteSpace(($parametersFileName))) {
        New-AzResourceGroupDeployment -WhatIf  -ResourceGroupName $resourceGroupName -TemplateFile $templatePath -TemplateParameterFile $templateParamsPath }
    else {  New-AzResourceGroupDeployment -WhatIf -ResourceGroupName $resourceGroupName -TemplateFile $templatePath  }
    
}
catch {
    $errorFlag=$true
    Write-Host "$messageError Evaluation returned the following errors: " 
    Write-Host $_. 
}


if ($errorFlag) {
    Write-Host "
    +-+ +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+
    |T| |E| |S| |T|   |N| |O| |T|   |P| |A| |S| |S| |E| |D|   |E| |R| |R| |O| |R|   |!| |!| |!| |!|
    +-+ +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+  
    "
    exit 1
}

Write-Host "
+-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+
|A| |l| |l|   |T| |H| |E|   |T| |E| |S| |T| |S|   |P| |A| |S| |S| |E| |D|   |C| |O| |R| |R| |E| |C| |T| |L| |Y|     |G| |R| |E| |A| |T|   |J| |O| |B|   |!| |!| |!| |!|
+-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+     +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+
"

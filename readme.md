This article describe the default test that are run with the  `template test toolkit`.


## 1. Use correct schema
_Test name : DeploymentTemplate Schema Is Correct_
***
In your template , you must specify a valid schema value 
the following examples passes this test
```
{
   "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
   "contentVersion": "1.0.0.0",
   "parameters": {},
   "resources": []
}
```
The schema property in the azure arm template must be set to one of the following schemas 

```
* https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#
* https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#
* https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#
* https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#
* https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json
```

## 2. Parameters must be exist
_Test name : Parameters Property Must Exist_
***
Your template should have a parameters elements .Parameters are essential for making your template reusable in diff environment , add parameters to your template for values that change when deploying to diff environments.

the following examples passes this test 

```
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "vmName": {
          "type": "string",
          "defaultValue": "argos-machine",
          "metadata": {
            "description": "Name for the Virtual Machine."
          }
      }
  },
```

## 3. Declared parameters must be used
_Test name : Parameters Must Be Referenced_
***
To reduce confusion in your template , delete any parameters that are defined but not used.

## 4. Secure parameters can't have hardcoded default values 
_Test name : Secure String Parameters Cannot Have Default_
***
Don't provide a hard-coded default values for a secure parameter in your template . `an empty string is fine for the default value`. 
You use the types SecureString or SecureObject on parameters that contain sensitive values , like password/tokens . When parameter uses a secure type , the value of the parameter isn't logged or stored in the deployment history . This action prevents a malicious user from discovering the sensitive value.

**However , when you provide a default value , that value is discoverable by anyone who can access the template or the deployment history**

The following examples **fails** this test :

```
"parameters": {
    "adminPassword": {
        "defaultValue": "HardcodedPassword", // ERROR
        "type": "SecureString"
    }
}

```
The next example **passes** this test

```
"parameters": {
    "adminPassword": {
        "type": "SecureString"
    }
}
```

## 5. Environment URLs can't be hardcoded 
_Test name : DeploymentTemplate Must Not Contain Hardcoded Uri_
***
Don't hard-coded environment URLs in your template .Instead , [uses the environment function](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-functions-deployment#environment) to dynamically get these URLs during deployment. For a list of the URL hosts that are blocked ,[see the test case code](https://github.com/Azure/arm-ttk/blob/master/arm-ttk/testcases/deploymentTemplate/DeploymentTemplate-Must-Not-Contain-Hardcoded-Uri.test.ps1)

The following examples **fails** this test because the URL is hardcoded.
```
"variables":{
    "AzureURL":"https://management.azure.com"  // ERROR
}
```
The test also **fails** when used with **concat** or **uri** functions

```
"variables":{
    "AzureSchemaURL1": "[concat('https://','gallery.azure.com')]", //ERROR
    "AzureSchemaURL2": "[uri('gallery.azure.com','test')]" //ERROR
}
```
The following example **passes** this test

```
"variables": {
    "AzureSchemaURL": "[environment().gallery]"
},
```
## 6. Location uses parameter
_Test name : Location Should Not Be Hardcoded_
***
Users of your template may have limited regions available to them . When you set the resource location to **"[resourceGroup().location]"** , the resource group may have been created in a region that other users can't access .Those users are blocked from using the template.
When defining the location for each resource , use a parameter that defaults to the resource group location .By providing this parameter , users can use the default value when convenient but also specify a diff location

the following example **fails** this test because location on the resource is set to `resourceGroup().location`

```
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": "storageaccount1",
            "location": "[resourceGroup().location]", //ERROR
            "kind": "StorageV2",
            "sku": {
                "name": "Premium_LRS",
                "tier": "Premium"
            }
        }
    ]
}
```
The next example uses a location parameter but **fails** this test because the location parameter defaults to a hardcoded location.

```
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "string",
            "defaultValue": "westus"  //ERROR
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": "storageaccount1",
            "location": "[parameters('location')]",
            "kind": "StorageV2",
            "sku": {
                "name": "Premium_LRS",
                "tier": "Premium"
            }
        }
    ],
    "outputs": {}
}

```
Instead , create a parameter that defaults to the resource group location but allow users to provide a diff value .
The following example **passes** this test.

```
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
                "description": "Location for the resources."
            }
        }
     },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": "storageaccount1",
            "location": "[parameters('location')]",
            "kind": "StorageV2",
            "sku": {
                "name": "Premium_LRS",
                "tier": "Premium"
            }
        }
    ],
    "outputs": {}
}
```
## 7. Resource should have location
_Test name :  Resources Should Have Location_
***
The location for a resource be set to a template expression or global.
The template expression would typically use the location parameter described in the previous test.

The following example **fails** this test because isn't an **expression** or **global**

```
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "functions": [],
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": "storageaccount1",
            "location": "westus",     // ERROR
            "kind": "StorageV2",
            "sku": {
                "name": "Premium_LRS",
                "tier": "Premium"
            }
        }
    ],
    "outputs": {}
}
```
The following example **passes** this test

``` 
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "functions": [],
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Maps/accounts",
            "apiVersion": "2020-02-01-preview",
            "name": "demoMap",
            "location": "global",
            "sku": {
                "name": "S0"
            }
        }
    ],
    "outputs": {
    }
}

```
Also the next example **passes** the test

```
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
                "description": "Location for the resources."
            }
        }
     },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Storage/storageAccounts",
            "apiVersion": "2019-06-01",
            "name": "storageaccount1",
            "location": "[parameters('location')]",
            "kind": "StorageV2",
            "sku": {
                "name": "Premium_LRS",
                "tier": "Premium"
            }
        }
    ],
    "outputs": {}
}
```
## 8.Virtual Machine size uses parameter
_Test name : VM Size Should Be A Parameter_
***
Don't hard-coded the virtual machine size .Provide a parameter so users of your template can modify the size of the deployed virtual machine

The following examples **fails** the test

```
"hardwareProfile": {
    "vmSize": "Standard_D2_v3"
}
```
Instead , provide a parameter.

```
"vmSize": {
    "type": "string",
    "defaultValue": "Standard_A2_v2",
    "metadata": {
        "description": "Size for the Virtual Machine."
    }
},
```
Then , set the VM size to that parameter

``` 
"hardwareProfile": {
    "vmSize": "[parameters('vmSize')]"
},
```
## 9. Min & Max value are numbers
_Test name : Min And Max Value Are Numbers_
***
If you define min and max values for a parameters , specify them as number 
The following examples **fails** this test :
``` 
"exampleParameter": {
    "type": "int",
    "minValue": "0",
    "maxValue": "10"
},
```
Instead , provides the values as numbers.The following examples **passes** this test:

``` 
"exampleParameter": {
    "type": "int",
    "minValue": 0,
    "maxValue": 10
},
```
**You also get this warning if you provide a min or max value, but not the other.**

## 10.Declared variables must be used
_Test name : Variables Must Be Referenced_
***
To reduce confusion in your template , delete any variables that are defined but not used .

## 11.Dynamic variable should not use concat 
_Test name : Dynamic Variable References Should Not Use Concat_
***
Sometimes you need to dynamically construct a variable based on the value of another variable or parameter. Don't use the concat function when setting the value. Instead, use an object that includes the available options and dynamically get one of the properties from the object during deployment.

The following example passes this test. The currentImage variable is dynamically set during deployment.

``` 
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
      "osType": {
          "type": "string",
          "allowedValues": [
              "Windows",
              "Linux"
          ]
      }
  },
  "variables": {
    "imageOS": {
        "Windows": {
            "image": "Windows Image"
        },
        "Linux": {
            "image": "Linux Image"
        }
    },
    "currentImage": "[variables('imageOS')[parameters('osType')].image]"
  },
  "resources": [],
  "outputs": {
      "result": {
          "type": "string",
          "value": "[variables('currentImage')]"
      }
  }
}
```
## 12.Use recent API Version
_Test name : apiVersions Should Be Recent_
***
The API version for each resource should use a recent version . The test evaluates the version you use agains the versions available for the resource type.

## 13.Use Hardcoded API Version
_Test name : Providers apiVersions Is Not Permitted_
***
The API version for a resource type determines which properties are available. Provide a hard-coded API version in your template. Don't retrieve an API version that is determined during deployment. You won't know which properties are available.
The following example **fails** this test.

``` 
"resources": [
    {
        "type": "Microsoft.Compute/virtualMachines",
        "apiVersion": "[providers('Microsoft.Compute', 'virtualMachines').apiVersions[0]]", //ERROR
        ...
    }
]
```
The following example **passes** this test.

``` 
"resources": [
    {
       "type": "Microsoft.Compute/virtualMachines",
       "apiVersion": "2019-12-01",
       ...
    }
]
```

## 14.Properties can't be empty
_Test name : Template Should Not Contain Blanks_
***
Don't hardcode properties to an empty value. Empty values include null and empty strings, objects, or arrays. If you've set a property to an empty value, remove that property from your template. However, it's okay to set a property to an empty value during deployment, such as through a parameter.

## 15.Use Resource ID functions
_Test name :IDs Should Be Derived From ResourceIDs_
***
When specifying a resource ID, use one of the resource ID functions. The allowed functions are:
* resourceId
* subscriptionResourceId
* tenantResourceId
* extensionResourceId

Don't use the concat function to create a resource ID. The following example **fails** this test.

``` 
"networkSecurityGroup": {
    "id": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Network/networkSecurityGroups/', variables('networkSecurityGroupName'))]" //ERROR
}
```
The next example **passes** this test.
```
"networkSecurityGroup": {
    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('networkSecurityGroupName'))]"
}
```
## 16.Use Resource ID functions
_Test name :ResourceIds should not contain_
***
When generating resource IDs, don't use unnecessary functions for optional parameters. By default, the resourceId function uses the current subscription and resource group. You don't need to provide those values.

The following example **fails** this test, because you don't need to provide the current subscription ID and resource group name.

``` 
"networkSecurityGroup": {
    "id": "[resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', variables('networkSecurityGroupName'))]"
}
```
The next example passes this test.
```
"networkSecurityGroup": {
    "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('networkSecurityGroupName'))]"
}
```
This test applies to:
* resourceId
* subscriptionResourceId
* tenantResourceId
* extensionResourceId
* reference
* list*

**For reference and list*, the test fails when you use concat to construct the resource ID.**

## 17.DependsOn best practices
_Test name : DependsOn Best Practices_
***
When setting the deployment dependency , don't use the **if** function to test a condition .If one resource depends on a resource that is **conditionally deployed**,set the dependency as you would with any resource . When a conditional resource isn't deployed , Azure Resource Manager automatically removes it from the required dependencies.

The following example **fails** this test.
``` 
"dependsOn": [
    "[if(equals(parameters('newOrExisting'),'new'), variables('storageAccountName'), '')]"
]
```
The next example **passes** this test.
```
"dependsOn": [
    "[variables('storageAccountName')]"
]
```
## 18.Nested or linked deployments can't use debug
_Test name : Deployment Resources Must Not Be Debug_
***
When you define a nested or linked template with the Microsoft.Resources/deployments resource type, you can enable debugging for that template. Debugging is fine when you need to test that template but should be turned when you're ready to use the template in production.

## 19.Admin user names can't be literal value
_Test name : adminUsername Should Not Be A Literal_
***
When setting an admin user name, don't use a literal value.
The following example **fails** this test:
``` 
"osProfile":  {
    "adminUserName":  "myAdmin" //ERROR
},
```
Instead, use a parameter. The following example **passes** this test:
``` 
"osProfile": {
    "adminUsername": "[parameters('adminUsername')]"
}
``` 
## 20.Use stable VM images
_Test name : Virtual Machines Should Not Be Preview_
***
Virtual machines shouldn't use preview images.
The following example **fails** this test:
``` 
"imageReference": {
    "publisher": "Canonical",
    "offer": "UbuntuServer",
    "sku": "16.04-LTS",
    "version": "latest-preview"  //ERROR
}
```
The following example **passes** this test.
``` 
"imageReference": {
    "publisher": "Canonical",
    "offer": "UbuntuServer",
    "sku": "16.04-LTS",
    "version": "latest"
},
```
## 21.Use latest VM image
_Test name : VM Images Should Use Latest Version_
***
If your template includes a virtual machine with an image, make sure it's using the latest version of the image.

## 22.Outputs can't include secrets
_Test name : Outputs Must Not Contain Secrets_
***
Don't include any values in the outputs section that potentially expose secrets. The output from a template is stored in the deployment history, so a malicious user could find that information.

The following example **fails** the test because it includes a secure parameter in an output value.
``` 
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "secureParam": {
            "type": "securestring"
        }
    },
    "functions": [],
    "variables": {},
    "resources": [],
    "outputs": {
        "badResult": {
            "type": "string",
            "value": "[concat('this is the value ', parameters('secureParam'))]"  //ERROR
        }
    }
}
```
The following example **fails**  because it uses a list* function in the outputs.

``` 
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "storageName": {
            "type": "string"
        }
    },
    "functions": [],
    "variables": {},
    "resources": [],
    "outputs": {
        "badResult": {
            "type": "object",
            "value": "[listKeys(resourceId('Microsoft.Storage/storageAccounts', parameters('storageName')), '2019-06-01')]" //ERROR
        }
    }
}
```

## 23.Don't use ManagedIdentity extension
_Test name :  ManagedIdentityExtension must not be used_
***

Don't apply the ManagedIdentity extension to a virtual machine. For more information, see [How to stop using the virtual machine managed identities extension and start using the Azure Instance Metadata Service.](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/howto-migrate-vm-extension)

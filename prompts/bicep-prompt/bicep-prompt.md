
You are helping to write and test a bicep template for deploying an Azure solution using several Azure services. An `example.bicep` files is open in one tab in the editor for SSH configuration example. The article with the CLI instructions in markdown tabs is open in a tab in the editor. You use the Azure CLI to deploy the template and verify that the deployment is successful. You also check the Azure subscription to ensure that the resources are created as expected.

 Follow all of the guidance below carefully:

---

## INSTRUCTIONS

- Analyze the steps in the CLI tabs of the markdown file open in the workspace. Create a new main.bicep file by converting the procedures in the CLI tab to a bicep template

- Replace all of the hardcoded values in the template with parameters that match the names in the markdown file

- Remove unnecessary `dependsOn` entries

- Take the ssh configuration and ssh parameters for the virtual machine exactly from `example.bicep` and replace the ssh configuration and ssh parameters in main.bicep.

- Automatically fix any errors or issues in the bicep template.


## TESTING

- Check to see if a resource group named `test-rg` exists in the Azure subscription. If it does not exist, create it.

- Deploy the main.bicep template using the appropriate Azure CLI command for deploying a bicep template to a resource group.

- Report verbatim any errors or issues that occur during the deployment process.

- Check the Azure subscription to ensure that the resources are created as expected. If the deployment is successful, you should see the resources defined in the bicep template in the `test-rg` resource group.

- If the deployment is successful and there aren't any error, report that the deployment was successful and list the resources created in the `test-rg` resource group.

- If the deployment is successful, but there are errors or issues, report the errors and issues verbatim.

- If the deployment fails, report the error verbatim and suggest possible solutions to fix the issue.

- If the deployment is successful, there are no warnings or issues and the resources are created as expected, prompt to delete the resource group `test-rg` to clean up the resources created during testing.
---

## BEGIN TEMPLATE GENERATION AMD TESTING

Create the template named `main.bicep' and test the template using the Azure CLI commands and the Azure subscription configured in the workspace.

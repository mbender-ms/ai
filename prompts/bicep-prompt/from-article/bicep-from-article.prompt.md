
---
mode: 'agent'
description: Generate and test a Bicep template by converting Azure portal, PowerShell or Azure CLI procedures from a Microsoft Learn article to Infrastructure as Code, including parameter extraction, template deployment, and resource verification.
tools:
  - azure_development-get_code_gen_best_practices
  - azure_development-get_deployment_best_practices
  - azure_bicep_schemas-get_bicep_resource_schema
  - azure_resources-query_azure_resource_graph
  - azure_cli-generate_azure_cli_command
  - run_in_terminal
  - create_file
  - read_file
  - get_errors
variables:
  - name: article_name
    description: The name of the Microsoft Learn article to analyze for portal, Powershell, or Azure CLI procedures
    type: string
---

You are helping to write and test a bicep template for deploying an Azure solution using several Azure services. An `example.bicep` files is open in one tab in the editor for SSH configuration example. You will analyze the article with the Azure portal, Powershell, or Azure CLI instructions from the MS Learn website https://learn.microsoft.com/en-us/azure/?product=popular and is named **${input:article_name}**. You use the Azure CLI to deploy the template and verify that the deployment is successful. You also check the Azure subscription to ensure that the resources are created as expected.

Follow all of the guidance below carefully:

---

## ARTICLE ANALYSIS

- Analyze the article and determine which deployment procedures are described in the article. Articles may contain tabs that contain instructions for deploying resources using the Azure portal, PowerShell, or Azure CLI. Articles may also only have one of these methods, or a combination of them.

- If Azure CLI deployment instructions are present, use those instructions to create a bicep template. 

- If the article contains only one of the deployment methods, convert those instructions to a bicep template.

## INSTRUCTIONS

- DO NOT USE THE AZURE DEVELOPER CLI FOR THIS TASK. You are using the Azure CLI to deploy the bicep template.

- Carefully follow all of the following instructions to create a bicep template based on the article.

- Don't create a `main.parameters.json` file or a `README.md`file.

- You aren't using the Azure developer CLI, don't create a `azure.yaml` file or deployment scripts.

- Analyze the steps in the article named **${input:article_name}** from the MS Learn website. Create a new main.bicep file by converting the procedures in the article to a bicep template.

- Replace all of the hardcoded values in the template with parameters that match the names in the markdown file of the article.

- Remove unnecessary `dependsOn` entries.

- Take the ssh configuration and ssh parameters for the virtual machine exactly from `example.bicep` and replace the ssh configuration and ssh parameters in main.bicep. 

- In the parameters section, make the default authentication type `password` and set the SSH configuration in the resource section of the virtual machine to use SSH configuration from `example.bicep`.

- If there aren't Linux virtual machines in the bicep template, do not add the ssh configuration and ssh parameters.

- If there are Linux virtual machines in the bicep template, you must use SSH for the configuration. Do not use password authentication for the virtual machine if it's Linux.

- Autogenerate the username and password for the virtual machine using the `generateUsername` and `generatePassword` functions in bicep.

- Use the `--parameters` option in the Azure CLI command to pass the parameters to the bicep template.

- Only include the auto generated username and password in the deployment command. Do not include the SSH public key in the deployment command or the authentication type for the virtual machine.

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

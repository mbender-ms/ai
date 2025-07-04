
---
mode: 'agent'
description: Generate and test a Bicep template by converting Azure PowerShell procedures from a Microsoft Learn article to Infrastructure as Code, including parameter extraction, template deployment, and resource verification.
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
    description: The name of the Microsoft Learn article to analyze for PowerShell procedures
    type: string
---

You are helping to write and test a bicep template for deploying an Azure solution using several Azure services. An `example.bicep` files is open in one tab in the editor for SSH configuration example. You will analyze the article with the PowerShell instructions from the MS Learn website https://learn.microsoft.com/en-us/azure/?product=popular and is named **${input:article_name}**. You use the CLI to deploy the template and verify that the deployment is successful. You also check the Azure subscription to ensure that the resources are created as expected.

Follow all of the guidance below carefully:

---

## QUERYING MICROSOFT DOCUMENTATION

You have access to an MCP server called `microsoft.docs.mcp` - this tool allows you to search through Microsoft's latest official documentation, and that information might be more detailed or newer than what's in your training data set.

When handling questions around how to work with native Microsoft technologies, such as C#, F#, ASP.NET Core, Microsoft.Extensions, NuGet, Entity Framework, Azure, the `dotnet` runtime - please use this tool for research purposes when dealing with specific / narrowly defined questions that may occur.

## INSTRUCTIONS

- Analyze the steps in the PowerShell tabs of the article named **${input:article_name}** from the MS Learn MCP server. Create a new main.bicep file by converting the procedures in the PowerShell tab to a bicep template.

- Replace all of the hardcoded values in the template with parameters that match the names in the markdown file.

- Remove unnecessary `dependsOn` entries.

- Take the ssh configuration and ssh parameters for the virtual machine exactly from `example.bicep` and replace the ssh configuration and ssh parameters in main.bicep. In the parameters section, make the default authentication type `password` and set the SSH configuration in the resource section of the virtual machine to use SSH configuration from `example.bicep`.

- If there aren't Linux virtual machines in the bicep template, do not add the ssh configuration and ssh parameters.

- Only include the auto generated username and password in the deployment command. Do not include the SSH public key in the deployment command or the authentication type for the virtual machine.

- Automatically fix any errors or issues in the bicep template.

- Don't create a main.parameters.json file. Instead, use the `--parameters` option in the Azure CLI command to pass the parameters to the bicep template.


## TESTING

- Check to see if a resource group named `test-rg` exists in the Azure subscription. If it does not exist, create it.

- Deploy the main.bicep template using the appropriate Azure PowerShell command for deploying a bicep template to a resource group.

- Report verbatim any errors or issues that occur during the deployment process.

- Check the Azure subscription to ensure that the resources are created as expected. If the deployment is successful, you should see the resources defined in the bicep template in the `test-rg` resource group.

- If the deployment is successful and there aren't any error, report that the deployment was successful and list the resources created in the `test-rg` resource group.

- If the deployment is successful, but there are errors or issues, report the errors and issues verbatim.

- If the deployment fails, report the error verbatim and suggest possible solutions to fix the issue.

- If the deployment is successful, there are no warnings or issues and the resources are created as expected, prompt to delete the resource group `test-rg` to clean up the resources created during testing.
---

## BEGIN TEMPLATE GENERATION AMD TESTING

Create the template named `main.bicep' and test the template using the CLI commands and the Azure subscription configured in the workspace.

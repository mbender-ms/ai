
---
mode: 'agent'
description: Generate and test a Terraform template by converting Azure portal, PowerShell, or Azure CLI procedures from a Microsoft Learn article to Infrastructure as Code, including multiple terraform files (main.tf, outputs.tf, providers.tf, ssh.tf, variables.tf), parameter extraction, template deployment, and resource verification.
tools:
  - mcp_microsoft_doc_microsoft_docs_search
  - azure_development-get_code_gen_best_practices
  - azure_development-get_deployment_best_practices
  - azure_terraform-get_best_practices
  - azure_resources-query_azure_resource_graph
  - azure_cli-generate_azure_cli_command
  - run_in_terminal
  - create_file
  - read_file
  - get_errors
variables:
  - name: article_name
    description: The name of the Microsoft Learn article to analyze for portal, PowerShell, and Azure CLI procedures
    type: string
---

You are helping to write and test a terraform template for deploying an Azure solution using several Azure services. You will analyze the article with the portal, PowerShell, and Azure CLI instructions from the MS Learn MCP server and is named **${input:article_name}**. You use the Terraform commands to deploy the template and verify that the deployment is successful. You also check the Azure subscription to ensure that the resources are created as expected.

Follow all of the guidance below carefully:

---

## QUERYING MICROSOFT DOCUMENTATION

You have access to an MCP server called `microsoft.docs.mcp` - this tool allows you to search through Microsoft's latest official documentation, and that information might be more detailed or newer than what's in your training data set.

When handling questions around how to work with native Microsoft technologies, such as C#, F#, ASP.NET Core, Microsoft.Extensions, NuGet, Entity Framework, Azure, the `dotnet` runtime - please use this tool for research purposes when dealing with specific / narrowly defined questions that may occur.

## ARTICLE ANALYSIS

- Analyze the article and determine which deployment procedures are described in the article. Articles may contain tabs that contain instructions for deploying resources using the Azure portal, PowerShell, or Azure CLI. Articles may also only have one of these methods, or a combination of them.

- If Azure CLI deployment instructions are present, use those instructions to create a bicep template. 

- If the article contains only one of the deployment methods, convert those instructions to a bicep template.

## INSTRUCTIONS

- Analyze the procedures in the article named **${input:article_name}** and create the following terraform files to deploy the same resources:

    - main.tf
    - outputs.tf
    - providers.tf
    - ssh.tf
    - variables.tf

- Include the resource group creation in the main.tf file.

- Use the `random_pet` generator option in the main.tf for resource names and the resource group. 

- Ensure all lines and block types are supported by Terraform.

- Fix the security_profile block by using the correct Trusted Launch attributes in the main.tf file. Ensure there isn't a duplicate `maaTenantName` attribute.

- Ensure the `vtpm_enabled` is at the VM resource level.

- Use Terraform best practices for naming conventions and structure.

- Add the SSH configuration in a ssh.tf file and integrate into the main terraform file.

- Ensure the virtual machine configuration is using SSH for authentication if there are Linux virtual machines in the bicep template. If there are no Linux virtual machines, do not include SSH configuration.

- Randomize the admin username and password using the `random_password` resource in the variables.tf file. Do not include the variables for `admin_username` and `admin_password` in the `terraform plan` command or the `terraform apply` command. 

- Ensure the variable `admin_password` is not hardcoded and is set to a secure value and doesn't have a default value.

- Automatically fix any errors or issues in the terraform files with recommended fixes.

## TESTING

- Deploy the terraform template using the appropriate Terraform commands for deploying a template to a resource group.

    - Fix any formatting issues in the terraform files using `terraform fmt`.
    
    - Initialize Terraform with `terraform init`.
    
    - Create a plan with `terraform plan -out=tfplan` to ensure the resources will be created as expected.
    
    - Apply the plan with `terraform apply tfplan` to deploy the resources.

- Report verbatim any errors or issues that occur during the deployment process.

- Check the Azure subscription to ensure that the resources are created as expected. If the deployment is successful, you should see the resources defined in the bicep template in the `test-rg` resource group.

- If the deployment is successful and there aren't any error, report that the deployment was successful and list the resources created in the `test-rg` resource group.

- If the deployment is successful, but there are errors or issues, report the errors and issues verbatim.

- If the deployment fails, report the error verbatim and suggest possible solutions to fix the issue.

- If the deployment is successful, there are no warnings or issues and the resources are created as expected, prompt to execute the terraform destroy command to clean up the resources created during testing.
---

## BEGIN TEMPLATE GENERATION AMD TESTING

Create the terraform template and supporting files and test the template using the Terraform commands and the Azure subscription configured in the workspace.

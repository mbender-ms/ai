# General MCP Tasks and tips

## MCP Server 

1. Finding an MCP server
    1. https://www.pulsemcp.com/servers/tavily-search
1. [Anthropic Fetch Server](https://github.com/modelcontextprotocol/servers/tree/HEAD/src/fetch) - Official server for retrieving and converting web content to markdown for analysis (278k weekly downloads)
1. [Tavily MCP Server](https://docs.tavily.com/documentation/mcp) - A purpose-built server for the Model Context Protocol (MCP) that provides access to a wide range of web content and data sources designed to enhance the capabilities of AI models.

## Adding an MCP server to your environment

    1. Add remote Tavily MCP server to your environment
    1. Ctrl + Shift + P
    1. Search for "MCP: Add Server" > Choose HTTP Server
    1. Enter the URL of the MCP server you want to add 
        1. https://mcp.tavily.com/mcp/?tavilyApiKey=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
    1. Enter a name for the server (e.g., "Tavily MCP Server")
    1. Choose Workspace or Global.
    1. Server will be added to MCP.json file in your workspace or global settings.
    1. View in Extensions > MCP Servers

## Adding Learn MCP Server

[Install MCP Server from GitHub](https://github.com/MicrosoftDocs/mcp?tab=readme-ov-file#-installation--getting-started)

## Demo - Analysis of articles

**Scenario:**

```vscode
Ask Copilot to list the number of articles in a service's folder, How many articles are older than 365 days, and how many article are missing customer intent statements in metadata.
```

**Prompt:**

```vscode
# Analyze Load Balancer Articles

- How many markdown articles are in the load-balancer folder?
- How many have ms.dates older than 07/08/2024?
- How many are missing # customer intent:" statements?
- How many articles use bicep, terraform or ARM temaplates?
- When completed, create a new document called lb-article-analysis.md in the current folder using results.
```

## Demo - create an FAQ article for Load Balancer

**Prompt:**

```vscode
#Create an FAQ

Utilizing Microsoft Learn documentation, techcommunity.microsoft.com, and all public Microsoft documentation, create an FAQ for Troubleshooting Azure Load Balancer.
Create lb-FAQ.yml in the current folder.
Follow microsoft style guide and best practices for FAQ documentation.
Optimize the FAQ for Generative Engine Optimization.
```

**Prompt2:**

```vscode
Fact check lb-FAQ.yml results against our current documentation set. Identify any items that don't align in the new FAQ.
```

## Demo - Gap Analysis

**Prompt:**
```vscode
# Gap Analysis for Azure Virtual Network Manager Documentation

Based on a review of customer-facing Microsoft official documentation and blogs on techcommunity.microsoft.com, analyze the virtual network manager doc set for scenarios and article gaps missing in our public documentation.

Create a new file including all the Article gaps, a high-level summary of what a new doc would include. Create article in current folder with name avnm-gap-analysis.md

include all links and references to fact-check recommendations.
```


## Q & A
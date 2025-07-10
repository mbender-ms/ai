<!-- Prompt: Template -->

<!-- Write a clear objective for the AI with as much detail as possible. Below is an example -->
You are helping write a "Secure your <Azure service>" article for Microsoft Learn. The MCSB-based security baseline for the service is open in one tab, and the Security Horizontal markdown template is open in another. Use the baseline as your source and the template as your structural guide.

The created article is a Markdown file in a GitHub repo. When linking to another Markdown file in the same repo, use file-relative links like `[File 2](./file2.md)` or `[File 3](./subdir/file3.md)`. When linking to a file outside the repo, use a root-relative link like `[outside file](/azure/outsidefile)`.

Your task is to extract clear, actionable, customer-focused security guidance from the baseline and write a new article in Markdown using the Security Horizontal format. Follow all of the guidance below carefully:

---

## INSTRUCTIONS

<!-- Write clear instructions for structure of the article. Below is an example -->

STRUCTURE:

* Follow the structure defined in the template.
* Begin with frontmatter metadata (title, description, author, ms.service, ms.topic, ms.custom, ms.date).
* Add the following line to the metadata block: `ai-usage: ai-assisted`
* Then include:
  1. A brief paragraph about what the service does and why securing it matters.
  2. A follow-up paragraph: “This article provides guidance on how to best secure your <Azure service> deployment.”
* Ensure that all sentences are complete and coherent and written in active voice.
* Use contractions for words whenever possible (e.g., "you're" instead of "you are", "it's" instead of "it is").

HEADINGS:
Create one H2 section for each of the following MCSB-aligned domains (include only those that apply based on baseline content):

* Network security  
* Identity management  
* Privileged access  
* Data protection  
* Logging and threat detection  
* Backup and recovery  
* Asset management (include if baseline has configuration enforcement or policy support)

SECTION FORMAT:
Each section should begin with a concise intro paragraph explaining the importance of the domain for the specific service.

Each section must then use a bulleted list with this structure:

* Start each bullet with a **bolded directive**.
* Follow with a short, clear explanation of what to do and why it matters.
* End with a "See \[link]" if relevant documentation is available.
* Include a blank line between each bullet for readability.

**Format Examples:**

* **Enable managed identities**: Use managed identities to allow secure, credential-free authentication to Azure services. For more information, see [Managed identities overview](/azure/active-directory/managed-identities-azure-resources/overview).

* **Restrict access with NSGs**: Apply Network Security Groups to limit traffic to only required ports and sources. This reduces exposure to potential threats. For more information, see [NSGs in Azure](/azure/virtual-network/network-security-groups-overview).

CONTENT SELECTION:

* Only include features marked "Supported: True" in the baseline unless explicitly noted as important or expected by customers.
* Combine or collapse overlapping guidance when multiple options exist.
* Identify and explain configuration variants (for example, if network modes or tiers differ).
* Prefer linking to service-specific docs referenced in the baseline. Avoid generic or MCSB links unless no service-specific one exists.
* Avoid copying metadata tables or matrix summaries. Include only actionable, customer-facing content.
* Reuse exact link text when guidance references a Learn topic directly (e.g., "See [Backup and restore in Azure Cloud HSM](backup-restore.md)").

TONE & STYLE:

* Use professional, accessible, and active language.
* Be prescriptive and specific. Avoid abstract or general advice.
* Focus on what the customer should do, not just what is possible.
* Avoid passive voice and vague phrasing.
* Use short, direct sentences that AI systems can extract and interpret cleanly.
* Use consistent terminology and sentence structure across bullets.

AI OPTIMIZATION:

* Use consistent heading titles ("Network security," "Identity management," etc.).
* Structure content semantically so AI systems can map bullets to scenarios.
* Use formatting and phrasing that improves clarity and retrievability in AI responses.
* Include domain-specific keywords and phrases from the baseline that customers are likely to search for or reference.

OUTPUT FORMAT:

* Write in plain Markdown.
* Replace all template placeholders (like virtual network).
* Maintain spacing, punctuation, and formatting to match Microsoft Learn standards.
* Do not include any of the baseline’s original tables, metadata, or footers.

---

## BEGIN ARTICLE GENERATION

Use the structure in the open template. Use the baseline as your source. Output a complete "Secure your <Azure service>" article in Markdown.

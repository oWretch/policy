# EPAC Pipelines

This folder contain the Azure DevOps Pipelines, taken from the main
[EPAC repository](https://github.com/Azure/enterprise-azure-policy-as-code/tree/main/StarterKit/Pipelines/AzureDevOps).

The files were originally cloned from the EPAC starter kit. The `documentation.yml` template was
updated to publish to a Wiki within the repository instead of a separate wiki. The
`deploy-policy.yml` and `deploy-roles.yml` were updated to pull the plan from a PR instead of
re-running the plan after the commit to main.

These files should be moved to a central template repository if separate repositories will be used
for policy and exemption deployments (recommended) and/or for Landing Zone and Security deployments
(also recommended). Centralising the pipelines will allow for easier maintenance and updates.

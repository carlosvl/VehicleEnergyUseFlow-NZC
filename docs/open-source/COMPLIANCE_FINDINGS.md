# OSPO and Quality Findings

Generated 2026-08-31 while applying OSPO compliance, repository shape, and Salesforce quality rules.

## Remediated

| Item | Action |
| ---- | ---- |
| Employee email in Network `emailSenderAddress` | Replaced with `noreply@example.com` |
| Experience Home referenced `NZC_Create_EUR_for_Stationary` (not in repo) | Pointed at `Vehicle_Asset_Energy_Use` |
| EUR-lwc referenced `c:billIngestorGuest` (companion accelerator) | Replaced with in-repo vehicle flow |
| Missing Apache 2.0 governance set | Added `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `CODEOWNERS` (`LICENSE.txt` already present) |
| `package.json` had no SPDX license | Set `"license": "Apache-2.0"` |
| `sourceApiVersion` was `55.0` (Spring '22) | Bumped to `64.0` |
| Flow `apiVersion` was `56.0` (SFCA High: AvoidOldSalesforceApiVersions) | Bumped to `64.0` |
| Flow had no description | Added `<description>` on `Vehicle_Asset_Energy_Use` |
| No LLM inventory / wiki | Added `REPOSITORY_SUMMARY.md` and `wiki/index.md` |

## Remaining (non-blocking unless noted)

| Item | Severity | Notes |
| ---- | ---- | ---- |
| Network member profile `nzc partner user` | Medium | Org-specific. Create it or remap membership after deploy |
| CustomSite `EUR_collection` not in source | Medium | Network references it. Enable Digital Experiences and publish/create the site if deploy fails |
| No Apex/LWC copyright headers | Info | No Apex, LWC, CSS, or Aura source exists to stamp |
| Salesforce Code Analyzer | Partial | Ran `sf code-analyzer run --workspace force-app`. Regex High on old Flow API **fixed**. Flow engine did not start (Python 3.10+ missing). Re-run locally with Python so the Flow Scanner can evaluate `Vehicle_Asset_Energy_Use` |
| GitHub Discussions disabled | Info | Issues tab is enabled. Enable Discussions if you want that support channel |
| GitHub license detection showed `Other` | Info | Full ALv2 is in `LICENSE.txt`; confirm GitHub detects Apache-2.0 after this commit |
| `deploy-mdapi` branch stale after these edits | Medium | Rebuild and push `deploy-mdapi` plus refresh the GitHub Release zip |
| Scratch orgs cannot host Net Zero Cloud | Info | Documented; `Communities` added to scratch def for Experience experiments only |

## Not found

- Internal hosts (`*.sfdc.sh`, `git.soma.salesforce.com`)
- Internal CI names (GUS, Grand Slam, Jenkins) in published source
- Hardcoded credentials, tokens, or API keys
- SOQL injection or DML-in-loop (no Apex)
- Private npm packages

## Approvals

Have you obtained **VP Approval**, **Legal Approval**, and **OSPO Approval** via the OSS Request Portal (https://oss-request2.sfdc.sh/) before treating this as a Salesforce-published open-source accelerator?

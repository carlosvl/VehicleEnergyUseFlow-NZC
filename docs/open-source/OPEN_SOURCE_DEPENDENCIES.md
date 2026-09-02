# Open Source Dependencies

Inventory of runtime and development dependencies for Vehicle Asset Energy Use (NZC).

This accelerator is Salesforce metadata. Deployed runtime includes **Apex** and **Lightning web components** in this repository plus platform and Net Zero Cloud. npm packages below are **dev-only** (lint/format/Jest scaffolding).

## Runtime (Salesforce)

| Name | Type | License / source | Required | Notes |
| ---- | ---- | ---- | ---- | ---- |
| Salesforce Platform | PaaS | Salesforce subscription | Yes | Flows, Experience Cloud, Metadata API, Apex |
| Net Zero Cloud (`sustainability`) | Managed package | Salesforce product license | Yes | Provides `VehicleAssetEmssnSrc`, `VehicleAssetEnrgyUse`, `StnryAssetEnvrSrc`, `StnryAssetEnrgyUse`, Other Emissions Factor Set |
| Experience Cloud / Digital Experiences | Platform feature | Salesforce subscription | For site only | LWR `talon-template-byo`, `dxp_flow:flow`; guest capture also needs site Preferences **Allow guest users to access public APIs** (not in metadata) |
| Collect Energy Use Data | Managed flow | Net Zero Cloud | No | Stationary counterpart; not in this repo |

## Development (npm)

From `package.json` `devDependencies`. None are deployed to the org.

| Package | Role | Typical license |
| ---- | ---- | ---- |
| `eslint` | Lint | MIT |
| `@lwc/eslint-plugin-lwc` | LWC lint | MIT |
| `@salesforce/eslint-config-lwc` | LWC lint config | BSD-3-Clause |
| `@salesforce/eslint-plugin-aura` | Aura lint | BSD-3-Clause |
| `@salesforce/eslint-plugin-lightning` | Lightning lint | BSD-3-Clause |
| `@salesforce/sfdx-lwc-jest` | LWC unit tests | MIT |
| `prettier` | Format | MIT |
| `prettier-plugin-apex` | Apex format | MIT |
| `@prettier/plugin-xml` | XML format | MIT |
| `husky` | Git hooks | MIT |
| `lint-staged` | Pre-commit | MIT |
| `eslint-plugin-import` | Lint | MIT |
| `eslint-plugin-jest` | Lint | MIT |

Confirm current SPDX on npm at publish time. Prefer Apache 2.0, BSD-3, MIT, ISC, or MPL for any new dependency.

## Explicitly not included

- `c:billIngestorGuest` (NZC LLM Bill Ingestor) — optional companion; site pages do not reference it
- `NZC_Create_EUR_for_Stationary` — not in this package
- Private npm registries or Salesforce internal artifacts — none referenced

Machine-readable copy: [dependency-inventory.json](dependency-inventory.json).

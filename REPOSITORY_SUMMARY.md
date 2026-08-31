# Vehicle Asset Energy Use (NZC) — Repository Summary

LLM-oriented inventory of this Salesforce DX accelerator. For how the solution works and the main caveats, read `wiki/index.md` first.

## Overview

**Vehicle Asset Energy Use (NZC)** captures vehicle fuel and energy use in Salesforce Net Zero Cloud. It ships:

- A screen flow that creates `VehicleAssetEnrgyUse` records against a `VehicleAssetEmssnSrc` parent
- An Experience Cloud LWR site (**EUR collection**) for external Energy Use Record collection
- Network and branding metadata for that site

It is the vehicle counterpart to Net Zero Cloud’s managed **Collect Energy Use Data** flow (`sustainability__CollectEnergyUseData`), which is not retrievable as source.

| Item | Value |
| ---- | ---- |
| GitHub | `https://github.com/carlosvl/VehicleEnergyUseFlow-NZC` |
| Default branch | `master` |
| One-click deploy ref | `deploy-mdapi` |
| License | Apache License 2.0 |
| SFDX project name | `VehicleEnergyUseFlow-NZC` |
| `sourceApiVersion` | `64.0` |
| Flow API version | `64.0` |
| Namespace | none |

## Technology Stack

- Salesforce Platform (DX / Metadata API)
- Net Zero Cloud (licensed managed package `sustainability`)
- Screen Flow (Lightning Flow Builder)
- Experience Cloud LWR (`talon-template-byo` / Build Your Own)
- Salesforce CLI (`sf project deploy start`)
- Optional npm tooling: Prettier, ESLint, `sfdx-lwc-jest` (no LWC source in this repo yet)

## Directory Structure

```
VehicleEnergyUseFlow-NZC/
├── force-app/main/default/
│   ├── flows/Vehicle_Asset_Energy_Use.flow-meta.xml
│   ├── experiences/EUR_collection1/          # ExperienceBundle (LWR)
│   ├── networks/EUR collection.network-meta.xml
│   └── networkBranding/cbEUR_collection.*
├── manifest/package.xml
├── config/project-scratch-def.json
├── docs/open-source/                         # OSPO inventory and findings
├── wiki/index.md                             # synthesis
├── REPOSITORY_SUMMARY.md                     # this inventory
├── README.md
├── LICENSE.txt / LICENSE.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CODEOWNERS
└── sfdx-project.json
```

There is no Apex, LWC, Aura, custom object, permission set, or trigger metadata in `force-app`.

## Metadata Inventory

### Flow

| API name | Label | Type | Status | Path |
| ---- | ---- | ---- | ---- | ---- |
| `Vehicle_Asset_Energy_Use` | Vehicle Asset Energy Use | Screen Flow (`processType` = Flow) | Active | `force-app/main/default/flows/Vehicle_Asset_Energy_Use.flow-meta.xml` |

**Interview path**

1. `GetAsset` — `recordLookups` on `VehicleAssetEmssnSrc` where `Id` = `RecordID`
2. `FuelConsumtion` — screen (required: Name, Other Emissions Factor lookup, Fuel Type, Fuel Consumption, Fuel Consumption Unit; optional: Start Date, End Date, Fuel Efficiency, Fuel Efficiency Unit default `MILES_PER_GALLON`)
3. `CreateEUR` — `recordCreates` on `VehicleAssetEnrgyUse`

**Input variable:** `RecordID` (String, `isInput=true`). Not named `recordId`.

**Picklist choice sets (from `VehicleAssetEnrgyUse`):** `FuelType`, `FuelConsumptionUnit`, `FuelEfficiencyUnit`.

**Create field map**

| Flow element | Target field |
| ---- | ---- |
| `Name` | `Name` |
| `OtherEmissionsFactors.recordId` | `OtherEmssnFctrId` |
| `Fuel_Type` | `FuelType` |
| `Fuel_Consumption` | `FuelConsumption` |
| `Fuel_Consumption_Unit` | `FuelConsumptionUnit` |
| `Start_Date` | `StartDate` |
| `End_Date` | `EndDate` |
| `Fuel_Efficiency` | `FuelEfficiency` |
| `Fuel_Efficiency_Unit` | `FuelEfficiencyUnit` |
| `RecordID` | `VehicleAssetEmssnSrcId` |

### Experience Cloud

| Metadata | API / name | Path |
| ---- | ---- | ---- |
| ExperienceBundle | `EUR_collection1` | `force-app/main/default/experiences/EUR_collection1/` |
| Site meta | label EUR collection, type `ChatterNetworkPicasso`, URL prefix `eurlwr` | `force-app/main/default/experiences/EUR_collection1.site-meta.xml` |
| Network | `EUR collection` | `force-app/main/default/networks/EUR collection.network-meta.xml` |
| NetworkBranding | `cbEUR_collection` | `force-app/main/default/networkBranding/` |

**Site config**

- Template: `talon-template-byo`
- Auth: `AUTHENTICATED_WITH_PUBLIC_ACCESS_ENABLED`
- Network URL prefix: `eurlwrvforcesite`
- Status: Live
- Member profiles in retrieved metadata: `admin`, `nzc partner user` (org-specific; may need remapping)
- Email sender in source: `noreply@example.com` (placeholder; set a verified org address after deploy)

**Routes / views**

| Route | URL prefix | View | Notes |
| ---- | ---- | ---- | ---- |
| Home | `""` | `views/home.json` | Embeds `Vehicle_Asset_Energy_Use` via `dxp_flow:flow` |
| EUR-lwc | `eur-lwc` | `views/eURLwc.json` | Same vehicle flow |
| Login / Register / Forgot Password / Check Password | standard | matching views | Standard LWR login components |
| Error / Too Many Requests / Service Not Available / News Detail | standard | matching views | Platform pages |

Branding sets: `nZC.json` (scoped NZC), `buildYourOwnLWR.json`. Theme: `themes/buildYourOwnLWR.json`.

**Not in this repo:** CustomSite `EUR_collection` (referenced by the Network as `<site>EUR_collection</site>`). Target orgs may need the Digital Experience created or published before Network deploy succeeds.

### Manifest

`manifest/package.xml` members: `Vehicle_Asset_Energy_Use` (Flow), `EUR_collection1` (ExperienceBundle), `EUR collection` (Network), `cbEUR_collection` (NetworkBranding). API 64.0.

## Data Model

Net Zero Cloud vehicle family (standard objects; not defined in this repo):

```
VehicleAssetEmssnSrc  1──*  VehicleAssetEnrgyUse  *──1  OtherEmssnFctr
        │                         │
        │                         └── carbon footprint / NZC calculations
        └── VehicleAssetCrbnFtprnt (downstream, not written by this flow)
```

Stationary family (not automated here): `StnryAssetEnvrSrc` / `StnryAssetEnrgyUse` / `StnryAssetCrbnFtprnt` plus managed flow `sustainability__CollectEnergyUseData`.

This org model does not include Fugitive or Process asset objects.

## Deployment

| Path | How |
| ---- | ---- |
| Option 1 | GitHub Salesforce Deploy Tool, ref `deploy-mdapi` (Metadata API layout, `package.xml` at root) |
| Option 2 | GitHub Release asset `VehicleEnergyUseFlow-NZC-Deploy.zip` via Workbench |
| Option 3 | `sf project deploy start --source-dir force-app --target-org <alias>` from `master` |

Prerequisite: Net Zero Cloud licensed; Digital Experiences enabled for site metadata.

After deploy: map Lightning record page `recordId` → flow `RecordID`; publish EUR collection; assign real profiles; set site sender email; grant FLS/CRUD on vehicle energy-use objects to site users.

`config/project-scratch-def.json` is Developer Edition + `Communities`. Net Zero Cloud is typically **not** available on scratch orgs.

## Integration Points

| Dependency | In repo? | Notes |
| ---- | ---- | ---- |
| Net Zero Cloud (`sustainability`) | No | Required managed package |
| `VehicleAssetEmssnSrc`, `VehicleAssetEnrgyUse`, Other Emissions Factor | No | Standard NZC objects |
| `dxp_flow:flow`, LWR login/layout | No | Standard Experience Cloud |
| NZC LLM Bill Ingestor (`billIngestorGuest`) | No | Optional companion; not referenced by site pages |

## Security Notes

- No Apex: no SOQL injection or Apex DML-in-loop surface in this repo
- No hardcoded credentials in source (site sender is a placeholder address)
- Flow runs in user context of the running user; site users need object/FLS access
- Locker Service enabled on the LWR app page (`isLockerServiceEnabled: true`)

There is no Apex or LWC source, so Salesforce copyright file headers and `@api` / Javadoc style rules do not currently apply. Add headers if Apex or LWC is introduced.

## Development Guidelines

- Keep Experience Cloud components pointing at metadata that ships in this package
- Do not reintroduce unmanaged or companion-package component references on site pages
- Update this file when metadata types, flow shape, or site routes change
- Prefer `sf` CLI v2 commands documented in `README.md`
- Target test coverage >75% for any Apex added later
- Cursor / LLM maintainers: keep `wiki/index.md` (synthesis) and this file (inventory) in sync; see [awesome-context](https://github.com/johannesjo/awesome-context) for maintainer rule patterns

## Related Docs

- `README.md` — install, usage, architecture diagram
- `wiki/index.md` — how it works and caveats
- `docs/open-source/OPEN_SOURCE_DEPENDENCIES.md` — 3PP / platform inventory
- `docs/open-source/COMPLIANCE_FINDINGS.md` — OSPO / quality findings

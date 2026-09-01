# Vehicle Asset Energy Use (NZC) — Repository Summary

LLM-oriented inventory of this Salesforce DX accelerator. For how the solution works and the main caveats, read `wiki/index.md` first.

## Overview

**Vehicle Asset Energy Use (NZC)** captures vehicle fuel and energy use in Salesforce Net Zero Cloud. It ships:

- A screen flow that creates `VehicleAssetEnrgyUse` records against a `VehicleAssetEmssnSrc` parent (internal Lightning and EUR collection Home)
- A config-driven guest LWC (`guestRecordCapture`) on public `/eur-lwc` for unauthenticated vehicle and stationary capture
- Apex guest capture engine (CMDT allowlist, USER_MODE search/create, Field Set schema)
- An Experience Cloud LWR site (**EUR collection**) plus network and branding metadata

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
- Lightning Web Components (LWR Experience Cloud)
- Apex (`with sharing` / `inherited sharing`, `USER_MODE`)
- Experience Cloud LWR (`talon-template-byo` / Build Your Own)
- Salesforce CLI (`sf project deploy start`)
- npm tooling: Prettier, ESLint, `sfdx-lwc-jest`

## Directory Structure

```
VehicleEnergyUseFlow-NZC/
├── force-app/main/default/
│   ├── classes/                              # Guest capture Apex + tests
│   ├── lwc/                                  # Primitives, service module, composer
│   ├── objects/Guest_Capture_Config__mdt/
│   ├── objects/VehicleAssetEnrgyUse/fieldSets/
│   ├── objects/StnryAssetEnrgyUse/fieldSets/
│   ├── customMetadata/                       # Vehicle_Energy_Use and Stationary_Energy_Use
│   ├── permissionsets/Guest_Record_Capture.permissionset-meta.xml
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

### Guest capture (Apex + LWC)

**Custom metadata** `Guest_Capture_Config__mdt` — object API names only from this allowlist; the LWC client may pass only `configName`. Optional `Form_Title__c`, `Parent_Search_Label__c`, and `Submit_Label__c` distinguish stacked composers.

| Field | Vehicle (`Vehicle_Energy_Use`) | Stationary (`Stationary_Energy_Use`) |
| ---- | ---- | ---- |
| `Search_Object__c` | `VehicleAssetEmssnSrc` | `StnryAssetEnvrSrc` |
| `Search_Field__c` | `Name` | `Name` |
| `Target_Object__c` | `VehicleAssetEnrgyUse` | `StnryAssetEnrgyUse` |
| `Parent_Lookup_Field__c` | `VehicleAssetEmssnSrcId` | `StnryAssetEnvrSrcId` |
| `Field_Set_Name__c` | `Guest_Energy_Use_Capture` | `Guest_Energy_Use_Capture` |
| `Min_Search_Length__c` | 3 | 3 |
| `Result_Limit__c` | 25 | 25 |
| `Default_Field_Values__c` | `{"FuelEfficiencyUnit":"MILES_PER_GALLON"}` | `{"FuelConsumptionUnit":"kWh"}` |
| `Form_Title__c` | Vehicle energy use | Stationary energy use |
| `Parent_Search_Label__c` | Vehicle asset | Stationary asset |
| `Submit_Label__c` | Create energy use record | Create energy use record |

**Field Set** `Guest_Energy_Use_Capture` on `VehicleAssetEnrgyUse`: required `Name`, `OtherEmssnFctrId`, `FuelType`, `FuelConsumption`, `FuelConsumptionUnit`; optional `StartDate`, `EndDate`, `FuelEfficiency`, `FuelEfficiencyUnit`. Parent lookup is not a Field Set member.

**Field Set** `Guest_Energy_Use_Capture` on `StnryAssetEnrgyUse`: required `Name`, `OtherEmssnFctrId`, `FuelType`, `FuelConsumption`, `FuelConsumptionUnit`; optional `StartDate`, `EndDate`. No fuel-efficiency fields. Parent lookup is not a Field Set member.

**Permission set** `Guest_Record_Capture`: Apex class access on `GuestRecordCaptureController`; Read `VehicleAssetEmssnSrc`, `StnryAssetEnvrSrc`, and `OtherEmssnFctrSet`; Create/Read `VehicleAssetEnrgyUse` and `StnryAssetEnrgyUse` plus FLS for capture fields (required `Name` / `FuelType` omitted). Assign to the EUR collection guest user after deploy.

**Apex** (`force-app/main/default/classes/`)

| Class | Role |
| ---- | ---- |
| `GuestRecordCaptureController` | Thin `@AuraEnabled` façade (`getConfig`, `searchRecords`, `getFormSchema`, `createRecord`) |
| `GuestRecordCaptureService` | Config, search purpose (`parent` vs Field Set lookup API name), Field Set whitelist insert |
| `GuestCaptureConfigSelector` | `Guest_Capture_Config__mdt` |
| `GuestSObjectSelector` | Allowlisted `LIKE` search |
| `FieldSetSchemaService` | Field Set → `FieldDescriptor` |
| `GuestRecordCaptureDto` | `CaptureConfig` (includes form/parent/submit labels), `SearchResult`, `FieldDescriptor` |
| `GuestRecordCaptureException` | Typed errors surfaced as `AuraHandledException` |

`searchRecords` purpose: `"parent"` (or blank) searches the config search object. Any other purpose must be a Field Set lookup API name (for example `OtherEmssnFctrId` → `OtherEmssnFctrSet`). There is no `OtherEmssnFctr` object.

**LWC** (`force-app/main/default/lwc/`)

| Bundle | Exposed | Role |
| ---- | ---- | ---- |
| `recordTypeahead` | no | Presentational combobox/listbox; parent debounces `search` and replaces `results` |
| `dynamicFieldForm` | no | Renders FieldDescriptor rows; parent search is a sibling, not a form field |
| `inlineStatus` | no | Success/error/info region (no toasts) |
| `guestRecordCaptureService` | no | JS-only wrappers for the Apex façade |
| `guestRecordCapture` | yes | Composer for `lightningCommunity__Page` / `lightningCommunity__Default`; `@api configName` default `Vehicle_Energy_Use` |

Composer Jest mocks `c/guestRecordCaptureService` (does not call Apex). Primitive Jest tests use mock `@api` data.

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
| EUR-lwc | `eur-lwc` | `views/eURLwc.json` | Two `c:guestRecordCapture` instances (`Vehicle_Energy_Use` and `Stationary_Energy_Use`); route `pageAccess` Public |
| Login / Register / Forgot Password / Check Password | standard | matching views | Standard LWR login components |
| Error / Too Many Requests / Service Not Available / News Detail | standard | matching views | Platform pages |

Branding sets: `nZC.json` (scoped NZC), `buildYourOwnLWR.json`. Theme: `themes/buildYourOwnLWR.json`.

**Not in this repo:** CustomSite `EUR_collection` (referenced by the Network as `<site>EUR_collection</site>`). Target orgs may need the Digital Experience created or published before Network deploy succeeds.

Guest sharing rules are **not packaged**. After deploy, create guest user sharing for `VehicleAssetEmssnSrc`, `StnryAssetEnvrSrc`, `OtherEmssnFctrSet`, `VehicleAssetEnrgyUse`, and `StnryAssetEnrgyUse`, and assign `Guest_Record_Capture` to the site guest user.

### Adding the next object

1. Field Set on the target object
2. New `Guest_Capture_Config__mdt` row
3. FLS/CRUD + guest sharing for those objects
4. Drop `c:guestRecordCapture` on a page with that `configName`

No new typeahead or form LWC.

### Manifest

`manifest/package.xml` members include Flow, ExperienceBundle, Network, NetworkBranding, Apex classes, `Guest_Capture_Config__mdt`, `VehicleAssetEnrgyUse` and `StnryAssetEnrgyUse` (Field Sets), Custom Metadata `Guest_Capture_Config.Vehicle_Energy_Use` and `Guest_Capture_Config.Stationary_Energy_Use`, permission set `Guest_Record_Capture`, and LightningComponentBundle members `dynamicFieldForm`, `guestRecordCapture`, `guestRecordCaptureService`, `inlineStatus`, `recordTypeahead`. API 64.0.

## Data Model

Net Zero Cloud vehicle family (standard objects; not defined in this repo except the Field Set on `VehicleAssetEnrgyUse`):

```
VehicleAssetEmssnSrc  1──*  VehicleAssetEnrgyUse  *──1  OtherEmssnFctrSet
        │                         │
        │                         └── carbon footprint / NZC calculations
        └── VehicleAssetCrbnFtprnt (downstream, not written by this flow)
```

`OtherEmssnFctrId` on `VehicleAssetEnrgyUse` looks up **Other Emissions Factor Set** (`OtherEmssnFctrSet`). There is no `OtherEmssnFctr` object.

```
StnryAssetEnvrSrc  1──*  StnryAssetEnrgyUse  *──1  OtherEmssnFctrSet
        │                         │
        └── StnryAssetCrbnFtprnt (downstream, not written by guest capture)
```

Guest capture on `/eur-lwc` writes `StnryAssetEnrgyUse`. The managed flow `sustainability__CollectEnergyUseData` is not in this repo.

This org model does not include Fugitive or Process asset objects.

## Deployment

| Path | How |
| ---- | ---- |
| Option 1 | GitHub Salesforce Deploy Tool, ref `deploy-mdapi` (Metadata API layout, `package.xml` at root) |
| Option 2 | GitHub Release asset `VehicleEnergyUseFlow-NZC-Deploy.zip` via Workbench |
| Option 3 | `sf project deploy start --source-dir force-app --target-org <alias>` from `master` |

Prerequisite: Net Zero Cloud licensed; Digital Experiences enabled for site metadata.

After deploy: map Lightning record page `recordId` → flow `RecordID`; publish EUR collection; assign real profiles; set site sender email; grant FLS/CRUD on vehicle and stationary energy-use objects to site users; assign `Guest_Record_Capture` to the guest user; create guest sharing rules; keep `/eur-lwc` public.

`config/project-scratch-def.json` is Developer Edition + `Communities`. Net Zero Cloud is typically **not** available on scratch orgs.

## Integration Points

| Dependency | In repo? | Notes |
| ---- | ---- | ---- |
| Net Zero Cloud (`sustainability`) | No | Required managed package |
| `VehicleAssetEmssnSrc`, `VehicleAssetEnrgyUse`, `OtherEmssnFctrSet` | Field Set only on energy use | Standard NZC vehicle objects |
| `StnryAssetEnvrSrc`, `StnryAssetEnrgyUse` | Field Set only on energy use | Standard NZC stationary objects |
| `dxp_flow:flow`, LWR login/layout | No | Standard Experience Cloud |
| NZC LLM Bill Ingestor (`billIngestorGuest`) | No | Optional companion; not referenced by site pages |

## Security Notes

- Guest Apex never accepts raw object API names from the client; objects come from `Guest_Capture_Config__mdt`
- Create payload: keys not in the Field Set are rejected; parent Id is required and must match the config search object
- SOQL/DML use `USER_MODE` (sharing + FLS of the running guest or community user)
- Guest sharing rules remain org setup and are not in source
- No hardcoded credentials (site sender is a placeholder address)
- LWCs: no `innerHTML`; presentational primitives do not import Apex
- Locker Service enabled on the LWR app page (`isLockerServiceEnabled: true`)
- Apex and LWC files include Salesforce copyright / Apache-2.0 headers

## Development Guidelines

- Keep Experience Cloud components pointing at metadata that ships in this package
- Do not reintroduce unmanaged or companion-package component references on site pages
- Do not name a vehicle-specific composer; add objects via CMDT + Field Set
- Update this file when metadata types, flow shape, LWC, or site routes change
- Prefer `sf` CLI v2 commands documented in `README.md`
- Apex tests: no `SeeAllData`; ≥85% on changed classes (guest capture tests ship with the engine)
- LWC Jest: DOM assertions only; composer mocks `guestRecordCaptureService`
- Cursor / LLM maintainers: keep `wiki/index.md` (synthesis) and this file (inventory) in sync; see [awesome-context](https://github.com/johannesjo/awesome-context) for maintainer rule patterns

## Related Docs

- `README.md` — install, usage, architecture diagram
- `wiki/index.md` — how it works and caveats
- `docs/open-source/OPEN_SOURCE_DEPENDENCIES.md` — 3PP / platform inventory
- `docs/open-source/COMPLIANCE_FINDINGS.md` — OSPO / quality findings

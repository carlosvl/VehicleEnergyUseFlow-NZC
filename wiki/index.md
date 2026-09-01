# Vehicle Asset Energy Use (NZC)

This accelerator captures **vehicle** fuel and energy use in Salesforce Net Zero Cloud. It is the custom counterpart to the managed **Collect Energy Use Data** experience that Net Zero Cloud ships for stationary assets.

For component names, paths, and object lists, see [REPOSITORY_SUMMARY.md](../REPOSITORY_SUMMARY.md).

## How capture works

There are two capture paths. The screen flow creates Vehicle Asset Energy Use records. The guest LWC on `/eur-lwc` creates Vehicle Asset Energy Use or Stationary Asset Energy Use records, depending on which card the visitor uses.

### Internal Lightning (screen flow)

1. A user starts from a Vehicle Asset Emission Source record page.
2. The **Vehicle Asset Energy Use** screen flow loads that asset, then collects fuel type, consumption, optional efficiency, optional dates, and a required Other Emissions Factor.
3. The flow creates the energy use record. The flow input that identifies the parent asset is named `RecordID`. Lightning pages that pass `recordId` must map that value explicitly.

### Experience Cloud guest (LWC)

Unauthenticated visitors on the public **EUR-lwc** page (`/eur-lwc`) use a Lightning web component instead of the flow. The page hosts **two** instances of the same composer: vehicle (`Vehicle_Energy_Use`) and stationary (`Stationary_Energy_Use`). The visitor searches the parent asset that guest sharing allows, fills the Field Set form (including Other Emissions Factor from **Other Emissions Factor Set** — there is no Other Emissions Factor object), and submits. Apex runs in user mode against an allowlisted config; the client never sends object API names.

Home on the EUR collection site still runs the vehicle screen flow for authenticated members. The managed stationary **Collect Energy Use Data** flow is not on Home.

## Design decisions

- **Custom flow for vehicles.** The stationary collector is inside the managed Net Zero Cloud package and cannot be retrieved as editable source. This project provides an equivalent guided capture path for the vehicle asset family.
- **Reusable guest composer.** Guest capture is a config-driven LWC (`Guest Record Capture`) plus Custom Metadata, not a vehicle-only component. The next similar object is a Field Set, a `Guest_Capture_Config__mdt` row, FLS/sharing, and the same composer with a different config name.
- **No custom objects.** Records are written to standard Net Zero Cloud vehicle objects.
- **Experience Cloud is optional but included.** The EUR collection LWR site is for partner, community, or guest users who should not work in the internal app. Digital Experiences must be enabled before that metadata can deploy.
- **Pages only reference this package.** Home runs the vehicle flow that ships here. EUR-lwc runs the guest composer twice (`Vehicle_Energy_Use` and `Stationary_Energy_Use`). The NZC LLM Bill Ingestor remains an optional companion, not a deploy dependency.

## Guest site setup (required after deploy)

Guest sharing rules and permission set assignment are org setup; they are not packaged.

1. **Assign `Guest_Record_Capture`** to the EUR collection **guest user** (Experience Workspaces → Administration → Members, or the site guest user record in Setup).
2. **Create guest user sharing rules** for:
   - `VehicleAssetEmssnSrc` — Read (vehicle parent search)
   - `StnryAssetEnvrSrc` — Read (stationary parent search)
   - `OtherEmssnFctrSet` — Read (records guests may choose as the emissions factor)
   - `VehicleAssetEnrgyUse` and `StnryAssetEnrgyUse` — access consistent with Create/Read on the permission set so inserts succeed in user mode
3. **Publish EUR-lwc as a public page** (`/eur-lwc`). The site is `AUTHENTICATED_WITH_PUBLIC_ACCESS_ENABLED`; the EUR-lwc route is public so guests can open it without signing in.

Without sharing, typeaheads return no rows even when FLS is correct. Without the permission set, Apex and object access fail.

## Adding another capture object

Do not fork the composer. For another Net Zero Cloud family (waste, hotel, and so on):

1. Add a Field Set on the target object with the create fields (parent lookup stays out of the Field Set).
2. Add a `Guest_Capture_Config__mdt` row (search object/field, target object, parent lookup field, Field Set name, min length, result limit, optional default JSON, optional card labels).
3. Extend FLS/CRUD (same or a new permission set) and guest sharing for those objects.
4. Drop **Guest Record Capture** on an Experience Cloud page and set **Capture Config Developer Name** to that row’s developer name.

## Caveats

- Target orgs need a Net Zero Cloud license. Scratch orgs generally cannot run this product.
- After deploy, set the Experience Cloud email sender to a verified org address. Source uses a placeholder.
- The retrieved network membership includes a partner profile named `nzc partner user`. Create that profile or replace it with profiles that exist in the target org.
- The network metadata references a site named EUR collection. If deploy reports a missing site, create or publish the Digital Experience in Setup, then redeploy.
- Other Emissions Factor lookups use **Other Emissions Factor Set** (`OtherEmssnFctrSet`).
- Run Salesforce Code Analyzer before any production publish.

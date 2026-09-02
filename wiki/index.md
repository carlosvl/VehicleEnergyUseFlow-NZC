# Vehicle Asset Energy Use (NZC)

This accelerator captures **vehicle** fuel and energy use in Salesforce Net Zero Cloud. It is the custom counterpart to the managed **Collect Energy Use Data** experience that Net Zero Cloud ships for stationary assets.

For component names, paths, and object lists, see [REPOSITORY_SUMMARY.md](../REPOSITORY_SUMMARY.md). For Setup work after deploy (sharing, guest APIs, publish, licenses), see [docs/admin-setup/README.md](../docs/admin-setup/README.md).

## How capture works

There are two capture paths. The screen flow creates Vehicle Asset Energy Use records. The guest LWC on `/eur-lwc` creates Vehicle Asset Energy Use or Stationary Asset Energy Use records, depending on which card the visitor uses.

### Internal Lightning (screen flow)

1. A user starts from a Vehicle Asset Emission Source record page.
2. The **Vehicle Asset Energy Use** screen flow loads that asset, then collects fuel type, consumption, optional efficiency, optional dates, and a required Other Emissions Factor.
3. The flow creates the energy use record. The flow input that identifies the parent asset is named `RecordID`. Lightning pages that pass `recordId` must map that value explicitly.

### Experience Cloud guest (LWC)

Unauthenticated visitors on the public **EUR-lwc** page (`/eur-lwc`) use a Lightning web component instead of the flow. The page hosts **two** instances of the same composer: vehicle (`Vehicle_Energy_Use`) and stationary (`Stationary_Energy_Use`). The visitor searches the parent asset that guest sharing allows, fills the Field Set form, and submits. Apex copies **Other Emissions Factor Set** (`OtherEmssnFctrId`) from the selected parent asset; guests do not pick a factor. There is no Other Emissions Factor object. Apex runs in user mode against an allowlisted config; the client never sends object API names.

Home on the EUR collection site still runs the vehicle screen flow for authenticated members. The managed stationary **Collect Energy Use Data** flow is not on Home.

## Design decisions

- **Custom flow for vehicles.** The stationary collector is inside the managed Net Zero Cloud package and cannot be retrieved as editable source. This project provides an equivalent guided capture path for the vehicle asset family.
- **Reusable guest composer.** Guest capture is a config-driven LWC (`Guest Record Capture`) plus Custom Metadata, not a vehicle-only component. The next similar object is a Field Set, a `Guest_Capture_Config__mdt` row, FLS/sharing, and the same composer with a different config name.
- **No custom objects.** Records are written to standard Net Zero Cloud vehicle and stationary energy-use objects.
- **Experience Cloud is optional but included.** The EUR collection LWR site is for partner, community, or guest users who should not work in the internal app. Digital Experiences must be enabled before that metadata can deploy.
- **Pages only reference this package.** Home runs the vehicle flow that ships here. EUR-lwc runs the guest composer twice (`Vehicle_Energy_Use` and `Stationary_Energy_Use`). The NZC LLM Bill Ingestor remains an optional companion, not a deploy dependency.

## Guest site setup (required after deploy)

The numbered checklist, license caveats, and troubleshooting live in [docs/admin-setup/README.md](../docs/admin-setup/README.md). These items are **org Setup**, not metadata in the package:

- **Allow guest users to access public APIs** (Experience Workspaces → Administration → Preferences). This is not in Network or ExperienceBundle source. Without it, guest Apex returns **The Apex request is invalid**. Do not confuse it with the guest profile permission **API Enabled** (leave that off).
- **Publish** the site after every LWC or Experience page deploy. Guests load a compiled webruntime view; metadata deploy alone does not refresh it.
- **Guest user sharing rules** grant **Read only**. Use them on `VehicleAssetEmssnSrc`, `StnryAssetEnvrSrc`, and `OtherEmssnFctrSet` so typeahead and the copied factor lookup work. Create on energy-use objects comes from the permission set or guest profile, not from sharing.
- **Assign `Guest_Record_Capture`** to the site guest user when the **Guest User license** includes Net Zero Cloud objects. Many orgs cannot assign that permission set (or the same CRUD on the guest profile). Then grant Apex class and Custom Metadata access on the guest profile so the cards can load, and use authenticated members whose license includes Net Zero Cloud for search and create.
- Keep `/eur-lwc` **Public**. The site is `AUTHENTICATED_WITH_PUBLIC_ACCESS_ENABLED`; Home stays for signed-in members.
- If the org already has an **enhanced LWR** site, the classic ExperienceBundle in this repo will not overlay it. Place two Guest Record Capture components in Experience Builder (`Vehicle_Energy_Use` and `Stationary_Energy_Use`) and publish.

Without parent sharing, typeaheads return no rows even when FLS is correct. Without public APIs and Apex class access, the cards never load config.

## Adding another capture object

Do not fork the composer. For another Net Zero Cloud family (waste, hotel, and so on):

1. Add a Field Set on the target object with the create fields (parent lookup and parent-copied fields stay out of the Field Set).
2. Add a `Guest_Capture_Config__mdt` row (search object/field, target object, parent lookup field, Field Set name, min length, result limit, optional default JSON, optional `Parent_Copied_Fields__c` JSON, optional card labels).
3. Extend FLS/CRUD (same or a new permission set) and guest sharing for those objects.
4. Drop **Guest Record Capture** on an Experience Cloud page and set **Capture Config Developer Name** to that row’s developer name.

## Caveats

- Target orgs need a Net Zero Cloud license. Scratch orgs generally cannot run this product.
- After deploy, set the Experience Cloud email sender to a verified org address. Source uses a placeholder.
- The retrieved network membership includes a partner profile named `nzc partner user`. Create that profile or replace it with profiles that exist in the target org.
- The network metadata references a site named EUR collection. If deploy reports a missing site, create or publish the Digital Experience in Setup, then redeploy.
- Other Emissions Factor lookups use **Other Emissions Factor Set** (`OtherEmssnFctrSet`). The internal flow still collects that lookup. Guest create copies `OtherEmssnFctrId` from the parent asset; the selected asset must already have a factor set.
- Guest user sharing is public to anyone who can open the site URL. Keep OWD Private and share only parent assets you intend guests to find.
- The composer form saves through a custom `capturesave` event, not native `submit`. Do not rebind the form to `onsubmit` on the Experience page.
- Run Salesforce Code Analyzer before any production publish.

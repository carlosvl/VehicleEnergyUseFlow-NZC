# Vehicle Asset Energy Use (NZC)

This accelerator captures **vehicle** fuel and energy use in Salesforce Net Zero Cloud. It is the custom counterpart to the managed **Collect Energy Use Data** experience that Net Zero Cloud ships for stationary assets.

For component names, paths, and object lists, see [REPOSITORY_SUMMARY.md](../REPOSITORY_SUMMARY.md).

## How capture works

1. A user starts from a Vehicle Asset Emission Source (internal Lightning page or the EUR collection Experience Cloud site).
2. The **Vehicle Asset Energy Use** screen flow loads that asset, then collects fuel type, consumption, optional efficiency, optional dates, and a required Other Emissions Factor.
3. The flow creates a Vehicle Asset Energy Use record. Net Zero Cloud can then use that record in carbon footprint calculations.

The flow input that identifies the parent asset is named `RecordID`. Lightning pages that pass `recordId` must map that value explicitly.

## Design decisions

- **Custom flow for vehicles.** The stationary collector is inside the managed Net Zero Cloud package and cannot be retrieved as editable source. This project provides an equivalent guided capture path for the vehicle asset family.
- **No custom objects.** Records are written to standard Net Zero Cloud vehicle objects.
- **Experience Cloud is optional but included.** The EUR collection LWR site is for partner or community users who should not work in the internal app. Digital Experiences must be enabled before that metadata can deploy.
- **Pages only reference this package.** Home and EUR-lwc run the vehicle flow that ships here. The NZC LLM Bill Ingestor remains an optional companion, not a deploy dependency.

## Caveats

- Target orgs need a Net Zero Cloud license. Scratch orgs generally cannot run this product.
- After deploy, set the Experience Cloud email sender to a verified org address. Source uses a placeholder.
- The retrieved network membership includes a partner profile named `nzc partner user`. Create that profile or replace it with profiles that exist in the target org.
- The network metadata references a site named EUR collection. If deploy reports a missing site, create or publish the Digital Experience in Setup, then redeploy.
- Run Salesforce Code Analyzer before any production publish.

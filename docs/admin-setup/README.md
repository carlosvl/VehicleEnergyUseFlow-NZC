# Admin setup after deploy

This accelerator deploys metadata. **Sharing, guest API access, site preferences, Lightning page mapping, and Experience Cloud membership are org setup** — they are not in source. Complete the steps below as a Salesforce administrator before users or guests capture energy use.

How capture works: [wiki/index.md](../../wiki/index.md). Component inventory: [REPOSITORY_SUMMARY.md](../../REPOSITORY_SUMMARY.md).

## Packaged vs Setup

| In this repository (deploys) | You must do in the org (not packaged) |
| ---- | ---- |
| Screen flow `Vehicle_Asset_Energy_Use` | Map Lightning page `recordId` → flow **`RecordID`** |
| Guest LWCs, Apex, `Guest_Capture_Config__mdt`, Field Sets, permission set `Guest_Record_Capture` | Enable **Allow guest users to access public APIs**; grant guest Apex/CMDT access; assign the permission set **if the license allows** |
| Classic ExperienceBundle `EUR_collection1`, Network, NetworkBranding | Enable Digital Experiences; verified email sender; member profiles; **publish** the site; keep `/eur-lwc` public |
| Field Sets that omit Other Emissions Factor | Create **Other Emissions Factor Set** records; set `OtherEmssnFctrId` on parent assets guests may select |
| — | **Guest user sharing rules** (Read only) on parent assets and factor sets |
| — | Object Create on the guest profile or permission set when the **Guest User license** includes Net Zero Cloud objects |

---

## 1. Confirm Net Zero Cloud

1. Confirm **Vehicle Asset Emission Source** (`VehicleAssetEmssnSrc`) and **Vehicle Asset Energy Use** (`VehicleAssetEnrgyUse`) are visible.
2. Confirm **Stationary Asset Environmental Source** (`StnryAssetEnvrSrc`) and **Stationary Asset Energy Use** (`StnryAssetEnrgyUse`) if you will use the stationary guest card.
3. Create **Other Emissions Factor Set** records (`OtherEmssnFctrSet`). There is no Other Emissions Factor object.
4. On every parent asset that guests may select, set **Other Emissions Factor Set ID** (`OtherEmssnFctrId`). Guest Apex copies that lookup onto the energy-use record. The guest form does not ask for it. Submit fails if the selected asset has no value.

Keep org-wide default sharing **Private** for these objects. Guest access is added later with guest sharing rules, not by opening OWD.

---

## 2. Internal Lightning (screen flow)

1. Open a Vehicle Asset Emission Source record → **Edit Page**.
2. Add a **Flow** component and select `Vehicle Asset Energy Use`.
3. Map the page record Id to the flow input **`RecordID`** (case-sensitive; not `recordId`).
4. Save and activate the page.

Internal users still pick Other Emissions Factor Set in the flow. That path is unchanged.

---

## 3. Digital Experiences (site)

Do this if you will use **EUR collection**.

1. Setup → **Digital Experiences** → **Settings** → enable Digital Experiences if needed.
2. If Network deploy fails because the site is missing, create or publish a site named **EUR collection**, then redeploy Network metadata.
3. Open **Experience Workspaces** for **EUR collection**.
4. Set the site **email sender** to a verified address in your org. Source uses `noreply@example.com`.
5. Assign **member profiles** that exist in your org. Retrieved Network membership includes Admin and a partner profile named `nzc partner user`, which you may need to create or replace.
6. Confirm the **EUR-lwc** route is **Public** (`/eur-lwc`) so unauthenticated visitors can open it. The site auth type is authenticated with public access enabled; Home stays for signed-in members.
7. **Publish** the site (Experience Builder **Publish**, or CLI below). Guest pages use a compiled webruntime bundle. After you deploy LWC or Experience page changes, publish again or guests keep the previous JavaScript.

```bash
sf community publish --name "EUR collection" --target-org MyOrg
```

Do not retrieve and commit `CustomSite` metadata from a live org. That file includes org-specific `siteAdmin` usernames.

### Site type mismatch

This repo ships a classic **ExperienceBundle** (Picasso / Chatter Network). Orgs that created **Build Your Own (LWR)** with a current CLI get an **enhanced LWR** site (`DigitalExperienceBundle`). Salesforce will not overlay one type on the other. You cannot delete an Experience Cloud site to start over.

If the org already has enhanced LWR:

1. Do not expect the repo ExperienceBundle to replace the live site.
2. In Experience Builder, add **Guest Record Capture** twice on a public page.
3. Set **Capture Config Developer Name** to `Vehicle_Energy_Use` and `Stationary_Energy_Use`.
4. Publish.

---

## 4. Guest capture (required for `/eur-lwc`)

Unauthenticated Apex will not run until guest **public APIs** and **class access** are in place. Parent search needs **guest sharing**. Insert needs object **Create** on a license that includes Net Zero Cloud objects.

### 4.1 Allow guest users to access public APIs

This checkbox is **not** in Network or ExperienceBundle metadata. It is required so guest Lightning web components can call Apex and public APIs. It is **not** the guest profile system permission **API Enabled** — leave **API Enabled** unchecked.

1. Digital Experiences → **All Sites** → **EUR collection** → **Workspaces** → **Administration** → **Preferences**.
2. Enable **Allow guest users to access public APIs**.
3. Save.
4. Hard-refresh `/eur-lwc`.

Without this setting, the cards show **The Apex request is invalid** and never load config.

This setting also opens the site’s public API surface to unauthenticated visitors. Combine it with Private OWD and **least-privilege** guest sharing (only parent assets you intend anyone with the URL to search).

### 4.2 Apex, Custom Metadata, and object permissions

Assign permission set **Guest Record Capture** (`Guest_Record_Capture`) to the EUR collection **site guest user** when the license allows it (Experience Workspaces → Administration → Members, or the guest user record in Setup).

That permission set includes:

- Apex class `GuestRecordCaptureController`
- Custom Metadata Type `Guest_Capture_Config__mdt`
- Read on parent assets and Other Emissions Factor Set, including parent `OtherEmssnFctrId`
- Create/Read on energy-use objects (required `Name` and `FuelType` are omitted from field permissions because the platform rejects them on the permission set)

**Guest User license:** many orgs reject assigning this permission set (and reject the same Net Zero Cloud object CRUD on the guest profile) because the Guest User license does not include those objects. Guest sharing cannot work around a missing license. In that case:

1. On the site **guest profile**, enable Apex class access for `GuestRecordCaptureController` and Custom Metadata access for `Guest_Capture_Config__mdt` so `getConfig` / `getFormSchema` can run.
2. Use **authenticated** Experience Cloud members whose license includes Net Zero Cloud for search and create, **or** a customer/partner license that allows those objects. Apex in this package runs in user mode and does not bypass the license.

Guest-created records are owned by the site’s **guest record default owner**, not by the guest user.

### 4.3 Guest user sharing rules (Read only)

Sharing is **not packaged**. Create **guest user** sharing rules so the running user can **read** parents (and the factor set copied from the parent):

| Object | Guest sharing | Why |
| ---- | ---- | ---- |
| `VehicleAssetEmssnSrc` | Read | Vehicle parent typeahead |
| `StnryAssetEnvrSrc` | Read | Stationary parent typeahead |
| `OtherEmssnFctrSet` | Read | User-mode insert of the factor copied from the parent |

Guest user sharing rules grant **Read only**. They cannot grant Create. Create comes from object permissions on the permission set or guest profile (section 4.2).

Without parent sharing, typeaheads return no rows even when FLS is correct. Anyone with the public URL can see every record those rules match — keep criteria tight.

### 4.4 Authenticated community / partner users

For signed-in members on Home (flow) or who should use the composer while logged in:

- Read on parent asset objects
- Create and Read on energy-use objects, including FLS for fuel, dates, efficiency (vehicle), and `OtherEmssnFctrId`

---

## 5. Verify

| Surface | Expect |
| ---- | ---- |
| Vehicle Asset Emission Source page | Flow runs and creates `VehicleAssetEnrgyUse` |
| EUR collection Home (signed in) | Same vehicle flow |
| Public `/eur-lwc` | Two cards: Vehicle energy use and Stationary energy use |
| Guest submit | Name, fuel type, consumption, unit (optional dates; vehicle optional efficiency). Factor comes from the parent asset. Success message only — no `REQUIRED_FIELD_MISSING` flash |

Optional: add the companion [NZC LLM Bill Ingestor](https://github.com/carlosvl/NZC-LLM-Bill-Ingestor) on a different page if you want bill upload. This site does not reference it.

---

## Troubleshooting

| Symptom | Typical cause |
| ---- | ---- |
| **The Apex request is invalid** / fallback title **Record capture** | Guest public APIs off, or guest profile/perm set missing `GuestRecordCaptureController` / `Guest_Capture_Config__mdt` |
| Typeahead always empty | Guest sharing missing on the parent object |
| Submit: selected asset has no Other Emissions Factor Set | Parent `OtherEmssnFctrId` is blank |
| Submit: insufficient access / DML in user mode | License or object Create does not allow Net Zero Cloud create; Guest User license often cannot CRUD these objects |
| Red `REQUIRED_FIELD_MISSING [Name, Fuel Type]` then success | Stale published webruntime view. Publish the site and hard-refresh |
| Repo ExperienceBundle will not deploy onto the live site | Site type mismatch (classic Picasso vs enhanced LWR). Place the LWC in Builder (section 3) |

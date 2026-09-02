# Contributing Guide For Vehicle Asset Energy Use (NZC)

This page lists the operational governance model of this project, as well as the recommendations and requirements for how to best contribute. We strive to obey these as best as possible. As always, thanks for contributing.

# Governance Model

## Community Based

The intent and goal of open sourcing this project is to increase the contributor and user base. The governance model is one where new project leads (`admins`) will be added to the project based on their contributions and efforts.

# Getting started

1. Review the [README](README.md) for install and usage.
2. Review [docs/admin-setup/README.md](docs/admin-setup/README.md) for post-deploy Setup that is not in metadata.
3. Review [REPOSITORY_SUMMARY.md](REPOSITORY_SUMMARY.md) for architecture and inventory.
4. Open a GitHub Issue before starting large changes.

# Issues, requests & ideas

Use the [GitHub Issues](https://github.com/carlosvl/VehicleEnergyUseFlow-NZC/issues) page to submit issues, enhancement requests, and discuss ideas.

### Bug Reports and Fixes

- Search existing [Issues](https://github.com/carlosvl/VehicleEnergyUseFlow-NZC/issues) first.
- Include Salesforce org edition, API version, and whether Digital Experiences was enabled.
- If you submit a fix, open a Pull Request against `master` and mention the Issue number.

### New Features

- Describe the problem you want to solve in a new Issue.
- Wait for maintainer feedback before spending significant time on implementation.

### Tests, Documentation, Miscellaneous

- Trivial doc or test improvements can go straight to a Pull Request.
- Larger changes should start as an Issue.

# Contribution Checklist

- [ ] Clean, simple, well styled code that follows Salesforce Apex and Lightning Web Component best practices
- [ ] Commits are atomic and messages are descriptive. Related issues are mentioned by number
- [ ] Module-level and function-level comments for Apex or LWC you add
- [ ] Tests pass and coverage stays above 75% for any Apex you add
- [ ] Dependencies are minimized and use Apache 2.0, BSD-3, MIT, ISC, or MPL licenses
- [ ] Experience Cloud pages only reference metadata that ships in this repository (or is a standard Salesforce component)
- [ ] README, wiki, admin-setup, and REPOSITORY_SUMMARY stay in sync when Setup or guest capture behavior changes
- [ ] Changes are approved via peer code review

# Creating a Pull Request

1. **Ensure the bug/feature was not already reported** by searching GitHub Issues.
2. **Fork** the repository and clone your fork.
3. **Create** a feature branch from `master`.
4. **Commit** changes to your own branch.
5. **Push** your work to your fork.
6. **Submit** a Pull Request against `master`. Keep the pull request small and focused.
7. **Sign** the Salesforce CLA when prompted: https://cla.salesforce.com/sign-cla

> **NOTE**: Sync your fork before opening a pull request.

# Development Setup

```bash
git clone https://github.com/carlosvl/VehicleEnergyUseFlow-NZC.git
cd VehicleEnergyUseFlow-NZC
sf org login web --alias MyOrg
sf project deploy start --source-dir force-app --target-org MyOrg
```

Net Zero Cloud is a licensed product and is not typically available on scratch orgs. Develop and test in a sandbox or Developer Edition that already has Net Zero Cloud and Digital Experiences enabled. After deploy, complete the administrator steps in [docs/admin-setup/README.md](docs/admin-setup/README.md) (guest public APIs, sharing, site publish). After LWC changes, republish the Experience Cloud site or unauthenticated pages keep the previous webruntime bundle.

# Code of Conduct

Please follow our [Code of Conduct](CODE_OF_CONDUCT.md).

# License

By contributing your code, you agree to license your contribution under the terms of our project [LICENSE](LICENSE.txt) and to sign the [Salesforce CLA](https://cla.salesforce.com/sign-cla).

## ⬜ Buildroot & App Pipeline GPG Integration

- [ ] **Prepare Infrastructure for GPG Pre-Reqs**
  - [ ] Add host distro package detection logic to `setup.sh` (handle `gnupg` vs `gnupg2` names).
  - [ ] Provision space in repository for the company master public key (`company_public.asc`).

- [ ] **Implement Signed Fingerprint Manifest**
  - [ ] Add `generate_manifest.sh` to local tools to pull and calculate Buildroot archive hashes.
  - [ ] Implement manual out-of-band audit process for new upstream releases.
  - [ ] Sign generated `verified_manifest.txt` with company private key to emit `.sig`.

- [*] **Wire Up Verification Steps**
  - [*] Update `setup.sh` to isolate a temporary GPG keyring using `--no-default-keyring`.
  - [*] Add stage 1 verification: Validate `verified_manifest.txt.sig` authenticity.
  - [*] Add stage 2 verification: Map downloaded tarball against verified SHA256 string.

~ [ ] **Automatic Mechanism to present Selection of predefined Configs from buildroot
  ~ [ ] Fetch list
  ~ [ ] Build dynamic kconfig defition
  ~ [ ] Exit download stage before running config

~ [ ] Mechanism use latest LTS, Stable and Candidate from buildroot.org
  ~ [ ] Externalize table from Makefile
  ~ [ ] Tell versions
  ~ [ ] Option to hardcode specific version too

~ [ ] Add menu to add external repos by hand



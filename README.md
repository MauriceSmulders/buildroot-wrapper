# Inverted Buildroot Core SDK Wrapper Framework

A highly reproducible, production-grade Board Support Package (BSP) development ecosystem implementing the **Inverted Core SDK Pattern**.

## Architectural Philosophy

Monolithic corporate forks of embedded operating systems introduce severe technical debt, brittle upstream tracking histories, and fragile deployment friction. This architecture flips the integration paradigm: **the custom downstream application acts as the repository root space, while the upstream core distribution is treated as a volatile, external runtime asset.**

By encapsulating the core Buildroot engine entirely within a `.gitignore` sandbox partition, your repository tree remains pristine, tracking exclusively your custom configurations, out-of-tree package recipes, and local filesystem layout layers.

### Structural Engineering Advantages:
1. **Zero Maintenance Overhead:** Upstream security patches (CVEs) and release maintenance tracks are swallowed natively on execution passes, completely avoiding legacy manual codebase backport Sweeps.
2. **Deterministic Workspace Synchronization:** The master parent Makefile interfaces directly with a decoupled POSIX bootstrap script, ensuring that local developer or automated CI/CD container configuration drift is structurally impossible.
3. **Clean Interface Abstraction:** Implements an atomic pass-through proxy catch-all routing design. Developers and build nodes execute universal top-level shortcuts, while the orchestration layer maps directory constraints implicitly behind the scenes.

## System Topography

```text
                        [ THE DETERMINISTIC TOOLCHAIN ENGINE ]
  
  \$ git clone git@github.com:MauriceSmulders/buildroot-wrapper.git
  \$ make lts
         |
         v
  [ Parent Makefile ] --------> Dynamic Target Route --------> [ support/scripts/bootstrap.sh ]
                                                                          |
                                                                          v
  [ .buildroot-core/ ] <====== Extracts Pure Source Core <====== [ Cryptographic PGP Signature Validation ]
```

## Core Workspace Commands

### Environment Initialization
Bootstrap the toolchain repository sandbox, verify upstream cryptographic signatures natively via GnuPG, map external application boundaries, and enter the active Kconfig subsystem configuration screen:
```bash
make lts
```

### First Run (fresh clone, or after `make repoclean`)
Bare `make` detects the missing sandbox and offers the release stream itself,
then bootstraps your pick and falls through into the build:
```bash
$ make
[*] Core sandbox missing. Select a release stream:
      1) lts       - Long Term Support (2025.02)
      2) stable    - Stable (2025.08)
      3) candidate - Release Candidate (2025.11) [risky]
Selection [1/2/3]:
```
Or skip the menu and go direct:
```bash
make lts        # Long Term Support
make stable     # Stable
make candidate  # Release Candidate [risky]
```

> Note: do not pipe the bootstrap/configure step through `tee` — `menuconfig`
> is ncurses and needs a real terminal; piping breaks its navigation.
> `time make 2>&1 | tee build.log` is safe for the build itself, since the
> build never invokes `menuconfig`.

### Catch-All Target Proxies
Any standard Buildroot keyword directive entered at the project root is automatically captured, bound to the custom external tree parameters, and forwarded downstream to the core engine space natively:
```bash
make menuconfig
make savedefconfig
make
```

### Workspace Destruction Safeguard
Completely nuke volatile cached sandbox assets, compiled target objects, and temporary files safely without risking history pollution on tracked repository branches:
```bash
make repoclean
```

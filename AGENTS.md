# AGENTS.md — schedule-docs

Repo for **schedule tile** requirements, grouping specs, and ODF playback freezes (CIS / WMR). Not an app repo.

## Quick map

| Path | Use |
|------|-----|
| `docs/common/schedule-tile-common.md` | Shared tile baseline |
| `docs/{DISC}/schedule-tile-requirements.md` | Discipline delta pack |
| `docs/grouping/` | Grouping CSVs + README |
| `openspec/specs/schedule-grouping/spec.md` | Backend grouping OpenSpec |
| `ownScenarios/{DISC}/` | Freeze XML + README + `AC.feature` |
| `rawData/{DISC}/` | Source ODF — **never edit** |

## MCP (see `.cursor/mcp.json`)

Use in this order when researching a discipline:

1. **OSRP** — schedule tile UX (before / during / after)
2. **ORIS** — procedures, exceptional states, IRMs
3. **Common Codes** — `CC@Unit` Schedule Y/N/S, statuses, `SC@*`
4. **ODF verifier** — XPaths, M/O, allowed values, XML validation

Always put **document versions** on the first line of substantive replies. Do not invent OSRP/ORIS/CC/ODF facts.

## Commands

| Command | Output |
|---------|--------|
| `/define-requirements {DISC}` | `docs/{DISC}/schedule-tile-requirements.md` |
| `/build-simulation {DISC}` | `ownScenarios/{DISC}/` freeze (needs pack + `rawData`) |

Default edition: **LA28 / OG2028**.

## Hard rules

- Docs / specs / READMEs in **English**
- No BE/FE application code unless explicitly requested
- Conflicts / gaps → **Open product questions**, not silent product decisions
- Freezes: copy from `rawData` first; `DT_MEDALLISTS` before `DT_MEDALS`; announce every fabricated file

## Project rules

Persistent guidance lives in `.cursor/rules/` (`project-overview`, `schedule-tile-docs`, `own-scenarios`, `grouping-openspec`).

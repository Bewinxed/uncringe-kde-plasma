# latin-locale — any region's formats without its native digit rendering

**The papercut:** you want a region's conventions — currency, metric, paper size,
phone prefix, weekend — but setting its locale fills every Qt app with that
script's native digits: Arabic-Indic for `ar_*` (٠١٢٣), Devanagari for `hi_IN`,
Bengali for `bn_BD`... And KDE's Region & Language GUI cannot express "region X
but Latin numerals," so it fights every manual attempt.

**Why the obvious fixes fail (all verified on `ar_QA`):**
- `locale` output misleads: glibc's data often *is* Latin-digit, but **Qt doesn't
  read glibc locale data** — it uses its own CLDR tables, where many locales
  default to native numbering. `LC_NUMERIC=<region>` is what forces native digits
  into Qt apps while your terminal looks fine.
- Qt ignores `@numbers=latn` and `-u-nu-latn` entirely.
- Inventing a glibc locale (e.g. `en_QA`): Qt has no such entry and silently
  falls back to `en_US` — Imperial units, M/D/YY.
- `en_GB` as the base locale: Qt classifies it Imperial; loses metric.

**What works:** Qt honours per-category `LC_*` overrides. Regional categories on
the target locale, only `LC_NUMERIC`/`LC_TIME` on a Latin-digit locale.

**No hardcoding.** Every locale is validated against the system's own registry
(`/usr/share/i18n/SUPPORTED`) and generated on demand with `localedef`; the
target user comes from sudo; `/etc/default/locale` is resolved through its
symlink before backup (or the backup silently tracks the file being overwritten).

```
sudo latin-locale ar_QA                  # Qatar formats, Latin digits, day-first
sudo latin-locale ar_SA --digits en_US   # Saudi formats, US date order
sudo latin-locale hi_IN --ui en_GB       # India, British English UI
latin-locale --list ar_                  # what's available
sudo latin-locale --dry-run ar_AE        # print without writing
sudo latin-locale --revert               # restore pre-change config
```

KDE's Region & Language GUI rewrites `plasma-localerc` on Apply — just re-run.

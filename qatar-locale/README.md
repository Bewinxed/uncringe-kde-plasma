# qatar-locale — regional formats without Arabic-Indic numerals

**The papercut:** you want Qatar's regional conventions (metric, A4, QAR, +974,
Fri-Sat weekend) but setting `ar_QA` fills every Qt app with Arabic-Indic
digits (٠١٢٣) — and KDE's Region & Language GUI cannot express "Qatar but Latin
numerals," so it fights every manual attempt.

**Why the obvious fixes fail (all verified):**
- `locale` output lies to you here: glibc's `ar_QA` uses Latin digits
  (`decimal_point="."`), but **Qt does not read glibc locale data** — it uses its
  own CLDR tables, where `ar_QA`'s numbering system is `arab`. `LC_NUMERIC=ar_QA`
  is what forces ٠١٢٣ into Qt apps while `date` looks fine in the terminal.
- Qt ignores `@numbers=latn` and `-u-nu-latn` entirely — all resolve back to arab.
- Custom `en_QA` glibc locale: Qt has no such entry and silently falls back to
  `en_US` — Imperial units and M/D/YY, worse than the problem.
- `en_GB` as base: Qt classifies it Imperial. Loses metric.

**What works:** Qt honours per-category `LC_*` overrides. Keep the regional
categories on `ar_QA`, move only the two digit-rendering ones to `en_GB`:

```
LANG=en_US.UTF-8                       # UI language
LC_NUMERIC / LC_TIME = en_GB.UTF-8     # Latin digits, day-first dates
everything else      = ar_QA.UTF-8     # metric, A4, QAR, +974
```

The script writes both the system locale and `~/.config/plasma-localerc` (KDE's
GUI rewrites the latter on Apply — just re-run the script). Adapt the three
variables at the top for other countries with the same problem (any Arabic-script
locale: SA, AE, EG...).

```
sudo qatar-locale
```

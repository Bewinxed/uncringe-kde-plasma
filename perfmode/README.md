# perfmode — Threadripper performance on demand

**The papercut:** you want max performance when you ask for it and quiet idle
otherwise, and every forum offers a different governor incantation.

**The finding:** on a correctly configured Zen 4 platform there is nothing to
tune. Correct = `amd_pstate` in **active** mode, `prefcore` enabled, boost on,
`powersave` governor — and then **EPP is the only knob**. EPP is a bias hint to
the CPPC firmware, not a lock: measured on a 7960X, even `EPP=performance`
floats 2.2–4.8 GHz at light load with a 410 MHz floor. The kernel's Dynamic EPP
work (2026) formalizes exactly this model.

**The switch:** `power-profiles-daemon`, which KDE's power widget also drives.
This script is a thin wrapper: `perfmode max` / `auto` / `eco` / `status`.

**The caveat worth knowing:** ppd can only drive one backend. On some boards it
latches onto ACPI `platform_profile` and `amd_pstate` goes uncontrolled —
`perfmode status` prints the CpuDriver so you can verify it says `amd_pstate`.

Anti-tuning notes: don't force `governor=performance` (defeats firmware
autonomy in active mode), and don't set EPP by hand while ppd runs (it will
fight you).

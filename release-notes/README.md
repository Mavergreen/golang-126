# Release notes

This is golang-126's notes directory: hand-written prose for this line's own releases only,
never a moving pointer at another line's.

The generator (`release-notes.sh`, from mavericks-shipyard) writes the notes file for every
release: the title, a "What changed" section, a "Build ingredients" section when a pin moved,
and the footer. That one file, `dist/RELEASE_NOTES.md`, becomes the GitHub Release body AND
both Sparkle appcast `<description>`s (native and cross) -- the same bytes, read three times.

The footer's install-floor line describes the native `.pkg` (`--min-os 10.9.5`), the variant
most users install. The cross variant's own, different minimum (macOS 12 or later; it does not
carry a 10.9 floor) lives only in `go126-cross.xml`, via its own `sign_and_appcast.sh --min-os`
argument -- the notes describe the product, each appcast describes the artifact it serves.

A release's own notes are a directory named for its tag, `<full-version>/`. Each file in
`changes/` is one sentence the generator lists under "What changed", in name order (so a numeric
prefix orders them), each passing shipyard's `check-release-sentence.sh`. Each `requires/<short>`
file holds the minimum version of a product to install first, listed under "Before you update".

An older form, a file named `<full-version>.md` (e.g. `1.26.4-mavericks.1.md`), is OPTIONAL hand-written
prose for that one release. When present, it is inserted verbatim right after the generated
title. It must NOT start with its own `## ` heading -- the generator already emits the title;
a second one would double it.

A release whose only change is a pin (a Renovate repackage) needs no notes here: the generator's own sections
are the whole note. Any other publishing release must commit at least one `changes/` sentence, or shipyard's
`check-release-version.sh` refuses it.

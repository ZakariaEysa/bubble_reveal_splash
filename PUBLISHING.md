# Publishing bubble_curtain_splash

The first release is version **0.1.0**. The package lives locally in
`E:\packages\bubbles`; folder names do not determine the published Dart name.

Source: https://github.com/ZakariaEysa/bubble_curtain_splash

## Validate

From the package root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool example/lib example/test
flutter analyze
flutter test
dart run tool/check_readme.dart
cd example
flutter test
flutter build web
cd ..
flutter pub publish --dry-run
```

The README code blocks are compiled and rendered by the dedicated documentation
check. Build artifacts, local paths in Android configuration, caches, tests,
capture tooling, lockfiles, and the duplicate GIF are excluded from the upload.
Only the example's dependencies use a local path; the package's runtime
dependencies contain the Flutter SDK alone.

GitHub Actions repeats these checks and generates API documentation on Linux.
The local Windows SDK's bundled Dartdoc 9.0.6 can crash while precaching Flutter
dependency documentation with a RangeError in `_stripDocImports`; use the Linux
CI result to verify documentation if this SDK issue occurs locally.

## Publish the first release

Review the dry-run file list, ensure the GitHub main branch contains the matching
source and preview images, then run:

```sh
flutter pub publish
```

Follow the Google-account authentication flow if requested. Review the final
archive prompt before confirming. This command uploads to pub.dev; a dry run
does not. No token or Google credential belongs in this repository.

Name availability was checked through `https://pub.dev/api/packages/bubble_curtain_splash`
before preparation and returned HTTP 404. That does not reserve the name; the
server decides availability at the time of the first upload.

After publishing, verify the package page, install command, screenshot carousel,
README image links, generated API docs, and example tab. Tag the corresponding
commit `v0.1.0` after the release succeeds. Future releases require a new version
and changelog entry.

Publishing guidance: https://dart.dev/tools/pub/publishing

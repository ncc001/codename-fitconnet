# Copilot Instructions for fit_connect

This project is a Flutter application using Riverpod for state management and Hive for local storage. The codebase is currently in a starter state, but the following conventions and workflows are established:

## Architecture & Patterns
- **Entry Point:** The app starts in `lib/main.dart` with a standard `MyApp` widget. The home page is `MyHomePage`.
- **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`) is included for scalable state management. Use providers for app state and business logic.
- **Persistence:** Hive and `hive_flutter` are used for local storage. Store persistent data in Hive boxes, and initialize Hive in the app startup sequence.
- **Routing:** Navigation is handled with `go_router`.
- **Theming:** Use `ThemeData` and `GoogleFonts` for consistent app styling.

## Developer Workflows
- **Build:** Use `flutter run` to build and launch the app on a device or emulator.
- **Test:** Run widget and unit tests with `flutter test`. Example test: `test/widget_test.dart`.
- **Linting:** Lint rules are defined in `analysis_options.yaml` (extends `flutter_lints`). Run `flutter analyze` to check for issues.
- **Code Generation:** Use `build_runner` for code generation (e.g., Riverpod, Hive adapters). Run:  
  `flutter pub run build_runner build --delete-conflicting-outputs`
- **Dependencies:** Manage with `pubspec.yaml`. Add packages using `flutter pub add <package>`.

## Project Conventions
- **File Organization:**
  - Main app code in `lib/`
  - Tests in `test/`
  - Platform-specific code in `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`
- **Naming:** Use descriptive, lowerCamelCase for variables and methods. Use UpperCamelCase for class names.
- **Testing:** Place widget and unit tests in `test/`, mirroring the structure of `lib/` where possible.

## Integration Points
- **Riverpod:** Use `@riverpod` annotations and providers for state. Run code generation after adding new providers.
- **Hive:** Register adapters and open boxes before accessing data. Store models in Hive-compatible formats.
- **Routing:** Define routes using `go_router` in a dedicated file (e.g., `lib/router.dart`) as the app grows.

## Example Commands
- Build & run: `flutter run`
- Test: `flutter test`
- Analyze: `flutter analyze`
- Codegen: `flutter pub run build_runner build --delete-conflicting-outputs`

## References
- See `pubspec.yaml` for dependencies and versions.
- See `analysis_options.yaml` for linting rules.
- See `test/widget_test.dart` for test structure.

Update these instructions as the project evolves or if new conventions are adopted.

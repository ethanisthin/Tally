<div align="center">
  <img src="https://github.com/user-attachments/assets/82dba2ee-d68c-452b-b408-a8871ae9ae8d" alt="Tally" height = "250" width="250">
</div>

# Tally

Tally is a cross-platform expense tracker built with Flutter. It enables users to easily keep track of expenses, with authentication and cloud sync backed by Firebase.

## Features

- **Cross-Platform**: Runs on Android, iOS, Windows, Linux, and macOS using Flutter.
- **Authentication**: Uses Firebase Authentication to manage user sign-in and security.
- **Expense Tracking**: Add, view, and manage expenses for trips or daily use.
- **Modern UI**: Built with Material 3 for a clean and modern user experience.
- **Firebase Integration**: Syncs data across devices using Firebase as a backend.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A Firebase project (already set up in this repo — see `lib/firebase_options.dart`)
- Dart >= 2.17

### Running the App

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ethanisthin/AppTally.git
   cd AppTally
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app (choose your platform):**
   - For Android/iOS:  
     ```bash
     flutter run
     ```
   - For Windows:  
     ```bash
     flutter run -d windows
     ```
   - For Linux:  
     ```bash
     flutter run -d linux
     ```

4. **Login:**  
   On launch, you’ll see a login screen. Sign in with your credentials to begin tracking expenses.

### Project Structure

- `lib/`
  - `main.dart` — App entry point and routing logic
  - `firebase_options.dart` — Firebase configuration (auto-generated)
  - `screens/` — Main UI screens (login, home, etc.)
- `test/` — Widget tests for the app
- `linux/`, `windows/` — Platform-specific build files

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/docs/overview/)

## Contributing

Pull requests are welcome! Feel free to fork the repository and submit improvements or bug fixes.

## License

*No license specified yet.*

---


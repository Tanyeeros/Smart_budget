# Smart Budget

A pastel-themed Flutter budgeting app for recording expenses, managing monthly budgets, understanding spending habits, and tracking financial goals.

## Features

### Expense tracking

- Add expenses manually with natural text, for example `10 food` or `llaollao 10`.
- Add multiple expenses from one entry, for example `car loan 500, rent 650, lunch 20`.
- Record expenses using voice input in English, Bahasa Melayu, or Mandarin.
- Scan a receipt with the camera or select one from the photo gallery.
- Review scanned receipt items before saving: edit names and prices, select only your items, and split shared items between 1–5 people.
- View all recorded expenses in **Activity** and edit or delete an entry when needed.

### Smart categories and monthly budgets

- Automatic category suggestions for Food, Home, Transport, Shopping, Fun, Gifts, Subscriptions, Travel, Bills, Health, and Education.
- Edit any expense category after it is recorded.
- View monthly spending, total monthly budget, remaining budget, and budget progress on the Home dashboard.
- Edit each category budget from **Monthly budgets**.
- Add custom budget categories and choose a suitable icon.

### Insights and financial position

- Monthly report with total spending, remaining budget, top spending category, and category breakdown.
- Yearly report based on the expenses recorded in the app.
- Track assets such as KWSP and investment accounts.
- Track debts such as car loans and house loans.
- View assets, debts, and net worth.
- Set a yearly savings target and record savings deposits to monitor progress.

### Personalisation

- Set your own display name from the Home screen.
- Macaron-inspired interface using mint, butter yellow, peach, pink, and lavender tones.

## Tech stack

- [Flutter](https://flutter.dev/)
- Dart
- `speech_to_text` for device speech recognition
- `image_picker` for camera and gallery receipt selection
- `google_mlkit_text_recognition` for on-device receipt OCR

## Requirements

- Flutter SDK 3.x
- Android Studio with Android SDK Platform-Tools and Command-line Tools
- An Android phone or emulator
- For speech input: a working Android speech recognition service and microphone permission

## Getting started

1. Clone the repository:

   ```bash
   git clone https://github.com/Tanyeeros/Smart_budget.git
   cd Smart_budget
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Connect an Android phone with USB debugging enabled, or start an emulator.

4. Check that Flutter can see your device:

   ```bash
   flutter devices
   ```

5. Run the app:

   ```bash
   flutter run
   ```

## Android permissions

The app requests the following Android permissions:

- **Microphone** — required for voice expense input.
- **Camera** — requested by the system when taking a receipt photo.

If voice input does not produce text, check that the phone has an active speech recognizer selected in Android settings. On some devices, Google Speech Services or another compatible recognizer may need to be installed or selected first.

## Receipt scanning notes

Receipt OCR quality depends on the photo and the receipt format. For best results:

- Use good lighting and keep the receipt flat.
- Include the product lines and prices in the image.
- Check every scanned item before confirming.
- Use the editable review fields to correct item names, prices, or shared-item splits.

## Current limitations

- Data is stored in memory for the current app session; it is not yet saved to a local database or cloud account.
- Speech recognition is provided by the phone’s installed speech service, so language availability and accuracy vary by device.
- Receipt OCR is designed as an assistive feature and should always be reviewed before saving.

## Project structure

```text
lib/
  main.dart          # App UI, budgeting logic, OCR and voice flows
android/             # Android configuration and permissions
test/                # Flutter tests
pubspec.yaml         # Packages and project metadata
```

## Future improvements

- Persistent local storage and optional cloud backup
- Authentication and multiple user profiles
- Real charts for monthly and yearly trends
- Notifications for budget limits and savings milestones
- More advanced receipt item parsing and multi-language OCR

## License

This project is currently intended for personal and educational use. Add a license file before distributing it publicly.

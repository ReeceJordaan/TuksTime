# TuksTime

Your Ultimate Timetable App for the University of Pretoria

## Overview

TuksTime is a Flutter-based mobile application designed specifically for University of Pretoria students to manage their academic schedules. The app allows students to create, customize, and view their timetables in weekly and monthly formats, helping them stay organized throughout their academic journey.

## Features

- **Weekly View**: Visualize your weekly schedule with a clean, intuitive interface showing all your lectures, tutorials, and practicals.
- **Monthly View**: Get a broader perspective of your academic calendar in a monthly format.
- **Timetable Generation**: Easily generate your timetable by selecting your modules and preferred groups.
- **Clash Detection**: Automatically detects and highlights scheduling conflicts between different classes.
- **Time Management**: Current time indicator helps you keep track of your day.
- **Customization**: Add custom events and manage your academic schedule.
- **Persistent Storage**: Your timetable is saved locally on your device.

## Technical Details

- **Framework**: Built with Flutter for cross-platform compatibility (Android, iOS, Web)
- **State Management**: Uses StatefulWidget pattern
- **Data Storage**: Utilizes SharedPreferences for local data persistence
- **Data Format**: Works with CSV data for modules and lectures

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/TuksTime.git
   ```

2. Navigate to the project directory:
   ```
   cd TuksTime
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

- `lib/`
  - `data/`: Data models for lectures and modules
  - `screens/`: UI screens (Weekly, Monthly, Generate)
  - `services/`: Business logic and data services
  - `widgets/`: Reusable UI components
- `assets/`: Contains CSV data files for modules and lectures

# SparkleUpdater (macOS)

![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg?style=for-the-badge&logo=swift)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-blue.svg?style=for-the-badge&logo=swift)

**SparkleUpdater** is a dedicated macOS developer tool designed to streamline the release process for apps using the [Sparkle Framework](https://sparkle-project.org/). 

It provides a graphical interface to manage multiple projects, automatically generate EdDSA signatures, and update your `appcast.xml` feeds without touching the command line.

## ✨ Features

### 🚀 Automated Workflow
* **Drag & Drop:** Simply drop your `.zip` archive or `.dmg` update file into the window.
* **Auto-Detection:** Automatically extracts the version number from the filename and calculates the file size.
* **Signature Generation:** Uses a bundled `sign_update` binary to generate EdDSA signatures securely using keys stored in your Keychain.

### 📄 Appcast Management
* **XML Injection:** Automatically appends new release items to your existing `appcast.xml` or creates a brand new one if it doesn't exist.
* **Header Customization:** Configure the Appcast Title, Description, and Language code per project.
* **Release Notes:** Built-in editor for HTML release notes.

### 🗂 Project Persistence
* **Multi-App Support:** Manage configuration for multiple macOS applications in the sidebar.
* **Auto-Save:** Project settings (Paths, URLs, Titles) are persisted locally using `UserDefaults`.

---

## 🛠 Tech Stack

* **Language:** Swift 5
* **Framework:** SwiftUI (macOS)
* **Architecture:** MVVM (Model-View-ViewModel)
* **Core Logic:**
    * `Process` / `Pipe` for running the bundled `sign_update` tool.
    * `XMLInjector` for safe string manipulation of RSS feeds.
    * `NSSavePanel` / `NSOpenPanel` for file system interaction.

---

## 📖 Usage Guide
1. Prerequisites

Ensure you have generated your EdDSA keys for Sparkle and that your Private Key is stored in your macOS Keychain. This app relies on the sign_update tool finding this key automatically.

---

2. Setting up a Project

Click Add App (+) in the toolbar.

Enter your App Name.

Appcast XML Path: Browse to where your appcast.xml is (or should be) located on your disk.

Download Base URL: Enter the public URL where your update files will be hosted (e.g., https://example.com/downloads/).

Customization: Fill in the Title and Description for the RSS feed header.

---

3. Publishing an Update

Archive your app and compress it (e.g., MyApp_2.0.zip).

Drag and drop the file into the "DROP BUILD HERE" zone.

The app will:

Calculate the file size.

Parse the version (e.g., "2.0").

Sign the update.

Update the appcast.xml file with the new <item> entry.

Upload the updated XML and the Zip file to your server.

## ⚙️ Configuration Details
The project bundles the sign_update binary directly. The ShellRunner struct handles execution permissions (chmod +x) and environment variables (DYLD_FRAMEWORK_PATH) to ensure the tool runs correctly within the app bundle.

Note: Because this app interacts with the file system and executes shell commands, it may require specific Sandbox entitlements or the removal of App Sandboxing depending on your distribution method.

## 👤 Author
Youssef Keram
Copyright: © 2025 All rights reserved.

## 📄 License
This tool is provided as-is. Please ensure you comply with the Sparkle Framework's license when using the bundled binary.

---

## 📂 Project Structure

```text
SparkleUpdater/
├── SparkleUpdaterApp.swift  # Application Entry Point
├── ContentView.swift        # Main Logic & UI
│   ├── Data Models          # Project struct & Persistence
│   ├── View Models          # AppViewModel
│   ├── Views                # NavigationSplitView, ProjectDetailView
│   └── Helpers              # ShellRunner (Binary Wrapper), XMLInjector
├── Assets.xcassets          # App Icons and Colors
└── sign_update              # Bundled binary for generating signatures


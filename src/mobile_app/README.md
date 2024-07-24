# incubapp_lite

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## run this app in linux 
Follow this instructions 

### install required packages 
Install the following packages: curl, git, unzip, xz-utils, zip, libglu1-mesa

$ sudo apt-get update -y && sudo apt-get upgrade -y;
$ sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

To develop Linux apps, use the following command to install these packages:
clang, cmake, ninja-build, pkg-config, libgtk-3-dev, libstdc++-12-dev

```bash
$ sudo apt-get install \
        clang cmake git \
        ninja-build pkg-config \
        libgtk-3-dev liblzma-dev \
        libstdc++-12-dev
```

### install codium and flutter pluggins

Launch Codium and install the pluggin.
the pluggin is named "Flutter from Dart Code at dartcode.org"

To open the Command Palette, press Control + Shift + P.

In the Command Palette, type flutter.

Select Flutter: New Project.

VS Code prompts you to locate the Flutter SDK on your computer.

    If you have the Flutter SDK installed, click Locate SDK.

    If you do not have the Flutter SDK installed, click Download SDK.

    This option sends you the Flutter install page if you have not installed Git as directed in the development tools prerequisites.

ref: https://docs.flutter.dev/get-started/install/linux/desktop 

## Launch the app 
open main.dart 
Press F5 and enable Linux platform 
Errors may appear...
Press F5 again and vuala 


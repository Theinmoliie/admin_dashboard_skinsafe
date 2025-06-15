#!/bin/bash

# Exit on error
set -e

# Install Flutter
echo "Cloning Flutter repository..."
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable $HOME/flutter
export PATH="$HOME/flutter/bin:$PATH"

# Run flutter doctor
echo "Running flutter doctor..."
flutter doctor -v

# Enable web
echo "Enabling web..."
flutter config --enable-web

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build the web app with environment variables
echo "Building Flutter web..."
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_KEY=$SUPABASE_KEY

echo "Build finished."
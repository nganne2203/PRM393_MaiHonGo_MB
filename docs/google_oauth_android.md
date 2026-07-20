# Android Google OAuth Setup

`PlatformException(sign_in_failed, ApiException: 10)` means Google Play
Services could not find an OAuth Android client that matches this app build.
This project does not need Firebase for Google login.

## Required Google Cloud config

1. In Google Cloud Console, open APIs & Services > Credentials.
2. Create or update an OAuth client with type `Android`.
3. Use this package name:

   ```text
   com.example.maihongo_mb
   ```

4. Add the debug signing certificate fingerprint for the machine running the
   emulator. You can print it with:

   ```bash
   keytool -list -v \
     -alias androiddebugkey \
     -keystore ~/.android/debug.keystore \
     -storepass android \
     -keypass android
   ```

5. Keep `.env` configured with the Web OAuth client ID:

   ```text
   GOOGLE_WEB_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com
   ```

The Android OAuth client authorizes the installed app package/signing
certificate. The Web OAuth client ID is passed as `serverClientId`, so Google
returns an ID token that your backend can verify.

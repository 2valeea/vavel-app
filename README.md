# Release build notes (Vavel)

## Android signing (do not lose)

- Keystore file: `c:\Users\vvlav\VAVEL\vavel_app\android\upload-keystore.jks`
- `keyAlias`: `upload`
- `storePassword`: `123456`
- `keyPassword`: `123456`
- `key.properties` path: `c:\Users\vvlav\VAVEL\vavel_app\android\key.properties`

Current `key.properties` values:

```properties
storePassword=123456
keyPassword=123456
keyAlias=upload
storeFile=../upload-keystore.jks
```

## Build release APK

From `c:\Users\vvlav\VAVEL\vavel_app`:

```powershell
flutter build apk --release
```

Output:

`c:\Users\vvlav\VAVEL\vavel_app\build\app\outputs\flutter-apk\app-release.apk`

## Helius API key (local secret)

- Local secret file: `c:\Users\vvlav\VAVEL\vavel_app\.env`
- Variable name: `HELIUS_API_KEY`
- App config reads this key from `.env` in `vavel_app/lib/config.dart`.
- `.env` is ignored by git in both `vavel_app/.gitignore` and root `.gitignore`.

Example `.env` format:

```env
HELIUS_API_KEY=YOUR_HELIUS_API_KEY
```


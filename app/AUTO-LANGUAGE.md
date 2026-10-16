# Automatic language selection

Startup language priority:

1. A valid user choice saved at `HKCU\Software\StadiaStudio\Language`.
2. The current Windows UI culture when no valid saved choice exists.
3. English when the Windows UI culture is unsupported.

Supported automatic mappings:

- `zh-CN`, `zh-SG`, and `zh-Hans*` -> `zh-CN`
- `es-*` -> `es`
- `en-*` -> `en`
- `fr-*` -> `fr`
- `de-*` -> `de`
- all other values, including Traditional Chinese, -> `en`

The application and installer compile the same `I18n.cs`, so both use the same
first-run behavior. Manual language selection remains persistent and takes
priority over future system-language changes.

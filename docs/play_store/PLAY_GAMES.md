# Google Play Games (optional, not enabled in this repo)

Offline `CloudSave` is implemented and source-of-truth. To ship true Google
cloud save + Play leaderboards:

1. Create an Android app in **Google Play Console**, package
   `com.panipurisimulator.game`, matching signing key.
2. Enable **Google Play Games services**, create an OAuth 2.0 Android client,
   add your SHA-1.
3. Add the Godot Android **Google Play Games** plugin under `addons/`
   (not vendored here; no network/credentials in this environment).
4. Configure `plugin.cfg`, manifest metadata, and Play Console **Cloud save**
   + **Leaderboards** IDs (e.g. `best_day_profit`, `most_served_day`,
   `most_tips_day`).
5. Replace `CloudSave.publish_play_games()` to call the plugin:
   - `PlayGames.save_snapshot()` / `PlayGames.load_snapshot()`
   - `PlayGames.unlock_leaderboard()` / `PlayGames.submit_score()`
   - `PlayGames.sign_in()`
6. Keep offline backup/code import as fallback.

**Status in this repo:** offline backup, shareable save code, and local
leaderboards are working; Play Games cloud sync is a documented hook, not
verified against a real Google account.

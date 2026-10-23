# Putting the game on your iPhone (free Apple ID)

You need: a Mac with Xcode signed in to your Apple ID, your iPhone with
Developer Mode on, and a cable between them. No paid developer account.

## 1. Download

**https://github.com/fg29cw8knf-wq/covenant-war/releases/download/iphone/CovenantWar-iOS.zip**

This link always gives the newest build. It is rebuilt by itself every time
the game's `main` branch changes (it takes a few minutes). The page
https://github.com/fg29cw8knf-wq/covenant-war/releases/tag/iphone says when
it was built.

Safari puts it in **Downloads** and usually unzips it into a folder called
**CovenantWar**. If you see `CovenantWar-iOS.zip` instead, double-click it.

## 2. Open it in Xcode

In the **CovenantWar** folder, double-click **CovenantWar.xcodeproj**.
Xcode opens it.

## 3. Choose your Apple ID as the team

1. In Xcode's left-hand column, click the blue **CovenantWar** icon at the very top.
2. In the middle, under **TARGETS**, click **CovenantWar**.
3. Click the **Signing & Capabilities** tab.
4. Make sure **Automatically manage signing** is ticked.
5. Click the **Team** menu and choose **your name (Personal Team)**.
   - If you see two sections, **Signing (Debug)** and **Signing (Release)**,
     you have a download from before 15 October 2026, 18:30. Download it again
     (step 1), or choose your team in both sections and then, on the **Build
     Settings** tab, search for `Code Signing Identity` and set **Release** to
     **Apple Development**.
   - Not in the list? Choose **Add an Account…**, sign in with your Apple ID,
     close that window and pick it from **Team** again.
6. Wait a few seconds. The red errors under Signing should clear.
   - If one says the bundle identifier "is not available" or "cannot be
     registered", change **Bundle Identifier** to something only you would
     use, e.g. `com.yourname.covenantwar`, and press Return.

## 4. Plug in the iPhone

1. Connect the iPhone to the Mac with the cable and unlock it.
2. If the phone asks **Trust This Computer?**, tap **Trust** and enter your passcode.
3. At the top of the Xcode window, in the middle, click the device name
   (next to **CovenantWar**) and choose **your iPhone** from the list.
   The first time, Xcode may show "Preparing iPhone…" for a few minutes.
   Wait for it to finish.

## 5. Press Run

Click the **▶** button at the top left (or press **⌘R**).

- The first build takes a few minutes. The game engine is large.
- If the Mac asks for your **login password** so "codesign" can use a key,
  type your Mac password and click **Always Allow**.

## 6. Trust the app on the iPhone (first time only)

The first time, Xcode says it **couldn't launch** the app and the phone says
**Untrusted Developer**. That's expected:

1. On the iPhone open **Settings → General → VPN & Device Management**.
2. Under **Developer App**, tap your Apple ID (your email address).
3. Tap **Trust "your email"**, then **Trust** again.
4. Back on the Mac, press **▶** again. Or tap **The Covenant War** on the
   phone's home screen.

Turn the phone sideways and play.

**For the smoothest play:** once it's installed, press **■** (Stop) in Xcode
and open the game from the home screen. Running from Xcode attaches a
debugger that slows things down.

## Getting a fresh build when the game updates

1. Download the same link again (step 1). Delete the old **CovenantWar** folder first.
2. Do steps 2, 3 and 5 again. You need to choose the team each time,
   because it's a new project. You don't need to trust it on the phone again.

The new build installs over the old one, and your saved game stays. The
title screen's **Early build** line (bottom right) shows when the build was
made, so you can see you have the new one.

## Things a free Apple ID does

- **The app stops opening after 7 days.** Plug in, open the project and press
  **▶** again to renew it. Your save stays.
- At most 3 apps from a free account can be on the phone at once.

## About quality

The app runs the game at full quality, the same as the Mac version: Godot's
Forward+ renderer with the village's full lighting (global illumination,
volumetric fog, the densest grass) and all the art inside the app. Nothing
downloads while you play. If a long session makes the phone hot or jerky,
say so: the phone can be switched to Godot's lighter Mobile renderer in one
line.

Since 23 October the app also carries the opening film at its full 4K and
60 frames a second (about 420 MB of the download) and plays it through the
phone's own video player, with a Skip of its own when you tap. If the film
ever won't play, the app falls back to the smaller copy the phone link uses,
so the game still opens. Tell Gary's session which you saw.

## How it's built

`tools/build_ios.sh` (needs Godot 4.7.2 with export templates; runs on Linux
or a Mac) makes `build/CovenantWar-iOS.zip`. The GitHub workflow
`.github/workflows/iphone.yml` runs it on every change to `main` and puts the
zip on the `iphone` release. To make one straight away, open the repository's
**Actions** tab, choose **iPhone app** and click **Run workflow**.

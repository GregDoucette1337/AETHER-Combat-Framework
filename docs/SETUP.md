# Roblox Studio installation & showcase checklist

## Script types and placement

- `ReplicatedStorage/AbilityConfig.luau` → **ModuleScript** `AbilityConfig`
- `ReplicatedStorage/AetherV3Config.luau` → **ModuleScript** `AetherV3Config`
- `ServerScriptService/AbilityServer.luau` → **Script** `AbilityServer`
- `ServerScriptService/AetherV3Server.luau` → **Script** `AetherV3Server`
- `ServerScriptService/DemoArena.luau` → **Script** `DemoArena` (optional)
- `ServerScriptService/AetherV3Arena.luau` → **Script** `AetherV3Arena` (optional)
- `StarterPlayer/StarterPlayerScripts/AbilityClient.luau` → **LocalScript** `AbilityClient`
- `StarterPlayer/StarterPlayerScripts/AetherV3Client.luau` → **LocalScript** `AetherV3Client`

**Do not run both arena generators at once.** You can set one Script's `Enabled` property to `false` in Roblox Studio.

## Testing

1. Save a backup of your `.rbxl` place before replacing scripts.
2. Start **Play** (not Run), and watch the Output panel.
3. Test Arc Slash and Thunder Strike on a dummy.
4. Test double jump, air dash, slide, and blink in free space and near walls.
5. Test Gravity Well and Meteor Barrage on multiple targets.
6. Open **Test → Server & Clients** to check replication with two players.
7. Review cooldowns and hit registration. Do not describe the code as exploit-proof or production-ready without security testing.

## Recording a gameplay video

- Use OBS Studio or Windows Game Bar; capture **your actual Roblox Studio gameplay**, not concept art.
- Record at 1080p if performance allows; turn on the target health bars and ability HUD.
- Suggested 50–65 second flow: title (3 sec), Arc Slash/Thunder Strike (12 sec), traversal (15 sec), Gravity Well (12 sec), Meteor Barrage (15 sec), ending card (5 sec).
- Export an MP4, upload to YouTube, then replace the recording-pending note in the root README with its real URL.
- Add 2–3 true in-game screenshots under `assets/` and reference them in the README.

## Portfolio copy

**Headline:** Roblox Gameplay Scripter & Systems Developer

**Short bio:** Roblox gameplay developer working with Luau, combat mechanics, movement systems, and client–server gameplay. I also bring project-coordination experience. Open to scoped commissions.

**Featured project title:** AETHER — Combat & Movement Framework (Prototype)

**Short featured description:** Luau-based Roblox combat and traversal prototype with eight abilities, client-side effects, server-side validations and a training arena. Personal, AI-assisted technical demonstration.

**Skills:** Luau · Roblox Studio · RemoteEvents · Combat mechanics · Movement · Procedural VFX · UI · Testing

Keep claims limited to functionality tested in your current Studio build. Separate prototype work from previous paid commissions.

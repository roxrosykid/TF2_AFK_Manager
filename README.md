# [TF2] AFK Manager

## Description

**[TF2] AFK Manager** is a SourceMod that plugin monitors player activity and notifies others when a player goes AFK.

Additionally, it can display an AFK message above the player's head, making it easy for other players to identify who is inactive.

![image](https://github.com/user-attachments/assets/d813271d-9bec-4190-85e5-0ef1881e2a6d)
Typical dustbowl gameplay.

## Features

- **AFK Detection**: Automatically detects when a player has been inactive for a specified period.
- **AFK Notifications**: Sends a message to the chat when a player goes AFK or returns from being AFK.
- **AFK Text Entities**: Displays a floating "AFK" text and a timer above the AFK player's head.
- **Customizable Settings**: Allows server administrators to configure the AFK time threshold and toggle the display of AFK messages and text entities.

## Installation

1. **Download the Plugin**: Grab the [latest release](https://github.com/roxrosykid/TF2_AFK_Manager/releases/latest). 
2. **Upload the Plugin**: Place the `.smx` file in the `addons/sourcemod/plugins/` directory.

## Usage

The plugin comes with several ConVars that can be configured to customize its behavior:
- **ConVars**:
  - `sm_afk_time`: Sets the time in seconds before a player is considered AFK. Default is `300.0` seconds (5 minutes).
  - `sm_afk_message`: Toggles the display of AFK message notifications in the chat. `1` for enabled, `0` for disabled. Default is `1`.
  - `sm_afk_text`: Toggles the display of text entities above AFK players. `1` for enabled, `0` for disabled. Default is `1`.

### Example Configuration

```cfg
sm_afk_time "300.0"
sm_afk_message "1"
sm_afk_text "1"
```

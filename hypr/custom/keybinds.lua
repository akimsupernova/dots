-- User keybinds

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[sh -c '"$HOME/.config/quickshell/scripts/brightness.sh" up']]))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[sh -c '"$HOME/.config/quickshell/scripts/brightness.sh" down']]))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 2%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"))

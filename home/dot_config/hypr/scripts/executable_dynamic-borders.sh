#!/usr/bin/env bash
# https://github.com/devadathanmb/hyprland-smart-borders
#
# Diverges from upstream: every `hyprctl dispatch setprop address:X noborder N`
# in it has been dead since the Hyprland 0.55 Lua migration, so this script
# silently did nothing at all. Two independent breakages, both fixed by the
# helper below:
#
#   * `hyprctl dispatch` evaluates a LUA EXPRESSION now (`return hl.dispatch(…)`),
#     so hyprlang-style arguments are a syntax error — exit 7, every call. Note
#     the namespace is hl.dsp.window.set_prop; hl.window.set_prop is nil.
#   * the `noborder` prop no longer exists. `border_size` replaced it, and it
#     takes an integer. Hiding a border is size 0; the literal "unset" drops the
#     override so the window falls back to graphics.lua's `border_size`, which is
#     better than restoring a hardcoded 1.
#
# Beware that a bad prop name only errors once the window actually resolves — a
# call with a bogus address returns "ok" regardless, so probe with a real one.
#
# $1 = window address (with the 0x prefix), $2 = hide|show
function border {
    local size
    case "$2" in
        hide) size=0 ;;
        *) size=unset ;;
    esac
    hyprctl dispatch "hl.dsp.window.set_prop({ prop = 'border_size', value = '$size', window = 'address:$1' })"
}

function handle {
    if [[ ${1:0:10} == "openwindow" ]]
    then
        window_id=$(echo $1 | cut --delimiter ">" --fields=3 | cut --delimiter "," --fields=1)
        workspace_id=$(echo $1 | cut --delimiter ">" --fields=3 | cut --delimiter "," --fields=2)
        if [[ $workspace_id == "special" ]]
        then
            workspace_id=-99
        fi
        windows=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id) | .windows")

        if [[ $windows -eq 1 ]]
        then
            floating_status=$(hyprctl clients -j | jq ".[] | select(.address == \"0x$window_id\" ) | .floating" )
            if [[ $floating_status == "false" ]]
            then
                border "0x$window_id" hide
            else
                border "0x$window_id" show
                return
            fi

        elif [[ $windows -eq 2 ]]
        then
            addresses=$(hyprctl clients -j | jq -r --arg foo "$foo" ".[] | select(.workspace.id == $workspace_id) | .address")
            for address in $addresses
            do
                if [[ "$address" != "$window_id" ]]; then
                    border "$(echo $address | xargs)" show
                fi
            done
        fi

    elif [[ ${1:0:10} == "movewindow"  ]]
    then
        window_id=$(echo $1 | cut --delimiter ">" --fields=3 | cut --delimiter "," --fields=1)
        workspace_id=$(echo $1 | cut --delimiter ">" --fields=3 | cut --delimiter "," --fields=2)

        # Sepcial workspaces have an id of -99, they need to be handled separately
        if [[ $workspace_id == "special" ]]
        then
            workspace_id=-99
        fi

        windows=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id) | .windows")

        if [[ $windows -eq 1 ]]
        then
            # Check if the current window is floating and then set the border accordingly
            floating_status=$(hyprctl clients -j | jq ".[] | select(.address == \"0x$window_id\" ) | .floating" )
            if [[ $floating_status == "false" ]]
            then
                border "0x$window_id" hide
            else
                border "0x$window_id" show
                return
            fi
        elif [[ $windows -eq 2 ]]
        then
            addresses=$(hyprctl clients -j | jq -r --arg foo "$foo" ".[] | select(.workspace.id == $workspace_id) | .address")
            for address in $addresses
            do
                if [[ "$address" != "$window_id" ]]; then
                    border "$(echo $address | xargs)" show
                fi
            done
        fi

        # Handle all the other workspaces with only one window
        single_window_workspaces=$(hyprctl workspaces -j | jq '.[] | select(.windows == 1)' | jq ".id")
        for workspace in $single_window_workspaces
        do
            window=$(hyprctl clients -j | jq ".[] | select(.workspace.id == $workspace) | .address")
            border "$(echo $window | xargs)" hide
        done

    elif [[ ${1:0:11} == "closewindow" ]]
    then
        workspace_id=$(hyprctl activewindow -j | jq ".workspace.id")
        windows=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id) | .windows")

        if [[ $windows -eq 1 ]]
        then
            window_id=$(hyprctl activewindow -j | jq -r ".address")
            floating_status=$(hyprctl activewindow -j | jq ".floating")
            if [[ $floating_status == "false" ]]
            then
                border "$window_id" hide
            else
                border "$window_id" show
                return
            fi

        fi

    elif [[ ${1:0:18} == "changefloatingmode" ]]
    then
        floating_status=$(echo $1 | cut --delimiter ">" --fields 3 | cut --delimiter "," --fields 2)
        address="0x$(echo $1 | cut --delimiter ">" --fields 3 | cut --delimiter "," --fields 1)"
        workspace_id=$(hyprctl clients -j | jq --arg address "$address" '.[] | select(.address == $address) | .workspace.id')
        if [[ $floating_status -eq 1 ]]
        then
            border "$address" show
        else
            no_windows=$(hyprctl workspaces -j | jq ".[] | select(.id == $workspace_id) | .windows")
            if [[ $no_windows -eq 1 ]]
            then
                border "$address" hide
            else
                border "$address" show
            fi
        fi
    fi
}

# Socket directory has changed in Hyprland v0.40.0
# socat - UNIX-CONNECT:/tmp/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | while read line; do handle $line; done
socat -U - UNIX-CONNECT:$(echo $XDG_RUNTIME_DIR)/hypr/$(echo $HYPRLAND_INSTANCE_SIGNATURE)/.socket2.sock | while read line; do handle $line; done

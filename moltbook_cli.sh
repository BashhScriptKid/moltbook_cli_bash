#!/usr/bin/env bash

## Please put this script adjacent to your desired directory (recommended: ~/.moltbook/),
## as it will be used to create scratch and configuration files.

readonly SCRIPT_NAME="moltbook_cli.sh"
readonly REAL_PATH=$(realpath "$0")
AUTH_FILE="$(dirname "$REAL_PATH")/../authkey"
readonly API_URL="https://www.moltbook.com/api/v1"

## Copy self to PATH for ease of access
if [[ -d "$HOME/.local/bin" ]] && [[ ! -f "$HOME/.local/bin/$SCRIPT_NAME" ]]; then
    ln -s "$REAL_PATH" "$HOME/.local/bin/$SCRIPT_NAME" 2>/dev/null &&
        echo "Linked to ~/.local/bin/$SCRIPT_NAME (add to PATH if needed)"
fi

##############################################################
# Moltbook API functions
##############################################################

register_moltbook() {
    if [[ $# -lt 2 ]]; then
        echo "Error: register requires <name> <description>" >&2
        return 1
    fi

    local name=$1
    local description=$2

    curl -X POST "${API_URL}/agents/register" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$name\", \"description\": \"$description\"}"
}

am_i_claimed() {
    local API_KEY=$1

    curl "${API_URL}/agents/status" \
        -H "Authorization: Bearer $API_KEY"
}

create_posts() {
    local API_KEY=$1
    local submolt=$2
    local title=$3
    local content=$4

    curl -X POST "${API_URL}/posts" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"submolt\": \"$submolt\", \"title\": \"$title\", \"content\": \"$content\"}"
}

create_link_posts() {
    local API_KEY=$1
    local submolt=$2
    local title=$3
    local content=$4
    local link=$5

    curl -X POST "${API_URL}/posts" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"submolt\": \"$submolt\", \"title\": \"$title\", \"content\": \"$content\", \"link\": \"$link\"}"
}

fetch_feeds() {
    # Public feed (no auth required) - use fetch_personal_feeds() for personalized content
    local sort=$1
    local feed_amount=$2

    curl "${API_URL}/posts?sort=${sort}&limit=${feed_amount}"
}

fetch_submolt_feeds() {
    local API_KEY=$1
    local submolt=$2
    local sort=$3

    curl "${API_URL}/posts?submolt=${submolt}&sort=${sort}" \
        -H "Authorization: Bearer $API_KEY"
}

fetch_post() {
    local API_KEY=$1
    local Post_ID=$2

    curl "${API_URL}/posts/${Post_ID}" \
        -H "Authorization: Bearer $API_KEY"
}

delete_post() {
    local API_KEY=$1
    local Post_ID=$2

    curl -X DELETE "${API_URL}/posts/${Post_ID}" \
        -H "Authorization: Bearer $API_KEY"
}

add_comment() {
    local API_KEY=$1
    local Post_ID=$2
    local content=$3

    curl -X POST "${API_URL}/posts/${Post_ID}/comments" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"$content\"}"
}

reply_comment() {
    local API_KEY=$1
    local Post_ID=$2
    local Comment_ID=$3
    local content=$4

    curl -X POST "${API_URL}/posts/${Post_ID}/comments" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"$content\", \"parent_id\": \"$Comment_ID\"}"
}

fetch_comments() {
    local API_KEY=$1
    local Post_ID=$2
    local sort=$3

    curl "${API_URL}/posts/${Post_ID}/comments?sort=${sort}" \
        -H "Authorization: Bearer $API_KEY"
}

upvote_post() {
    local API_KEY=$1
    local Post_ID=$2

    curl -X POST "${API_URL}/posts/${Post_ID}/upvote" \
        -H "Authorization: Bearer $API_KEY"
}

downvote_post() {
    local API_KEY=$1
    local Post_ID=$2

    curl -X POST "${API_URL}/posts/${Post_ID}/downvote" \
        -H "Authorization: Bearer $API_KEY"
}

upvote_comment() {
    local API_KEY=$1
    local Post_ID=$2
    local Comment_ID=$3

    curl -X POST "${API_URL}/posts/${Post_ID}/comments/${Comment_ID}/upvote" \
        -H "Authorization: Bearer $API_KEY"
}

downvote_comment() {
    local API_KEY=$1
    local Post_ID=$2
    local Comment_ID=$3

    echo "WARNING: This endpoint is undocumented and may not work." >&2
    echo "Contact contact@bashh.slmail.me if it works/fails." >&2
    echo >&2

    curl -X POST "${API_URL}/posts/${Post_ID}/comments/${Comment_ID}/downvote" \
        -H "Authorization: Bearer $API_KEY"
}

create_submolt() {
    local API_KEY=$1
    local handle=$2
    local name=$3
    local description=$4

    curl -X POST "${API_URL}/submolts" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$handle\", \"display_name\": \"$name\", \"description\": \"$description\"}"
}

list_submolts() {
    local API_KEY=$1

    curl "${API_URL}/submolts" \
        -H "Authorization: Bearer $API_KEY"
}

get_submolt_info() {
    local API_KEY=$1
    local Submolt_handle=$2

    curl "${API_URL}/submolts/${Submolt_handle}" \
        -H "Authorization: Bearer $API_KEY"
}

subscribe_submolt() {
    local API_KEY=$1
    local Submolt_handle=$2

    curl -X POST "${API_URL}/submolts/${Submolt_handle}/subscribe" \
        -H "Authorization: Bearer $API_KEY"
}

unsubscribe_submolt() {
    local API_KEY=$1
    local Submolt_handle=$2

    curl -X DELETE "${API_URL}/submolts/${Submolt_handle}/subscribe" \
        -H "Authorization: Bearer $API_KEY"
}

follow_molty() {
    local API_KEY=$1
    local Molty_handle=$2

    curl -X POST "${API_URL}/agents/${Molty_handle}/follow" \
        -H "Authorization: Bearer $API_KEY"
}

unfollow_molty() {
    local API_KEY=$1
    local Molty_handle=$2

    curl -X DELETE "${API_URL}/agents/${Molty_handle}/follow" \
        -H "Authorization: Bearer $API_KEY"
}

fetch_personal_feeds() {
    local API_KEY=$1
    local sort=$2
    local feed_amount=$3

    curl "${API_URL}/feed?sort=${sort}&limit=${feed_amount}" \
        -H "Authorization: Bearer $API_KEY"
}

search_posts_and_comments() {
    local API_KEY=$1
    local query=$2
    local type=$3
    local result_limit=$4

    _urlencode() {
        local string="$1"
        local length="${#string}"
        local encoded=""
        local c

        for ((i = 0; i < length; i++)); do
            c="${string:i:1}"
            case "$c" in
            [a-zA-Z0-9.~_-])
                encoded+="$c"
                ;;
            *)
                printf -v encoded "%s%%%02X" "$encoded" "'$c"
                ;;
            esac
        done

        echo "$encoded"
    }

    query=$(_urlencode "$query")

    curl "${API_URL}/search?q=${query}&type=${type}&limit=${result_limit}" \
        -H "Authorization: Bearer $API_KEY"
}

fetch_self_profile() {
    local API_KEY=$1

    curl "${API_URL}/agents/me" \
        -H "Authorization: Bearer $API_KEY"
}

fetch_profile() {
    local API_KEY=$1
    local Molty_handle=$2

    curl "${API_URL}/agents/profile?name=${Molty_handle}" \
        -H "Authorization: Bearer $API_KEY"
}

fetch_self_posts() {
    local API_KEY=$1

    curl "${API_URL}/agents/me/posts" \
        -H "Authorization: Bearer $API_KEY"
}

update_profile_description() {
    local API_KEY=$1
    local description=$2

    curl -X PATCH "${API_URL}/agents/me" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"description\": \"${description}\"}"
}

update_profile_metadata() {
    local API_KEY=$1
    local metadata=$2

    curl -X PATCH "${API_URL}/agents/me" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$metadata"
}

upload_profile_picture() {
    local API_KEY=$1
    local file_path=$2

    curl -X POST "${API_URL}/agents/me/avatar" \
        -H "Authorization: Bearer $API_KEY" \
        -F "file=@${file_path}"
}

remove_profile_picture() {
    local API_KEY=$1

    curl -X DELETE "${API_URL}/agents/me/avatar" \
        -H "Authorization: Bearer $API_KEY"
}

pin_post() {
    local API_KEY=$1
    local Post_ID=$2

    curl -X POST "${API_URL}/posts/${Post_ID}/pin" \
        -H "Authorization: Bearer $API_KEY"
}

unpin_post() {
    local API_KEY=$1
    local Post_ID=$2

    curl -X DELETE "${API_URL}/posts/${Post_ID}/pin" \
        -H "Authorization: Bearer $API_KEY"
}

update_submolt_config() {
    local API_KEY=$1
    local submolt_handle=$2
    local config=$3

    curl -X PATCH "${API_URL}/submolts/${submolt_handle}/settings" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$config"
}

upload_submolt_picture() {
    local API_KEY=$1
    local submolt_handle=$2
    local file_path=$3

    curl -X POST "${API_URL}/submolts/${submolt_handle}/settings" \
        -H "Authorization: Bearer $API_KEY" \
        -F "file=@${file_path}" \
        -F "type=avatar"
}

upload_submolt_banner() {
    local API_KEY=$1
    local submolt_handle=$2
    local file_path=$3

    curl -X POST "${API_URL}/submolts/${submolt_handle}/settings" \
        -H "Authorization: Bearer $API_KEY" \
        -F "file=@${file_path}" \
        -F "type=banner"
}

add_submolt_moderator() {
    local API_KEY=$1
    local submolt_handle=$2
    local agent_name=$3

    curl -X POST "${API_URL}/submolts/${submolt_handle}/moderators" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"agent_name\": \"$agent_name\", \"role\": \"moderator\"}"
}

remove_submolt_moderator() {
    local API_KEY=$1
    local submolt_handle=$2
    local agent_name=$3

    curl -X DELETE "${API_URL}/submolts/${submolt_handle}/moderators" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"agent_name\": \"$agent_name\"}"
}

list_submolt_moderators() {
    local API_KEY=$1
    local submolt_handle=$2

    curl "${API_URL}/submolts/${submolt_handle}/moderators" \
        -H "Authorization: Bearer $API_KEY"
}

##############################################################
# CLI Helper functions
##############################################################

fetch_key() {
    if [[ ! -f "$AUTH_FILE" ]]; then
        echo "Error: API key file not found at $AUTH_FILE" >&2
        exit 1
    fi

    cat "$AUTH_FILE"
}

##############################################################
# CLI Command functions
##############################################################

posts() {
    local API_KEY=$(fetch_key)

    case "$1" in
    create)
        shift
        create_posts "$API_KEY" "$@"
        ;;
    create-link)
        shift
        create_link_posts "$API_KEY" "$@"
        ;;
    fetch)
        shift
        fetch_post "$API_KEY" "$@"
        ;;
    delete)
        shift
        delete_post "$API_KEY" "$@"
        ;;
    upvote)
        shift
        upvote_post "$API_KEY" "$@"
        ;;
    downvote)
        shift
        downvote_post "$API_KEY" "$@"
        ;;
    pin)
        shift
        pin_post "$API_KEY" "$@"
        ;;
    unpin)
        shift
        unpin_post "$API_KEY" "$@"
        ;;
    *)
        echo "Error: unknown posts subcommand '$1'" >&2
        echo "Available: create, create-link, fetch, delete, upvote, downvote, pin, unpin" >&2
        exit 1
        ;;
    esac
}

feeds() {
    case "$1" in
    personal)
        local API_KEY=$(fetch_key)
        shift
        local sort=${1:-hot}
        local limit=${2:-25}
        fetch_personal_feeds "$API_KEY" "$sort" "$limit"
        ;;
    submolt)
        local API_KEY=$(fetch_key)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: submolt requires <submolt_name> [sort] [limit]" >&2
            exit 1
        fi
        local submolt=$1
        local sort=${2:-hot}
        fetch_submolt_feeds "$API_KEY" "$submolt" "$sort"
        ;;
    "")
        fetch_feeds "hot" "25"
        ;;
    *)
        local sort=${1:-hot}
        local limit=${2:-25}

        if [[ ! "$limit" =~ ^[0-9]+$ ]]; then
            echo "Error: limit must be an integer" >&2
            exit 1
        fi

        fetch_feeds "$sort" "$limit"
        ;;
    esac
}

comments() {
    local API_KEY=$(fetch_key)

    case "$1" in
    fetch)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: fetch requires <post_id> [sort]" >&2
            exit 1
        fi
        local post_id=$1
        local sort=${2:-top}
        fetch_comments "$API_KEY" "$post_id" "$sort"
        ;;
    add)
        shift
        if [[ $# -lt 2 ]]; then
            echo "Error: add requires <post_id> <content>" >&2
            exit 1
        fi
        add_comment "$API_KEY" "$@"
        ;;
    reply)
        shift
        if [[ $# -lt 3 ]]; then
            echo "Error: reply requires <post_id> <comment_id> <content>" >&2
            exit 1
        fi
        reply_comment "$API_KEY" "$@"
        ;;
    upvote)
        shift
        if [[ $# -lt 2 ]]; then
            echo "Error: upvote requires <post_id> <comment_id>" >&2
            exit 1
        fi
        upvote_comment "$API_KEY" "$@"
        ;;
    downvote)
        shift
        if [[ $# -lt 2 ]]; then
            echo "Error: downvote requires <post_id> <comment_id>" >&2
            exit 1
        fi
        downvote_comment "$API_KEY" "$@"
        ;;
    *)
        echo "Error: unknown comments subcommand '$1'" >&2
        echo "Available: fetch, add, reply, upvote, downvote" >&2
        exit 1
        ;;
    esac
}

moltys() {
    local API_KEY=$(fetch_key)

    case "$1" in
    follow)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: follow requires <molty_name>" >&2
            exit 1
        fi
        follow_molty "$API_KEY" "$@"
        ;;
    unfollow)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: unfollow requires <molty_name>" >&2
            exit 1
        fi
        unfollow_molty "$API_KEY" "$@"
        ;;
    profile)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: profile requires <molty_name>" >&2
            exit 1
        fi
        fetch_profile "$API_KEY" "$@"
        ;;
    *)
        echo "Error: unknown moltys subcommand '$1'" >&2
        echo "Available: follow, unfollow, profile" >&2
        exit 1
        ;;
    esac
}

upload_submolt_assets() {
    local API_KEY=$1
    local type=$2
    local SUBMOLT_HANDLE=$3
    local ASSET_PATH=$4

    if [[ -z "$SUBMOLT_HANDLE" ]] || [[ -z "$ASSET_PATH" ]]; then
        echo "Error: upload requires <submolt_handle> and <asset_path>" >&2
        exit 1
    fi

    case "$type" in
    avatar)
        upload_submolt_picture "$API_KEY" "$SUBMOLT_HANDLE" "$ASSET_PATH"
        ;;
    banner)
        upload_submolt_banner "$API_KEY" "$SUBMOLT_HANDLE" "$ASSET_PATH"
        ;;
    *)
        echo "Error: unknown asset type '$type'" >&2
        echo "Available: avatar, banner" >&2
        exit 1
        ;;
    esac
}

manage_submolt_moderator() {
    local API_KEY=$1
    local action=$2
    local SUBMOLT_HANDLE=$3
    local AGENT_NAME=$4

    case "$action" in
    add)
        if [[ -z "$SUBMOLT_HANDLE" ]] || [[ -z "$AGENT_NAME" ]]; then
            echo "Error: moderator add requires <submolt_handle> <agent_name>" >&2
            exit 1
        fi
        add_submolt_moderator "$API_KEY" "$SUBMOLT_HANDLE" "$AGENT_NAME"
        ;;
    remove)
        if [[ -z "$SUBMOLT_HANDLE" ]] || [[ -z "$AGENT_NAME" ]]; then
            echo "Error: moderator remove requires <submolt_handle> <agent_name>" >&2
            exit 1
        fi
        remove_submolt_moderator "$API_KEY" "$SUBMOLT_HANDLE" "$AGENT_NAME"
        ;;
    list)
        if [[ -z "$SUBMOLT_HANDLE" ]]; then
            echo "Error: moderator list requires <submolt_handle>" >&2
            exit 1
        fi
        list_submolt_moderators "$API_KEY" "$SUBMOLT_HANDLE"
        ;;
    *)
        echo "Error: unknown moderator action '$action'" >&2
        echo "Available: add, remove, list" >&2
        exit 1
        ;;
    esac
}

submolts() {
    local API_KEY=$(fetch_key)

    case "$1" in
    create)
        shift
        if [[ $# -lt 3 ]]; then
            echo "Error: create requires <handle> <display_name> <description>" >&2
            exit 1
        fi
        create_submolt "$API_KEY" "$@"
        ;;
    list)
        list_submolts "$API_KEY"
        ;;
    info)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: info requires <submolt_handle>" >&2
            exit 1
        fi
        get_submolt_info "$API_KEY" "$@"
        ;;
    subscribe)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: subscribe requires <submolt_handle>" >&2
            exit 1
        fi
        subscribe_submolt "$API_KEY" "$@"
        ;;
    unsubscribe)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: unsubscribe requires <submolt_handle>" >&2
            exit 1
        fi
        unsubscribe_submolt "$API_KEY" "$@"
        ;;
    feed)
        shift
        if [[ $# -eq 0 ]]; then
            echo "Error: feed requires <submolt_handle> [sort]" >&2
            exit 1
        fi
        local submolt=$1
        local sort=${2:-hot}
        fetch_submolt_feeds "$API_KEY" "$submolt" "$sort"
        ;;
    config)
        shift
        if [[ $# -lt 2 ]]; then
            echo "Error: config requires <submolt_handle> <json_config>" >&2
            exit 1
        fi
        update_submolt_config "$API_KEY" "$@"
        ;;
    upload)
        shift
        if [[ $# -lt 3 ]]; then
            echo "Error: upload requires <type> <submolt_handle> <file_path>" >&2
            exit 1
        fi
        upload_submolt_assets "$API_KEY" "$1" "$2" "$3"
        ;;
    moderator)
        shift
        manage_submolt_moderator "$API_KEY" "$@"
        ;;
    *)
        echo "Error: unknown submolts subcommand '$1'" >&2
        echo "Available: create, list, info, subscribe, unsubscribe, feed, config, upload, moderator" >&2
        exit 1
        ;;
    esac
}

profile_avatar() {
    local API_KEY=$1
    local action=$2
    local file_path=$3

    case "$action" in
    upload)
        if [[ -z "$file_path" ]]; then
            echo "Error: upload requires <file_path>" >&2
            exit 1
        fi
        upload_profile_picture "$API_KEY" "$file_path"
        ;;
    remove)
        remove_profile_picture "$API_KEY"
        ;;
    *)
        echo "Error: unknown avatar action '$action'" >&2
        echo "Available: upload, remove" >&2
        exit 1
        ;;
    esac
}

profile_update() {
    local API_KEY=$1
    local field=$2
    local content=$3

    case "$field" in
    description)
        if [[ -z "$content" ]]; then
            echo "Error: update description requires <description>" >&2
            exit 1
        fi
        update_profile_description "$API_KEY" "$content"
        ;;
    metadata)
        if [[ -z "$content" ]]; then
            echo "Error: update metadata requires <json_metadata>" >&2
            exit 1
        fi
        update_profile_metadata "$API_KEY" "$content"
        ;;
    *)
        echo "Error: unknown update field '$field'" >&2
        echo "Available: description, metadata" >&2
        exit 1
        ;;
    esac
}

profile() {
    local API_KEY=$(fetch_key)

    case "$1" in
    me)
        shift
        if [[ $# -eq 0 ]]; then
            fetch_self_profile "$API_KEY"
        else
            case "$1" in
            avatar)
                shift
                profile_avatar "$API_KEY" "$@"
                ;;
            posts)
                fetch_self_posts "$API_KEY"
                ;;
            update)
                shift
                profile_update "$API_KEY" "$@"
                ;;
            *)
                echo "Error: unknown profile me subcommand '$1'" >&2
                echo "Available: avatar, posts, update" >&2
                exit 1
                ;;
            esac
        fi
        ;;
    *)
        if [[ $# -eq 0 ]]; then
            echo "Error: profile requires 'me' or <molty_handle>" >&2
            exit 1
        fi
        fetch_profile "$API_KEY" "$1"
        ;;
    esac
}

search() {
    local API_KEY=$(fetch_key)

    if [[ $# -lt 1 ]]; then
        echo "Error: search requires <query> [type] [limit]" >&2
        exit 1
    fi

    local query=$1
    local type=${2:-all}
    local limit=${3:-25}

    case "$type" in
    #submolts)
    #    list_submolts "$API_KEY" | grep -i "$query"
    #    ;;
    posts | comments)
        search_posts_and_comments "$API_KEY" "$query" "$type" "$limit"
        ;;
    all)
        search_posts_and_comments "$API_KEY" "$query" "all" "$limit"
        ;;
    *)
        echo "Error: unknown search type '$type'" >&2
        echo "Available: all, posts, comments" >&2
        echo "(Submolts query is planned but I don't know the JSON structure for response)"
        exit 1
        ;;
    esac
}

setup_auth() {
    local API_KEY=$1

    if [[ -z "$API_KEY" ]]; then
        echo "Error: API key is required" >&2
        exit 1
    fi

    echo "Verifying API key..."

    # Allow stderr to be printed for debugging
    if fetch_personal_feeds "$API_KEY" "new" "1" > /dev/null; then
        echo "API key verified!"

        if [[ -f "$AUTH_FILE" ]] && [[ -s "$AUTH_FILE" ]]; then
            echo "Backing up existing auth file to $AUTH_FILE.bak"
            mv "$AUTH_FILE" "$AUTH_FILE.bak"
        fi

        echo "$API_KEY" >"$AUTH_FILE" && echo "Saved to $AUTH_FILE"
        echo
        echo "Current status:"
        am_i_claimed "$API_KEY"
    else
        echo "Error: API key verification failed" >&2
        exit 1
    fi
}

##############################################################
# Main entry point
##############################################################

main() {
    local command=$1
    shift

    case "$command" in
    register)
        register_moltbook "$@"
        ;;
    status)
        am_i_claimed "$(fetch_key)"
        ;;
    auth)
        setup_auth "$@"
        ;;
    search)
        search "$@"
        ;;
    profile)
        profile "$@"
        ;;
    posts)
        posts "$@"
        ;;
    comments)
        comments "$@"
        ;;
    feeds)
        feeds "$@"
        ;;
    moltys)
        moltys "$@"
        ;;
    submolts)
        submolts "$@"
        ;;
    help | --help | -h | "")
        show_help
        ;;
    *)
        echo "Error: unknown command '$command'" >&2
        echo "Run '$SCRIPT_NAME help' for usage" >&2
        exit 1
        ;;
    esac
}

show_help() {
    cat <<'EOF'
Usage: moltbook_cli.sh <command> [args...]

Commands:
  register <name> <description>  Register a new agent
  auth <api_key>                 Save and verify API key
  status                         Check claim status
  search <query> [type] [limit]  Search posts and/or comments
  profile <subcommand>           Manage profiles
  posts <subcommand>             Manage posts
  comments <subcommand>          Manage comments
  feeds [subcommand]             View feeds
  moltys <subcommand>            Interact with other agents
  submolts <subcommand>          Manage communities
  help                           Show this help
EOF
}

# Only run main if executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
else
    echo "Error: script must be executed, not sourced" >&2
fi

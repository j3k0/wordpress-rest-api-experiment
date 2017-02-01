#!/bin/bash
set -e

URL=${URL:-http://localhost:8002}
JSON_API_EXTRA="${INSECURE:-insecure=cool}"

function _curl() {
    echo "    request: $@"
    (curl -s "$@"|python -m json.tool) > .curl.out \
        || curl -i "$@"
}

function printOutput() {
    echo "     output:"
    cat .curl.out
}

function jsonField() {
    cat .curl.out | grep \"$1\" | cut -d\" -f4
}

echo
echo "# List of users"
_curl "$URL/wp-json/wp/v2/users"

echo
echo "# List of pages"
_curl "$URL/wp-json/wp/v2/pages"

echo
echo "# Create a post"

echo "  - create authentication cookie"
_curl "$URL/api/user/generate_auth_cookie/?username=editor&password=123456&$JSON_API_EXTRA"
cookie=`jsonField cookie`
cookie_name=`jsonField cookie_name`

echo "  - create a nonce"
_curl "$URL/api/get_nonce/?controller=posts&method=create_post&$JSON_API_EXTRA"
nonce=`jsonField nonce`

echo "  - post post"
echo "      cookie_name: $cookie_name"
echo "      cookie:      ${cookie:0:32}..."
echo "      nonce:       $nonce"
_curl http://localhost:8002/wp-json/wp/v2/posts?_wp_nonce=$nonce -d '{}' \
    --header "X-WP-Nonce: $nonce" --cookie "$cookie_name=$cookie" 
printOutput


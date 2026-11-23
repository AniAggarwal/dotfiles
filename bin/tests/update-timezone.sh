#!/usr/bin/env bash
set -euo pipefail

script=$(cd -- "$(dirname -- "$0")/../bin" && pwd)/update-timezone
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
export TEST_LOG="$test_dir/calls"

cat > "$test_dir/curl" <<'EOF'
#!/usr/bin/env bash
case "$TEST_CASE" in
    offline) exit 6 ;;
    fallback) [[ ${!#} == *ipinfo.io* ]] && exit 22 ;;
    malformed) printf '<html>error</html>'; exit 0 ;;
    invalid) printf '{"timezone":"../../etc/passwd"}'; exit 0 ;;
    api-error) printf '{"success":false,"timezone":{"id":"Asia/Kolkata"}}'; exit 0 ;;
esac
if [[ ${!#} == *ipwho.is* ]]; then
    printf '{"success":true,"timezone":{"id":"Asia/Kolkata"}}'
else
    printf '{"timezone":"Asia/Kolkata"}'
fi
EOF

cat > "$test_dir/timedatectl" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == list-timezones ]]; then
    printf 'America/Los_Angeles\nAsia/Kolkata\n'
else
    printf '%s\n' "$*" >> "$TEST_LOG"
    [[ $TEST_CASE != denied ]]
fi
EOF
chmod +x "$test_dir/curl" "$test_dir/timedatectl"
export PATH="$test_dir:$PATH"

for TEST_CASE in success fallback offline malformed invalid api-error denied; do
    export TEST_CASE
    : > "$TEST_LOG"
    status=0
    bash "$script" > "$test_dir/output" 2>&1 || status=$?
    case "$TEST_CASE" in
        success|fallback)
            [[ $status == 0 ]]
            [[ $(cat "$TEST_LOG") == 'set-timezone Asia/Kolkata' ]]
            grep -Fx 'New timezone: Asia/Kolkata' "$test_dir/output" >/dev/null
            ;;
        *)
            [[ $status != 0 ]]
            ! grep -q 'New timezone:' "$test_dir/output"
            if [[ $TEST_CASE != denied ]]; then
                [[ ! -s $TEST_LOG ]]
            fi
            ;;
    esac
    printf 'PASS %s\n' "$TEST_CASE"
done

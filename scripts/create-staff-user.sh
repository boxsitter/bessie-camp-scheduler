#!/usr/bin/env bash
# Creates a staff account (Supabase Auth user + profile) for Bessie.
#
# Public sign-up is disabled, so accounts are provisioned here with the
# service-role key. The database trigger `app.handle_new_user` turns the
# user's app_metadata into a `profiles` row.
#
#   scripts/create-staff-user.sh <email> <first-name> <last-name> <role> [password]
#
#   role      root | director | admin | counselor
#   password  optional; a random one is generated and printed if omitted
#
# Environment:
#   SUPABASE_URL                default http://127.0.0.1:54321 (local stack)
#   SUPABASE_SERVICE_ROLE_KEY   required (local: `supabase status -o env`; hosted:
#                               Project Settings > API). Keep it secret.
#   ORGANIZATION_ID             default: the only organization in the database
set -euo pipefail

if [[ $# -lt 4 || $# -gt 5 ]]; then
  sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
  exit 64
fi

email=$1 first=$2 last=$3 role=$4
password=${5:-$(python3 -c 'import secrets; print(secrets.token_urlsafe(12))')}
url=${SUPABASE_URL:-http://127.0.0.1:54321}
key=${SUPABASE_SERVICE_ROLE_KEY:?Set SUPABASE_SERVICE_ROLE_KEY (local: supabase status -o env)}

case $role in
  root | director | admin | counselor) ;;
  *) echo "role must be root, director, admin or counselor" >&2; exit 64 ;;
esac

org=${ORGANIZATION_ID:-}
if [[ -z $org ]]; then
  org=$(curl -fsS "$url/rest/v1/organizations?select=id" -H "apikey: $key" -H "Authorization: Bearer $key" |
    python3 -c 'import json,sys; rows=json.load(sys.stdin); sys.exit("expected exactly one organization; set ORGANIZATION_ID") if len(rows)!=1 else print(rows[0]["id"])')
fi

payload=$(python3 - "$email" "$password" "$first" "$last" "$role" "$org" <<'PY'
import json, sys
email, password, first, last, role, org = sys.argv[1:]
print(json.dumps({
    "email": email,
    "password": password,
    "email_confirm": True,
    "user_metadata": {"first_name": first, "last_name": last},
    "app_metadata": {"organization_id": org, "role": role},
}))
PY
)

response=$(curl -sS -w '\n%{http_code}' -X POST "$url/auth/v1/admin/users" \
  -H "apikey: $key" -H "Authorization: Bearer $key" -H 'Content-Type: application/json' -d "$payload")
status=${response##*$'\n'}
body=${response%$'\n'*}

if [[ $status != 200 && $status != 201 ]]; then
  echo "Could not create the user (HTTP $status): $body" >&2
  exit 1
fi

echo "Created $role $first $last <$email>"
echo "Password: $password"
echo "They can change it any time with 'Forgot password' on the login screen."

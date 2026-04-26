# Plan: Add Tag Protection to `JohannesBertens/power-platform-skills`

## Context

`gh skill publish` warned that no tag protection rulesets exist. Tag protection prevents anyone from moving or deleting a published tag (e.g., `v1.0.0`) to point to a different commit, which protects the integrity of `gh skill install --pin` workflows.

## Goal

Configure a repository ruleset that restricts who can create, update, or delete tags.

## Prerequisites

- GitHub Enterprise or GitHub Team plan (tag protection via rulesets is not available on GitHub Free for org-owned repos; for user-owned repos it is available)
- Admin access to `JohannesBertens/power-platform-skills`

## Steps

| # | Action | Detail |
|---|--------|--------|
| 1 | Check current rulesets | `gh api repos/JohannesBertens/power-platform-skills/rulesets` to see if any exist |
| 2 | Create a tag protection ruleset via GitHub API | Use `gh api` to POST a ruleset that restricts `v*` tag pattern to admins/maintainers only |
| 3 | Verify the ruleset | `gh api repos/JohannesBertens/power-platform-skills/rulesets` to confirm creation |
| 4 | Re-run `gh skill publish --dry-run` | Confirm the warning is gone |

## Ruleset Configuration

```json
{
  "name": "protect-skill-tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/v*"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "creation",
      "parameters": {
        "operator": "allowed"
      }
    },
    {
      "type": "update",
      "parameters": {
        "allowed": false
      }
    },
    {
      "type": "deletion",
      "parameters": {
        "allowed": false
      }
    }
  ],
  "bypass_actors": [
    {
      "actor_id": "<repo-admin-user-id>",
      "actor_type": "User",
      "bypass_mode": "always"
    }
  ]
}
```

This restricts:
- **Creating** tags matching `v*`: allowed (no restriction)
- **Updating** (force-pushing/moving) tags: blocked
- **Deleting** tags: blocked
- **Bypass**: repo admin only

## Alternative: GitHub Web UI

If API rulesets aren't available on your plan, tag protection patterns can also be set at:
**Settings → Tags → Tag protection rules → Add pattern `v*`**

This is a simpler feature available on all plans and restricts who can create/match tags to the `v*` pattern.

## Commands

```bash
# Step 1: Check existing rulesets
gh api repos/JohannesBertens/power-platform-skills/rulesets

# Step 2: Get the authenticated user's ID for bypass_actors
gh api user --jq '.id'

# Step 3: Create the ruleset
gh api repos/JohannesBertens/power-platform-skills/rulesets \
  -f name="protect-skill-tags" \
  -f target="tag" \
  -f enforcement="active" \
  -f conditions='{"ref_name":{"include":["refs/tags/v*"],"exclude":[]}}' \
  --input - <<'EOF'
{
  "name": "protect-skill-tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/tags/v*"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "update"
    },
    {
      "type": "deletion"
    }
  ],
  "bypass_actors": [
    {
      "actor_id": PLACEHOLDER_USER_ID,
      "actor_type": "User",
      "bypass_mode": "always"
    }
  ]
}
EOF

# Step 4: Verify
gh api repos/JohannesBertens/power-platform-skills/rulesets

# Step 5: Re-validate
gh skill publish --dry-run
```

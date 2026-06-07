# Publish to GitHub

One-time setup, then push.

## 1. Log in to GitHub (once)

```bash
gh auth login
```

Choose: **GitHub.com** → **HTTPS** (or SSH if you prefer) → authenticate in the browser.

## 2. Create the repo and push

From this folder:

```bash
cd ~/Projects/UCS-Multi-Toolkit
```

**Personal account:**

```bash
gh repo create ucs-multi-toolkit \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description "UCS naming and batch workflow for REAPER"
```

**Haptik Audio organization** (if you have access):

```bash
gh repo create haptikaudio/ucs-multi-toolkit \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description "UCS naming and batch workflow for REAPER"
```

If the remote already exists from a partial setup:

```bash
git remote add origin https://github.com/haptikaudio/ucs-multi-toolkit.git
git push -u origin main
```

## 3. Tag the release

```bash
git tag -a v1.0.0 -m "UCS Multi Toolkit v1.0.0"
git push origin v1.0.0
```

Then on GitHub: **Releases → Draft a new release** from tag `v1.0.0` and paste the `CHANGELOG.md` section.

## 4. ReaPack

Users import this repository URL in **Extensions → ReaPack → Import repositories**:

```
https://raw.githubusercontent.com/haptikaudio/ucs-multi-toolkit/main/index.xml
```

Package files live in `Workflow/`. When releasing a new version:

1. Update `@version` and `@changelog` in `Workflow/UCS Multi Toolkit.lua`
2. Update `index.xml` with the new version entry and commit hash URLs (or run `reapack-index` if installed)
3. Commit, push, and tag the release

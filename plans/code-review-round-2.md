# Implementation Plan: Code Review Round 2 Fixes

PRD: [#1](https://github.com/joeljose/Useful_scripts/issues/1)
Tracking: [#2](https://github.com/joeljose/Useful_scripts/issues/2)

All 5 phases are independent — no ordering constraints. Grouped by blast radius (broadest first).

---

## Phase 1: Autoremove error handling
**Issue**: #3
**Goal**: Wrap `sudo apt-get autoremove` with `if !` guard in all 15 scripts.
**Slice**: Mechanical find-and-replace across all uninstall functions.
**Files to touch**: All 15 `install-*.sh`
**Changes**:
```bash
# Before
sudo apt-get autoremove

# After
if ! sudo apt-get autoremove; then
    echo "Warning: autoremove failed. Some unused packages may remain."
fi
```
**Acceptance criteria**:
- `grep -c 'sudo apt-get autoremove' install-*.sh` → 0 bare calls remaining
- `grep -c 'if ! sudo apt-get autoremove' install-*.sh` → 15
- `shellcheck install-*.sh` → zero warnings
**Estimated complexity**: S

---

## Phase 2: SSH server status message
**Issue**: #4
**Goal**: Only show server status when user chose to start it.
**Slice**: Move the `server:` echo line inside the start block in `install-ssh.sh`.
**Files to touch**: `install-ssh.sh`
**Changes**:
- Move `echo "  server: $(sudo systemctl is-active ssh)"` from the unconditional verify block into the `if [[ "$start_ssh" == [yY] ]]` branch, after the `systemctl start` succeeds.
- The `else` branch already prints "SSH server installed but not enabled" — no change needed there.
**Acceptance criteria**:
- Declining server start → output has no "server:" line
- Accepting server start → output shows "server: active"
- `shellcheck install-ssh.sh` → passes
**Estimated complexity**: S

---

## Phase 3: fzf uninstall .bashrc cleanup
**Issue**: #5
**Goal**: Replace fragile multi-line sed with line-by-line deletion + trailing blank line cleanup.
**Slice**: Rewrite the sed block in `uninstall_fzf()`.
**Files to touch**: `install-fzf.sh`
**Changes**:
```bash
# Before
sed -i -e '/^$/N;/\n# fzf keybindings/d' -e '\|source /usr/share/doc/fzf/examples/key-bindings.bash|d' "$HOME/.bashrc"

# After
sed -i '/^# fzf keybindings/d' "$HOME/.bashrc"
sed -i '\|source /usr/share/doc/fzf/examples/key-bindings.bash|d' "$HOME/.bashrc"
# Remove trailing blank lines at EOF
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$HOME/.bashrc"
```
**Acceptance criteria**:
- After uninstall: no `# fzf keybindings` line in `.bashrc`
- After uninstall: no `source .../key-bindings.bash` line in `.bashrc`
- After uninstall: no trailing blank lines at EOF
- `shellcheck install-fzf.sh` → passes
**Estimated complexity**: S

---

## Phase 4: gh post-install login message
**Issue**: #6
**Goal**: Use `if !` pattern instead of `||` for consistency with `login_gh()`.
**Slice**: Rewrite the login offer at the bottom of `install-gh.sh`.
**Files to touch**: `install-gh.sh`
**Changes**:
```bash
# Before (line 165)
gh auth login || echo "Login skipped. Run '$0 --login' later."

# After
if ! gh auth login; then
    echo "Login skipped. Run '$0 --login' later."
fi
```
**Acceptance criteria**:
- No `||` pattern for login in the file
- Cancelling login → "Login skipped" message
- `shellcheck install-gh.sh` → passes
**Estimated complexity**: S

---

## Phase 5: Update CI actions/checkout
**Issue**: #7
**Goal**: Eliminate Node.js 20 deprecation warning by updating to v6.
**Slice**: Single line change in CI workflow.
**Files to touch**: `.github/workflows/shellcheck.yml`
**Changes**:
```yaml
# Before
- uses: actions/checkout@v4

# After
- uses: actions/checkout@v6
```
**Acceptance criteria**:
- CI passes after push
- No Node.js deprecation annotation in the Actions run
**Estimated complexity**: S

---

## Risks
None — all changes are small, independent, and easily reversible. ShellCheck CI validates correctness on push.

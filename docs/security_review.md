# Security review

Focus: `rw` mounts and host impact on macOS / Docker Desktop.

## Threat model

A malicious (or compromised) npm package, JAR, Python script, or agent-generated command runs **inside** the container and tries to:

- read, delete, or encrypt files on the host
- reach `~/Documents` or other personal folders
- persist or escalate

## Current volume map (relevant parts)

| Host path | Container path | Mode | Risk if malicious code runs |
|-----------|----------------|------|-----------------------------|
| `${HOST_PROJECT_DIR}` | `/workspace` | **rw** | Full read/write/delete/encrypt of the project |
| `./.vibe-home` | `/home/node/.vibe-home` | **rw** | Low (only sandbox-local state) |
| `${HOST_NPM_CACHE}` → usually `~/.npm` | `/home/node/.npm` | **rw** | **Cache poisoning** of host npm |
| `${HOST_GRADLE_DIR}` → `~/.gradle` | `/home/node/.gradle` | **rw** | **Cache / plugin poisoning** |
| `${HOST_M2_DIR}` → `~/.m2` | `/home/node/.m2` | **rw** | **Cache / artifact poisoning** |
| `${HOST_SSH_DIR}` → `~/.ssh` | `/home/node/.ssh` | ro | Keys readable; cannot modify them |
| host Oh My Zsh + `.zshrc` | … | ro | No write |

Nothing under `~/Documents`, `~/Desktop`, `~/Library`, etc. is mounted. **A process inside the container cannot see or touch those paths** unless you deliberately set `HOST_PROJECT_DIR` (or another mount) to a parent of them.

## What a malicious npm/JAR *can* and *cannot* do

### Can do

1. **Destroy or encrypt the project**  
   Anything under `HOST_PROJECT_DIR` is fully writable. Ransomware-style encryption or `rm -rf` of the project is possible.

2. **Poison host caches** (the biggest indirect host impact today)  
   Because `~/.npm`, `~/.m2` and `~/.gradle` are bind-mounted `rw`:
   - A malicious `postinstall` can write trojaned packages/artifacts into the host cache.
   - Later, when you run `npm` / Maven / Gradle **on the host**, you may execute that code outside the container.

3. **Exfiltrate secrets**  
   - All LLM API keys present in the container environment.
   - Any secrets, tokens, or `.env` files that live inside `HOST_PROJECT_DIR`.
   - Contents of `~/.ssh` (private keys are readable).

4. **Use the network**  
   Full outbound internet (needed for LLMs). Data can leave easily.

5. **Talk to host MCP servers**  
   Via `host.docker.internal`. Depending on what the IntelliJ/VS Code MCP tools allow, an agent could be steered into harmful IDE actions. This is a tool-permission issue more than a container-escape issue.

### Cannot do (under normal Docker Desktop on macOS)

- Reach arbitrary host paths that are not bind-mounted (`~/Documents`, other projects, system files).
- Directly execute macOS binaries or call macOS APIs.
- Modify the ro-mounted SSH keys or Oh My Zsh files.
- Escape the Linux VM that Docker Desktop uses (practical container escapes exist in theory; they are outside the “malicious npm package” threat model for most people).

Docker Desktop’s file-sharing settings add a second layer: only paths you have allowed in Docker Desktop → Settings → Resources → File sharing can be mounted at all.

## Main design strengths

- Project mount is the intentional trust boundary.
- Home directory is **not** mounted as a whole.
- SSH is read-only.
- Process runs as non-root (uid 1000).

## Main weaknesses

1. **Host package caches mounted `rw`** → cache-poisoning path back onto the host.
2. **No defense-in-depth** around the project mount (no `no-new-privileges`, no dropped caps, rootfs not read-only).
3. **Broad network + secrets in environment** → easy exfiltration if the agent or a package is malicious.
4. **User error**: setting `HOST_PROJECT_DIR=$HOME` (or a parent of Documents) would expose everything.

## Practical hardening recommendations (ordered by impact)

### 1. Stop sharing host package caches (highest priority)

Replace the three host bind mounts with **named Docker volumes** (or paths under the sandbox only):

```yaml
volumes:
  - ${HOST_PROJECT_DIR}:${CONTAINER_WORK_DIR:-/workspace}:rw
  - ./.vibe-home:/home/node/.vibe-home:rw
  - ./.vibe-home/.bash_profile:/home/node/.bash_profile:ro
  - ${HOST_SSH_DIR}:/home/node/.ssh:ro
  - ${HOST_OH_MY_ZSH}:/home/node/.oh-my-zsh:ro
  - ${HOST_ZSHRC}:/home/node/.zshrc:ro

  # Isolated caches – never touch host ~/.npm, ~/.m2, ~/.gradle
  - vibe-npm:/home/node/.npm
  - vibe-gradle:/home/node/.gradle
  - vibe-m2:/home/node/.m2

volumes:
  vibe-npm:
  vibe-gradle:
  vibe-m2:
```

Result: a malicious package can only poison caches that live inside Docker. Host `npm` / Maven / Gradle stay clean.

### 2. Keep `HOST_PROJECT_DIR` narrow

Always point it at a single repository. Never at `$HOME`, `~/Documents`, or a parent folder that contains other projects.

### 3. Add basic container hardening (low cost)

```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
# Optionally re-add only what you really need, e.g.:
# cap_add: [CHOWN, SETGID, SETUID]   # rarely needed for node
```

### 4. Reduce secret exposure

- Prefer passing only the keys the current agent actually needs.
- Avoid putting long-lived cloud credentials into the container environment if the agent can run arbitrary code.

### 5. npm-specific hygiene (when installing untrusted packages)

- Prefer `npm ci` with a committed lockfile.
- For truly untrusted packages consider `npm install --ignore-scripts` first, or install in a throw-away container that has no project mount.

### 6. Optional stronger isolation

- Run the agent container with a more restricted network (or an egress proxy) if you want to limit exfiltration.
- For maximum paranoia: do not mount SSH keys at all; use HTTPS remotes + credential helper on the host, or a short-lived deploy key that can only push to one repo.

## Bottom line

| Goal | Current status | What to change |
|------|----------------|----------------|
| Prevent access to `~/Documents` etc. | Already protected (not mounted) | Keep `HOST_PROJECT_DIR` narrow |
| Prevent deletion/encryption of personal files | OK as long as project dir is narrow | Same |
| Prevent host cache poisoning via npm/JAR | **Vulnerable today** | Switch caches to named volumes |
| Prevent project ransomware | Possible by design | Accept for the project, or use snapshots/Time Machine |
| Prevent secret exfiltration | Possible (env + project files) | Minimize secrets in the container |

The strongest single improvement is **#1 – stop bind-mounting `~/.npm`, `~/.m2` and `~/.gradle`**. That closes the main realistic path from “malicious package inside the sandbox” back onto the host outside the project directory.

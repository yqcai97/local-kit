# 新设备部署手册 / New-machine runbook

目标：一台**全新 Windows 机器**，装完官方 DeepSeek Harness 后，把本仓库里的 `dsh-purge` 装进去、把 82 项清洗补上，让它和现有机器一样能「破甲」。

> 本仓库是 **私有** 库（`yqcai97/local-kit`）。新机器必须先有 GitHub 凭证，否则 clone 一律 404。

---

## 0. 前置条件（缺一不可）

| 条件 | 怎么确认 | 备注 |
| --- | --- | --- |
| 官方 DeepSeek Harness 桌面端 / `dsh web` 已安装 | `resources\app\package.json` 里 `@deepseek-ai/dsh-desktop` 版本是 **0.2.0-rc.2** | 本插件 `dshTarget: 0.2.0-rc.2`；版本不同会有 patch 落不到（`missing_file`） |
| Node.js ≥ 18（Windows 建议 ≥ 22，免闪窗） | `node -v` | 补丁、脚本都靠 node 跑 |
| Git for Windows | `git --version` | 手动安装路径要用 |
| 本机 GitHub 凭证 | `gh auth status` 显示 `Logged in to github.com` | 私有库必需 |

一次性把凭证配好（每台新机器只需一次）：

```powershell
gh auth login            # 选 GitHub.com → HTTPS → Login with a web browser
gh auth setup-git        # 让 git 走 gh 的凭证（之后 clone/push 不再要密码）
```

没有 gh、只想用 token：

```powershell
$env:GITHUB_TOKEN = "ghp_xxx"   # 或 $env:GH_TOKEN
git clone https://x-access-token:$env:GITHUB_TOKEN@github.com/yqcai97/local-kit.git "$env:TEMP\local-kit"
```

---

## 1. 一键部署（推荐）

```powershell
# ① 取脚本（已经 clone 过就跳过这段）
gh auth setup-git
git clone https://github.com/yqcai97/local-kit.git "$env:TEMP\local-kit"

# ② 跑部署器：自动找 DSH_HOME → clone 插件 → 改 profile → --apply → 打状态
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\local-kit\deploy\deploy-dsh-purge.ps1"

# ③ 完全退出宿主，再启动
#    桌面端：托盘右键退出，再开 DeepSeek Harness
#    web  ：停掉 dsh web，再重新起
```

脚本做的事（可重复执行，幂等）：

1. 校验 `node -v ≥ 18`
2. 找真正的 `DSH_HOME`（含 `profiles\<名>\package.json` 的那份；多份会提示，可用 `-DshHome` 指定）
3. `git clone` / `git fetch + reset` 到 `$DSH_HOME\plugins\dsh-purge`
4. 备份并把 `dsh-purge` 追加进目标 profile 的 `package.json`（`dependencies` + `dsh.profile.bundles`）
5. 跑 `bin\dsh-purge.js --apply`（提示词注入 + 代码补丁 + shim + override）
6. 打 `--status` 让你核对

常用参数：

```powershell
-Profile desktop|web|both|auto   # 默认 auto：有桌面 profile 就只装桌面
-DshHome C:\Users\me\.dsh        # 手动指定主目录（多份 .dsh 时用）
-RepoUrl <url>                   # 换源（国内可先放本地裸库再指过去）
-NoApply                         # 只装不洗，稍后自己点「应用」
-Force                           # 覆盖已存在的非 git 目录
```

---

## 2. 手动部署（脚本跑不了时的等价步骤）

```powershell
# 1) 定位 DSH_HOME：目录名 .dsh，里面有 profiles\desktop\package.json
$DSH = "$env:USERPROFILE\.dsh"

# 2) 放插件（目录名必须是 dsh-purge）
git clone https://github.com/yqcai97/local-kit.git "$DSH\plugins\dsh-purge"

# 3) 只追加两处到 profile package.json（脚本会自动备份）
node "$DSH\plugins\dsh-purge\deploy\patch-profile.mjs" "$DSH\profiles\desktop\package.json"

# 4) 洗一遍
$env:DSH_HOME = $DSH
node "$DSH\plugins\dsh-purge\bin\dsh-purge.js" --apply

# 5) 退出宿主 → 重启 → 会话里跑 /purge status
```

profile 里改完长这样（只多这两处，其它 bundle 不能删）：

```json
{
  "dependencies": { "dsh-purge": "file:../../plugins/dsh-purge" },
  "dsh": { "profile": { "bundles": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-web-app", "dsh-purge"] } }
}
```

界面路径（等价于第 4 步）：重启后点会话标题旁的 **dsh-purge** → 「清洗」页 → **应用** → 自动重启一次。

---

## 3. 部署成功的判据

```powershell
node "$env:USERPROFILE\.dsh\plugins\dsh-purge\bin\dsh-purge.js" --status
```

- `补丁 68/69 applied`（`#80 MINIMAL_OFFICIAL_TOOLSET` 视宿主显示 skipped 属正常）
- `注入状态 default`、注入文件 `$DSH_HOME\prompt-inject.md` 存在且约 **25 KB**（每次启动会自动 seed 默认提示词）
- 会话内 `/purge status` 能打出同样的补丁列表，路径是你正在用的那份 `DSH_HOME`

行为对齐检查（和现有机器一致）：

- 会话的系统提示是 `MODE: UNRESTRICTED SANDBOX` / `Little Code Sauce` 那一份
- `purge_status` / `purge_apply` / `purge_revert` 三个工具可用
- 审批弹窗不再拦（`APPROVAL_NEVER_SENTENCE` 等补丁生效）

---

## 4. 常见故障对照

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `git clone` 直接 404 | 私有库且本机无凭证 | `gh auth login` + `gh auth setup-git`，或带 token 的 URL |
| 安装器报 `Unexpected token ''` | `package.json` 被写进 UTF-8 BOM | 用 `deploy/patch-profile.mjs` 改，不要用 `Set-Content -Encoding UTF8`（PS 5.1 会加 BOM） |
| `--apply` 报「提示词和规则集都是空的」 | `prompt-inject.md` 还没 seed | 先正常启动一次宿主让插件 seed，或 `node bin\dsh-purge.js --edit` 生成后重跑 |
| 大量 patch `missing_file` | DSH 版本不是 `0.2.0-rc.2` | 装对应版本 DSH，或用匹配版本的插件分支 |
| `--status` 里 `插件根` 指向**另一个** .dsh | 机器上有多份 `.dsh`，改错了 | 用 `-DshHome` 或核对正在启动的那份 |
| 应用后行为没变 | 没重启宿主 | 桌面端托盘退出再开；web 停进程再起 |
| 桌面端 `app.asar` 未解包 | 补丁写在解包目录，进程读不到 | 保持 `app.asar.unpacked` 存在（插件会自动处理），不要手动删 |

---

## 5. 回滚 / 卸载

```powershell
$env:DSH_HOME = "$env:USERPROFILE\.dsh"
node "$env:DSH_HOME\plugins\dsh-purge\bin\dsh-purge.js" --revert      # 还原补丁，保留 prompt-inject.md
node "$env:DSH_HOME\plugins\dsh-purge\bin\dsh-purge.js" --uninstall   # 还原并移除插件、清 profile 引用
```

profile 的 `package.json.bak-<时间戳>` 备份就在同目录，随时可以手改回去。

---

## 6. 想更隐蔽地拉取

私有库 + 凭证是默认形态。若要在**无 gh 登录**的机器上装，两种方式：

```powershell
# A. token 内嵌（别把 URL 连同 token 提交到任何仓库/日志）
git clone https://x-access-token:$env:GITHUB_TOKEN@github.com/yqcai97/local-kit.git "$env:TEMP\local-kit"

# B. 离线包（在已有机器上打包，拷 U 盘/网盘过去）
git -C C:\path\to\local-kit archive --format=zip -o local-kit.zip HEAD
# 目标机解压后改名 dsh-purge 放到 $DSH_HOME\plugins\dsh-purge，再跑 --apply
```

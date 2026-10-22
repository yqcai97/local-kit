# 来源与完整性记录 / Provenance

本仓库是 `dsh-purge` **v1.1.71** 的完整源码快照，来自上游原始 Git 仓库归档，现作为**私有**的个人维护分支保存（仓库名已改为中性的 `local-kit`，包名/代码保持 `dsh-purge` 原样）。

## 本仓库（私有）

| 项目 | 值 |
| --- | --- |
| 仓库（**私有**） | `https://github.com/yqcai97/local-kit` |
| 旧地址 | `https://github.com/yqcai97/dsh-purge` → 已改名，匿名访问一律 404（GitHub 侧保留重定向，但目标私有） |
| 默认分支 | `master` |
| 快照提交 | `2ea506705c7255d5f403d365af34688d7f29e558`（原始未改动快照） |
| 后续提交 | `57a0f6a` 来源说明；`6e17ff0` 安装源重指；`b583566` 公开期文档；`a9fbf9c` 改名；`c4ad17f` 去 BOM；之后仅文档 |
| Tag | `v1.1.71`（原始快照）、`v1.1.71-fork.1`、`v1.1.71-fork.2` |
| 文件数 | 106（104 个上游源码文件 + `.gitignore` + 本文件） |
| 匿名可访问 | 否：仓库页 / `raw` / `codeload` / `api` 实名探测全部 **404** |

安装（需本机有 GitHub 凭证）：

```bash
# 方式一：本机已 gh auth login 且 gh auth setup-git（git 走 gh credential helper）
dsh plugin add github:yqcai97/local-kit

# 方式二：clone 后本地装（最稳，不依赖安装器如何解析私有库）
git clone https://github.com/yqcai97/local-kit.git
dsh plugin add ./local-kit

# 方式三：带 token 的 tarball
curl -L -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/yqcai97/local-kit/tarball/master -o local-kit.tgz
dsh plugin add ./local-kit.tgz
```

> 私有库关键点：`github:owner/repo` 简写最终由 git 向 GitHub 取包，**能不能装取决于本机 git 凭证**。本机已 `gh auth setup-git`（`credential.https://github.com.helper = !gh auth git-credential`），所以匿名 shell 里 `pnpm add github:yqcai97/local-kit` 也能成功——那是凭证在起作用，不是库公开。没凭证的机器一律拿到 404。

> URL 修正说明：上游原 `package.json` 的 `dsh.install.tarball/zip/git` 三处都指向已 404 的 `YuJunZhiXue/dsh-purge`，已全部重指到本仓；`repository` / `homepage` / `bugs` 同步更新。**代码与资源文件一字未改**，仅元数据 URL。


## 上游原始信息

| 项目 | 值 |
| --- | --- |
| 原仓库 | `https://github.com/YuJunZhiXue/dsh-purge`（当前 **404**，已删除或转私有） |
| 原 npm 包 | `dsh-purge`（`registry.npmjs.org/dsh-purge` 当前 **404**，已取消发布） |
| 版本 | `1.1.71` |
| 提交 | `6c1d638d1bdcc45ede50fc30249c753d58122a51` |
| dshTarget | `0.2.0-rc.2` |
| 归档地址（原） | `https://codeload.github.com/YuJunZhiXue/dsh-purge/tar.gz/6c1d638d1bdcc45ede50fc30249c753d58122a51` |
| pnpm integrity | `sha512-B16L/Jht+6BfV09hBsI4Hkbk4XwqBdJO6D3/VkBQr2A2aVDsRJoS0k4p5ivyOzcjLHO+Y4fzse1RDvpfP9V2fQ==` |
| 本机安装时间 | 2026-10-17 18:38（`~/.dsh/profiles/desktop/node_modules/dsh-purge`） |
| 快照导出时间 | 2026-10-22 |

## 完整性校验

快照目录共 **104 个文件 / 3.43 MB**，逐文件 SHA-256 清单见
`backups/dsh-purge-1.1.71-manifest.txt`（工作区 `backups/` 目录）。

与社区镜像 `github.com/mmparko/dsh-purge@master`（同为 v1.1.71）逐文件哈希比对，以下文件全部 **MATCH**：

```
lib/index.js
lib/core.js
lib/redteam/tools.js
client.js
README.md
package.json
```

## 内容核对

- `lib/**/*.js`：未压缩 ESM 源码（非构建产物），可直接改、直接跑。
- `client.js`：由 `scripts/build-client.mjs` 从 `lib/redteam/client.js` 嵌入生成，可重建。
- `presets/redteam`、`skills/redteam`（22 个 skill）、`scripts/`、`docs/`、`README*.md`、`LICENSE` 齐全。
- 无 `test/` 目录、无 `.git` 历史：上游仓库本身没有测试脚本（`package.json.scripts` 仅 `embed-prompt` 与 `build:client`），历史随归档丢失。
- `lib/default-prompt-inject.md` 未包含：上游 `.gitignore` 明确排除该文件（嵌入前原文不进仓库），非丢失。

## 用途

```bash
# 从本私库直接安装
dsh plugin add github:<你的账号>/dsh-purge
# 或
dsh plugin add https://github.com/<你的账号>/dsh-purge/archive/refs/heads/master.tar.gz
```

## 许可证

上游 `LICENSE`（MIT 主体 + 二开署名要求）随源码一并保留，见仓库内 `LICENSE` 与 `README.md` 的署名要求部分。二开或分发前请按其条款保留署名。

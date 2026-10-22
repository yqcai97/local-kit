# 来源与完整性记录 / Provenance

本仓库是 `dsh-purge` **v1.1.71** 的完整源码快照，来自上游原始 Git 仓库归档，用于个人私库保存与维护。

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

# singbox_rules

一个用于收集 sing-box 规则集并将其编译为 `.srs` 二进制文件的最简仓库骨架。核心目标：

1. 将 `rules/` 目录下的 JSON 原始规则编译到 `dist/`。
2. 提供跨平台脚本，方便在本地或 CI/CD 环境运行。
3. 通过 GitHub Actions worker 自动化构建并输出编译结果。

## 文件结构

```
.
├── rules/                  # 存放 sing-box JSON 规则源文件，可按子目录拆分
│   ├── README.md           # 规则书写要求
│   └── sample.block.json   # 示例规则（version 3）
├── scripts/
│   ├── compile.sh          # Linux/macOS 入口，遍历规则并调用 sing-box CLI
│   └── compile.ps1         # Windows 入口
├── dist/                   # 输出 `.srs`（被 .gitignore 忽略）
├── .github/workflows/
│   └── compile.yml         # GitHub Actions worker，push/workflow_dispatch 自动编译
└── .gitignore
```

规则 JSON 必须符合官方格式：https://sing-box.sagernet.org/configuration/rule-set/source-format/  
> ⚠️ Rule-set Source 内的条目属于 *Headless Rule*，不能包含 `action`、`outbound` 等行为字段；这些字段应在引用 `.srs` 的主配置 `route.rules` 中定义。

## 本地编译

1. 安装 [sing-box](https://github.com/SagerNet/sing-box/releases) 并确保可通过 `sing-box` 命令调用。
2. 根据系统选择脚本：

```bash
# Linux / macOS
chmod +x scripts/compile.sh
scripts/compile.sh rules dist
```

```powershell
# Windows PowerShell
./scripts/compile.ps1 -SourceDir rules -OutputDir dist
```

脚本会保证：

- 自动创建 `dist/` 目录并保持子目录结构。
- 每个 `*.json` 会输出同名 `.srs`。
- 若缺少 sing-box 或无 JSON 源文件会直接报错。

## GitHub Actions Worker

`.github/workflows/compile.yml` 说明：

- 触发条件：`main` 分支的规则/脚本/workflow 变动或手动 `workflow_dispatch`。
- 运行环境：`ubuntu-latest`。
- 步骤：
  1. `actions/checkout` 获取仓库。
  2. `actions/setup-go` 安装 Go 1.22。
  3. `go install github.com/SagerNet/sing-box/cmd/sing-box@latest` 安装 CLI 并加入 PATH。
  4. 执行 `scripts/compile.sh`，生成全部 `.srs`。
  5. 使用 `actions/upload-artifact` 上传 `dist/**/*.srs`，供下载或后续发布使用。

如需将产物发布为 Release，可在 workflow 中追加 `actions/create-release` 或 `softprops/action-gh-release`。

## 扩展建议

- **多分支/多规则渠道**：可通过不同子目录（如 `rules/global`, `rules/cn`）管理，worker 中按路径矩阵构建。
- **版本锁定**：若需要固定 sing-box 版本，在脚本或 workflow 中改为下载指定 release 并缓存。
- **测试校验**：编译后可附加 `sing-box rule-set inspect` 或 `sing-box check`，在 CI 中提前拦截格式问题。

通过以上结构，即可在保持仓库整洁的同时，让所有规则经过统一的 worker 编译为可直接分发的 `.srs` 文件。

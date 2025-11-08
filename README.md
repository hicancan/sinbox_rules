# singbox_rules

这个仓库用来集中维护 sing-box 规则集，并把 `rules/` 下的 JSON 源文件编译成 `.srs` 二进制产物。核心目标：

1. 通过统一脚本快速在本地生成 `.srs`。
2. 借助 GitHub Actions 自动编译并把结果推送到远程 `dist` 分支，获得可直接下载的 URL。
3. 保持仓库结构清晰，方便后续扩展更多规则渠道。

## 文件结构

```
.
├── rules/                  # 规则源文件，可再建子目录
│   ├── README.md           # 规则编写注意事项
│   └── sample.block.json   # version=3 的示例
├── scripts/
│   ├── compile.sh          # Linux / macOS 脚本
│   └── compile.ps1         # Windows PowerShell 脚本
├── dist/                   # 编译输出目录（被 .gitignore 忽略）
├── .github/workflows/
│   └── compile.yml         # GitHub Actions worker
└── .gitignore
```

规则 JSON 必须符合官方格式：https://sing-box.sagernet.org/configuration/rule-set/source-format/  
> ⚠️ Rule-set Source 是 *Headless Rule*。不要在 JSON 中写 `action`、`outbound` 等字段 —— 这些行为字段应该在引用 `.srs` 的主配置 `route.rules` 里定义。

## 本地编译

1. 安装 [sing-box CLI](https://github.com/SagerNet/sing-box/releases) 并确保 `sing-box` 命令可用。
2. 根据系统选择脚本（参数：`<SourceDir> <OutputDir>`，默认为 `rules dist`）：

```bash
# Linux / macOS
chmod +x scripts/compile.sh
scripts/compile.sh rules dist
```

```powershell
# Windows PowerShell
./scripts/compile.ps1 -SourceDir rules -OutputDir dist
```

脚本会：

- 检查 sing-box CLI 是否存在。
- 递归收集 `*.json` 并保持子目录结构输出 `.srs`。
- 遇到异常（无源文件、编译失败等）直接退出并返回非 0 状态码。

## GitHub Actions Worker

`.github/workflows/compile.yml` 的主要流程：

1. `actions/checkout` 获取仓库。
2. `actions/setup-go` 安装 Go 1.22（禁用缓存，避免缺少 `go.sum` 的警告）。
3. `go install github.com/sagernet/sing-box/cmd/sing-box@latest`。
4. 执行 `scripts/compile.sh` 生成全部 `.srs`。
5. 使用 `peaceiris/actions-gh-pages` 把 `dist/` 推送到仓库的 `dist` 分支（`force_orphan: true`），从而得到稳定的远程 URL。
6. 额外保留 `actions/upload-artifact`，方便在 Actions 页面直接下载。

### 远程下载 URL

- **Raw 下载**：`https://raw.githubusercontent.com/<owner>/sinbox_rules/dist/<relative-path>.srs`
- **GitHub Pages（可选）**：在仓库 Settings → Pages 中选择 `dist` 分支即可启用，随后可通过 `https://<owner>.github.io/sinbox_rules/<relative-path>.srs` 访问。

示例：`rules/sample.block.json` 会在 dist 分支下生成为 `sample.block.srs`，对应地址为  
`https://raw.githubusercontent.com/<owner>/sinbox_rules/dist/sample.block.srs`

## 扩展建议

- 如果需要不同渠道/地区的规则，可在 `rules/` 下创建多层目录，脚本和 worker 会自动保持路径。
- 若要固定 sing-box 版本，可把安装命令改成具体 tag（例如 `@v1.12.12`）并视情况加缓存。
- 可在编译完成后追加 `sing-box rule-set inspect`、`sing-box check` 等验证步骤，提前发现错误。*** End Patch

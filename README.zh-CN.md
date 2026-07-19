<p align="center">
  <img src="assets/rm-airbag.svg" width="160" alt="rm-airbag 标志">
</p>

<h1 align="center">rm-airbag</h1>

<p align="center"><strong>给 macOS 的 <code>rm</code> 装一个安全气囊。</strong><br>
AI 删除的文件进入废纸篓，而不是永久消失。</p>

`rm-airbag` 是一个透明、Trash-first、失败即停止的 macOS `rm` 安全层。
它不要求 AI 安装插件、调用 Skill 或记住特殊命令。只要进程通过正常 `PATH`
解析普通 `rm`，就会自动经过同一层保护。

```text
AI 或人类执行： rm -rf important-project
                         ↓
PATH 实际找到： ~/.local/share/rm-airbag/shims/rm
                         ↓
macOS 真正执行：/usr/bin/trash important-project
```

如果文件无法进入废纸篓，它会留在原地，命令返回错误。项目不会把文件藏到
临时目录，也不会退回永久删除。

> [!IMPORTANT]
> `rm-airbag` 只保护经 `PATH` 解析的普通 `rm`。它不是沙箱，拦不住显式
> `/bin/rm`、`find -delete`、`git clean`、Python 文件 API 或其他删除机制。
> 使用前请阅读 [THREAT-MODEL.md](THREAT-MODEL.md)。

## 系统要求

- macOS 15.0 或更高版本（`/usr/bin/trash` 从 macOS 15 开始提供）
- `rm-airbag` 本身使用 Zsh
- shell 配置支持 Zsh、Bash 和 POSIX `sh`

## 使用 Homebrew 一键安装（推荐）

复制并粘贴下面这一整行即可：

```bash
brew install gy-0/tap/rm-airbag && rm-airbag enable && /bin/zsh -lic 'rm-airbag doctor'
```

Homebrew 会自动下载并校验 Release，不需要用户自己克隆仓库。最后一步会启动一个
新的 Zsh 登录环境并执行自检，确认 `rm` 已经由安全 shim 接管。

## 从源码一键安装

下面这一行会依次完成克隆、安装、启用和自检：

```bash
git clone --depth 1 https://github.com/gy-0/rm-airbag.git && ./rm-airbag/scripts/install.sh && /bin/zsh -lic 'rm-airbag doctor'
```

如果已经下载了源码，也可以在项目目录中执行：

```bash
./scripts/install.sh
/bin/zsh -lic 'rm-airbag doctor'
```

安装器会：

1. 把程序安装到 `~/.local/bin/rm-airbag`。
2. 在 `~/.local/share/rm-airbag/shims/` 创建名为 `rm` 的 shim。
3. 向 `.zshenv`、`.zprofile`、`.bash_profile` 和 `.profile` 添加带明确标记的
   `PATH` 配置块。
4. 修改前保留带时间戳的 shell 配置备份。

它不会修改系统 `/bin/rm`，也不会修改 `/System` 下的任何内容。

如果只想创建 shim、自己管理 `PATH`：

```bash
./scripts/install.sh --shim-only
```

然后把 shim 目录放到 `PATH` 最前面：

```bash
export PATH="$HOME/.local/share/rm-airbag/shims:$PATH"
```

## 验证是否真的生效

```bash
rm-airbag doctor
```

正常情况下会看到：

```text
PASS  Trash backend: /usr/bin/trash
PASS  rm shim: ~/.local/share/rm-airbag/shims/rm -> ~/.local/bin/rm-airbag
PASS  zsh login: ~/.local/share/rm-airbag/shims/rm
PASS  zsh non-login: ~/.local/share/rm-airbag/shims/rm
PASS  bash login: ~/.local/share/rm-airbag/shims/rm
PASS  sh login: ~/.local/share/rm-airbag/shims/rm
INFO  explicit /bin/rm and non-rm deletion APIs bypass PATH protection
```

只要 `doctor` 仍报告 critical failure，就不能认为安装完成。

## 正常使用

安装后继续照常使用 `rm`：

```bash
rm file.txt
rm -rf build/
rm -i notes.md
rm -- --strange-name
```

它保留常见 macOS `rm` 行为，包括：

- `-f`、`-i`、`-I`
- `-r` / `-R`
- `-d`
- `-v`
- `--` 和以 `-` 开头的文件名
- 文件不存在时的退出码
- 目录和符号链接处理

`-W` 和 `-x` 的原生语义无法由 Trash 移动诚实复现，因此会被安全拒绝；使用
这些选项时不会移动任何文件。

## 永久保护目标

即使传入 `-rf` 和 `--no-preserve-root`，以下目标仍会被拒绝：

- `/` 和当前用户 Home 根目录
- `/System`、`/Library`、`/Applications`、`/Users`
- `/bin`、`/usr`、`/etc`、`/private` 等常见系统根目录
- `/Volumes` 和其直接卷挂载根目录
- `.` 和 `..`

其他目标会进入 macOS 系统废纸篓。移动到废纸篓不等于释放磁盘空间，只有清空
废纸篓后空间才会真正释放。

## 管理命令

```text
rm-airbag enable [--shim-only]
rm-airbag disable
rm-airbag doctor
rm-airbag status
rm-airbag version
```

## 卸载

通过 Homebrew 安装：

```bash
rm-airbag disable && brew uninstall gy-0/tap/rm-airbag
```

通过源码安装：

```bash
./scripts/uninstall.sh
exec zsh -l
```

卸载器只移除自己的配置标记、shim 和安装的可执行文件。shell 配置备份会保留。

## 它不是什么

它是面向误操作和 AI 错误命令的安全网，不是抵抗恶意进程的系统安全边界。一个
拥有你账户权限的进程仍然可以显式调用其他删除接口或修改自己的环境。

推荐同时使用：

- Agent 沙箱和工作区限制
- 大范围文件访问审批
- Git 等版本控制
- Time Machine 或其他经过验证的备份

完整覆盖范围见 [THREAT-MODEL.md](THREAT-MODEL.md)。

## 开发与测试

```bash
make test
make package
```

测试使用带路径白名单的假 Trash 后端，不会拿 `/`、真实 Home 或系统路径做删除
实验。

## 许可证

MIT，见 [LICENSE](LICENSE)。

English: [README.md](README.md)

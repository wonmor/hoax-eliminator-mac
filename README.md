# 구라제거기 for Mac · Hoax Eliminator for Mac

> **한국어** 아래 · **English** below

한국 은행·카드사·관공서 사이트가 맥에 강제로 설치하는 "보안 프로그램"(키보드 보안, IP 수집기, 공인인증서 중계기, 통합 보안모듈 관리자…)을 한 번에 찾아서 지우는 macOS용 커맨드라인 도구입니다. 윈도우용 [구라제거기](https://teus.me/)에서 영감을 받아 처음부터 macOS용으로 만들었습니다. 원작자와는 관련이 없습니다.

A command-line tool that finds and removes the Korean "security" agents that banks, card companies and government sites force-install on macOS (keyboard encryptors, IP collectors, certificate relays, "integrated security-module managers"). Inspired by the Windows tool 구라제거기 (Hoax Eliminator). Independent reimplementation, not affiliated with the original author.

---

## 한국어

### 왜 필요한가요?

맥에서 국내 은행 사이트에 한 번 접속하면 아래 같은 프로그램들이 설치되어 **재부팅 후에도 root 권한 데몬으로 계속 실행**됩니다. 키 입력을 가로채고, 네트워크 환경을 수집하고, 브라우저 플러그인과 launchd 항목을 남깁니다. 지우려면 각 업체 삭제 프로그램을 하나씩 찾아 돌려야 하고, 그마저도 파일을 다 지우지 않는 경우가 많습니다.

이 도구는 알려진 프로그램 목록(카탈로그)을 기준으로 **앱 폴더, launchd 항목, 브라우저 플러그인, 프레임워크, 지원 파일, 설정 파일, 패키지 영수증, 실행 중인 프로세스**를 모두 찾아 한 번에 정리합니다.

### 설치 없이 바로 실행

```bash
# 1) 무엇이 설치되어 있는지 확인 (관리자 권한 불필요)
curl -fsSL https://raw.githubusercontent.com/wonmor/hoax-eliminator-mac/main/hoax-eliminator.sh | bash -s -- scan

# 2) 전부 삭제 (삭제 전에 한 번 물어봅니다)
curl -fsSL https://raw.githubusercontent.com/wonmor/hoax-eliminator-mac/main/hoax-eliminator.sh | sudo bash -s -- remove
```

파이프로 실행하는 게 꺼림칙하면 받아서 읽어보고 실행하세요. 의존성 없는 bash 스크립트 하나입니다.

```bash
git clone https://github.com/wonmor/hoax-eliminator-mac.git
cd hoax-eliminator-mac
./hoax-eliminator.sh scan
sudo ./hoax-eliminator.sh remove
```

### 사용법

| 명령 | 설명 |
|---|---|
| `scan` | 설치된 프로그램과 파일을 보여줍니다. 아무것도 지우지 않습니다. (기본값) |
| `scan --deep` | 카탈로그에 없는 의심 항목도 키워드로 찾아 보고합니다. 지우지는 않습니다. |
| `remove` | 발견된 프로그램을 전부 삭제합니다. `sudo` 필요. 삭제 전 확인을 받습니다. |
| `remove --yes` | 확인 없이 삭제합니다. |
| `remove --dry-run` | 무엇을 지울지 보여만 줍니다. |
| `remove --only astx,nxkey` | 지정한 것만 삭제합니다. (id는 `list` 참고) |
| `remove --keep anysign` | 지정한 것만 남기고 삭제합니다. |
| `list` | 카탈로그 전체를 보여줍니다. |
| `--ko` / `--en` | 메시지 언어. 기본값은 시스템 언어를 따릅니다. |

삭제 로그는 `/tmp/hoax-eliminator-날짜.log` 에 남습니다.

### 지우는 프로그램 (카탈로그)

| id | 프로그램 | 제조사 |
|---|---|---|
| `astx` | AhnLab Safe Transaction (ASTx) | 안랩 |
| `nxkey` | TouchEn nxKey (키보드 보안) | 라온시큐어 |
| `crosswebex` | INISAFE CrossWeb EX | 이니텍 |
| `crossex` | iniLINE CrossEX / CrossWarpEX (브라우저 중계) | 이니라인 |
| `veraport` | Veraport (통합 보안모듈 관리) | 위즈베라 |
| `delfino` | Delfino (인증서/전자서명) | 위즈베라 |
| `ipinside` | IPinside LWS Agent (IP/환경 수집) | 인터리젠 |
| `anysign` | AnySign4PC (인증서/전자서명) | 소프트포럼 (한컴위드) |
| `xecureweb` | XecureWeb Unified | 소프트포럼 |
| `nprotect` | nProtect Online Security | 잉카인터넷 |
| `magicline` | MagicLine4NX (인증서/전자서명) | 드림시큐리티 |
| `epagesafer` | ePageSafer / MaSaferJS (출력·화면 제어) | 마크애니 |
| `ksign` | KSign (KSignSWFT / CertRelay) | 케이사인 |
| `unisign` | UniSign / UniSignMulti | 한국전자인증 |
| `vestcert` | VestCert | 예티소프트 |
| `secukit` | SecuKit NX | SGA솔루션즈 |

위쪽 8개는 실제 설치된 맥에서 파일 경로를 하나하나 확인해 넣었습니다. 아래쪽은 업체 식별자(`com.dreamsecurity.*` 등)와 폴더 이름 패턴으로 찾으므로, 실제 설치본에서 경로를 확인해 주시면 ([이슈](https://github.com/wonmor/hoax-eliminator-mac/issues)) 바로 반영하겠습니다. `scan --deep` 결과를 붙여주시면 가장 좋습니다.

### 주의

- 지운 뒤 은행 사이트에 다시 들어가면 **다시 설치하라고 합니다.** 필요한 날에만 설치하고, 끝나면 다시 지우세요.
- 이 도구는 파일을 영구 삭제합니다. 걱정되면 `remove --dry-run` 으로 먼저 보세요.
- 업체 루트 인증서(키체인)는 건드리지 않습니다.
- macOS 10.13 이상, 기본 `/bin/bash` 3.2 에서 동작합니다. 추가 설치 없음.

---

## English

### Why

Visit one Korean bank site on a Mac and you end up with half a dozen "security" programs that keep running as **root daemons after every reboot**: keystroke interceptors, network-environment collectors, browser plugins, launchd jobs. Removing them means hunting down each vendor's uninstaller, and those often leave files behind.

This tool works from a catalog of known programs and cleans up **app folders, launchd daemons and agents, browser plugins, frameworks, support files, preference files, package receipts and running processes** in one pass.

### Run without installing

```bash
# 1) See what is installed (no admin rights needed)
curl -fsSL https://raw.githubusercontent.com/wonmor/hoax-eliminator-mac/main/hoax-eliminator.sh | bash -s -- scan

# 2) Remove everything found (asks for confirmation first)
curl -fsSL https://raw.githubusercontent.com/wonmor/hoax-eliminator-mac/main/hoax-eliminator.sh | sudo bash -s -- remove
```

If piping into `sudo bash` makes you uneasy, download it, read it, then run it. It is a single dependency-free bash script.

```bash
git clone https://github.com/wonmor/hoax-eliminator-mac.git
cd hoax-eliminator-mac
./hoax-eliminator.sh scan
sudo ./hoax-eliminator.sh remove
```

### Usage

| Command | What it does |
|---|---|
| `scan` | Lists installed programs and their files. Deletes nothing. (default) |
| `scan --deep` | Also reports suspects not in the catalog, matched by vendor keywords. Report only. |
| `remove` | Removes everything found. Needs `sudo`. Asks for confirmation. |
| `remove --yes` | No confirmation. |
| `remove --dry-run` | Shows what would be deleted. |
| `remove --only astx,nxkey` | Removes only the given ids (see `list`). |
| `remove --keep anysign` | Removes everything except the given ids. |
| `list` | Prints the catalog. |
| `--ko` / `--en` | Message language. Defaults to the system language. |

A log of every action is written to `/tmp/hoax-eliminator-<date>.log`.

### What it removes (catalog)

| id | Program | Vendor |
|---|---|---|
| `astx` | AhnLab Safe Transaction (ASTx) | AhnLab |
| `nxkey` | TouchEn nxKey (keyboard encryption) | RaonSecure |
| `crosswebex` | INISAFE CrossWeb EX | INITECH |
| `crossex` | iniLINE CrossEX / CrossWarpEX (browser relay) | iniLINE |
| `veraport` | Veraport (integrated security-module manager) | Wizvera |
| `delfino` | Delfino (certificate / e-signature) | Wizvera |
| `ipinside` | IPinside LWS Agent (IP / environment collector) | Interezen |
| `anysign` | AnySign4PC (certificate / e-signature) | SoftForum (HancomWITH) |
| `xecureweb` | XecureWeb Unified | SoftForum |
| `nprotect` | nProtect Online Security | INCA Internet |
| `magicline` | MagicLine4NX (certificate / e-signature) | DreamSecurity |
| `epagesafer` | ePageSafer / MaSaferJS (print and screen control) | MarkAny |
| `ksign` | KSign (KSignSWFT / CertRelay) | KSign |
| `unisign` | UniSign / UniSignMulti | CrossCert |
| `vestcert` | VestCert | Yettiesoft |
| `secukit` | SecuKit NX | SGA Solutions |

The first eight entries were built from exact file paths verified on a real install. The rest are matched by vendor identifiers (`com.dreamsecurity.*` and so on) and folder-name patterns. If you have one of those installed, please paste your `scan --deep` output in an [issue](https://github.com/wonmor/hoax-eliminator-mac/issues) so the exact paths can be added.

### Caveats

- The next bank site you visit **will ask you to reinstall** these. Install only on the day you need them, then remove again.
- Deletion is permanent. Use `remove --dry-run` first if unsure.
- Vendor root certificates in Keychain are left alone.
- Works on macOS 10.13 and later with the stock `/bin/bash` 3.2. No dependencies.

### How it works

For each catalog entry the tool expands the known paths and launchd plist patterns, checks for running processes, and then, in order: stops launchd jobs with `launchctl bootout`, kills leftover processes, deletes the plists and files, forgets package receipts with `pkgutil --forget`, and verifies nothing is left. `scan --deep` additionally greps `/Applications`, `/Library/Application Support`, `/Library/Internet Plug-Ins`, `/Library/PrivilegedHelperTools` and the launchd folders for vendor keywords and reports anything the catalog does not already cover.

### Contributing

Add a line to `CATALOG` in `hoax-eliminator.sh`. Format: `id|Name|Vendor|paths|launchd plists|process regex|uninstaller`. Paths and plists are `;`-separated, globs allowed, `~` is the logged-in user's home.

## License

MIT

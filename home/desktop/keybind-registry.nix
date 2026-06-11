{ lib, ... }:

let
  tagBindings = lib.concatMap (i: [
    { desc = "切换到 Tag ${toString i}"; alias = "tag"; key = toString i; mods = [ "Super" ]; category = "workspace"; }
    { desc = "切换显示 Tag ${toString i}"; alias = "toggle tag"; key = toString i; mods = [ "Super" "Ctrl" ]; category = "workspace"; }
    { desc = "移动窗口到 Tag ${toString i}"; alias = "move tag"; key = toString i; mods = [ "Super" "Shift" ]; category = "workspace"; }
    { desc = "切换窗口在 Tag ${toString i}"; alias = "toggle tag window"; key = toString i; mods = [ "Super" "Ctrl" "Shift" ]; category = "workspace"; }
  ]) (lib.range 1 9) ++ [
    { desc = "切换到所有 Tag"; alias = "tag all"; key = "0"; mods = [ "Super" ]; category = "workspace"; }
    { desc = "移动窗口到所有 Tag"; alias = "move tag all"; key = "0"; mods = [ "Super" "Shift" ]; category = "workspace"; }
  ];

  # Intra-app conflict detection: same app + same key+mods+mode = build error
  # Note: same key+mods with different modes is intentional (e.g., kwm passthrough)
  checkConflicts = appName: bindings:
    let
      keyId = b: "${lib.concatStringsSep "+" b.mods}+${b.key}@${b.mode or "default"}";
      ids = lib.imap0 (i: b: { inherit i; id = keyId b; inherit (b) desc; }) bindings;
      findDup = lib.concatMap (a:
        lib.filter (b: a.i < b.i && a.id == b.id) ids
      ) ids;
      dupDescs = map (d: "${d.id} → ${d.desc}") findDup;
    in
    assert lib.assertMsg (findDup == [])
      "keybind-registry: ${appName} has conflicting bindings: ${lib.concatStringsSep "; " dupDescs}";
      bindings;

in
{
  conventions = {
    tier = "documented";
    desc = "行业约定 — 跨应用行为一致的快捷键，不由 Nix 管理";
    bindings = checkConflicts "conventions" [
      { desc = "复制"; alias = "copy"; key = "c"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "粘贴"; alias = "paste"; key = "v"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "剪切"; alias = "cut"; key = "x"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "撤销"; alias = "undo"; key = "z"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "重做"; alias = "redo"; key = "z"; mods = [ "Ctrl" "Shift" ]; category = "edit"; }
      { desc = "全选"; alias = "select all"; key = "a"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "查找"; alias = "find"; key = "f"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "保存"; alias = "save"; key = "s"; mods = [ "Ctrl" ]; category = "edit"; }

      { desc = "新建标签页"; alias = "new tab"; key = "t"; mods = [ "Ctrl" ]; category = "tab"; }
      { desc = "关闭标签页"; alias = "close tab"; key = "w"; mods = [ "Ctrl" ]; category = "tab"; }
      { desc = "恢复关闭的标签"; alias = "reopen tab"; key = "t"; mods = [ "Ctrl" "Shift" ]; category = "tab"; }
      { desc = "下一个标签页"; alias = "next tab"; key = "Tab"; mods = [ "Ctrl" ]; category = "tab"; }
      { desc = "上一个标签页"; alias = "prev tab"; key = "Tab"; mods = [ "Ctrl" "Shift" ]; category = "tab"; }

      { desc = "全屏切换"; alias = "fullscreen"; key = "F11"; mods = []; category = "media"; }
    ];
  };

  kwm = {
    tier = "managed";
    desc = "kwm 默认 — dwm 风格，F=Floating 全家桶，Super+字母=基础 Super+Shift=破坏性";
    bindings = checkConflicts "kwm" [
      { desc = "重载配置"; alias = "reload"; key = "r"; mods = [ "Super" "Shift" ]; category = "session"; }
      { desc = "进入键盘直通模式"; alias = "passthrough enter"; key = "Escape"; mods = [ "Super" "Shift" ]; category = "session"; mode = "default"; }
      { desc = "退出键盘直通模式"; alias = "passthrough exit"; key = "Escape"; mods = [ "Super" "Shift" ]; category = "session"; mode = "passthrough"; }
      { desc = "退出会话"; alias = "quit"; key = "q"; mods = [ "Super" "Shift" ]; category = "session"; }
      { desc = "关闭当前窗口"; alias = "close"; key = "c"; mods = [ "Super" "Shift" ]; category = "session"; }

      { desc = "与主窗口交换(Zoom)"; alias = "zoom swap master"; key = "Return"; mods = [ "Super" ]; category = "focus"; }
      { desc = "聚焦下一个窗口"; alias = "focus next"; key = "j"; mods = [ "Super" ]; category = "focus"; }
      { desc = "聚焦上一个窗口"; alias = "focus prev"; key = "k"; mods = [ "Super" ]; category = "focus"; }
      { desc = "聚焦下一个(跳过浮动)"; alias = "focus next tiled"; key = "j"; mods = [ "Super" "Ctrl" ]; category = "focus"; }
      { desc = "聚焦上一个(跳过浮动)"; alias = "focus prev tiled"; key = "k"; mods = [ "Super" "Ctrl" ]; category = "focus"; }
      { desc = "焦点回到主窗口"; alias = "focus master"; key = "h"; mods = [ "Super" "Ctrl" ]; category = "focus"; }
      { desc = "焦点回到主窗口"; alias = "focus master"; key = "l"; mods = [ "Super" "Ctrl" ]; category = "focus"; }

      { desc = "与下一个窗口交换"; alias = "swap next"; key = "j"; mods = [ "Super" "Shift" ]; category = "swap"; }
      { desc = "与上一个窗口交换"; alias = "swap prev"; key = "k"; mods = [ "Super" "Shift" ]; category = "swap"; }

      { desc = "聚焦下一个输出"; alias = "focus output next"; key = "period"; mods = [ "Super" ]; category = "output"; }
      { desc = "聚焦上一个输出"; alias = "focus output prev"; key = "comma"; mods = [ "Super" ]; category = "output"; }
      { desc = "发送窗口到下一个输出"; alias = "send output next"; key = "period"; mods = [ "Super" "Shift" ]; category = "output"; }
      { desc = "发送窗口到上一个输出"; alias = "send output prev"; key = "comma"; mods = [ "Super" "Shift" ]; category = "output"; }

      { desc = "切换到上一个布局"; alias = "layout prev"; key = "space"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Tile 布局"; alias = "layout tile"; key = "t"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Grid 布局"; alias = "layout grid"; key = "g"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Deck 布局"; alias = "layout deck"; key = "d"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Monocle 布局"; alias = "layout monocle"; key = "m"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Scroller 布局"; alias = "layout scroller"; key = "s"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Centered Master 布局"; alias = "layout centered"; key = "u"; mods = [ "Super" ]; category = "layout"; }
      { desc = "Float 布局"; alias = "layout float"; key = "f"; mods = [ "Super" "Alt" ]; category = "layout"; }

      { desc = "切换浮动/平铺"; alias = "float toggle"; key = "f"; mods = [ "Super" ]; category = "window"; }
      { desc = "临时浮动模式"; alias = "float temp"; key = "f"; mods = [ "Super" "Ctrl" ]; category = "window"; }
      { desc = "全屏(保留边框)"; alias = "fullscreen border"; key = "m"; mods = [ "Super" "Shift" ]; category = "window"; }
      { desc = "全屏(无边框)"; alias = "fullscreen noborder"; key = "f"; mods = [ "Super" "Shift" ]; category = "window"; }
      { desc = "最大化"; alias = "maximize"; key = "e"; mods = [ "Super" "Shift" ]; category = "window"; }
      { desc = "切换 Sticky"; alias = "sticky"; key = "s"; mods = [ "Super" "Ctrl" ]; category = "window"; }
      { desc = "切换 Swallow"; alias = "swallow"; key = "a"; mods = [ "Super" ]; category = "window"; }
      { desc = "切换状态栏"; alias = "bar toggle"; key = "b"; mods = [ "Super" ]; category = "window"; }
      { desc = "切换自动 Swallow"; alias = "autowsow"; key = "a"; mods = [ "Super" "Shift" ]; category = "window"; }
      { desc = "切换 Grid 方向"; alias = "grid direction"; key = "g"; mods = [ "Super" "Shift" ]; category = "window"; }
      { desc = "切换 Centered Master 方向"; alias = "centered direction"; key = "u"; mods = [ "Super" "Shift" ]; category = "window"; }

      { desc = "增大主区域比例"; alias = "master grow"; key = "l"; mods = [ "Super" ]; category = "layout-param"; }
      { desc = "减小主区域比例"; alias = "master shrink"; key = "h"; mods = [ "Super" ]; category = "layout-param"; }
      { desc = "主区域位置→底部"; alias = "master bottom"; key = "j"; mods = [ "Super" "Alt" ]; category = "layout-param"; }
      { desc = "主区域位置→顶部"; alias = "master top"; key = "k"; mods = [ "Super" "Alt" ]; category = "layout-param"; }
      { desc = "主区域位置→右侧"; alias = "master right"; key = "l"; mods = [ "Super" "Alt" ]; category = "layout-param"; }
      { desc = "主区域位置→左侧"; alias = "master left"; key = "h"; mods = [ "Super" "Alt" ]; category = "layout-param"; }
      { desc = "增加主窗口数"; alias = "master count inc"; key = "equal"; mods = [ "Super" ]; category = "layout-param"; }
      { desc = "减少主窗口数"; alias = "master count dec"; key = "minus"; mods = [ "Super" ]; category = "layout-param"; }
      { desc = "增大间距"; alias = "gap grow"; key = "equal"; mods = [ "Super" "Alt" ]; category = "layout-param"; }
      { desc = "减小间距"; alias = "gap shrink"; key = "minus"; mods = [ "Super" "Alt" ]; category = "layout-param"; }

      { desc = "切换到上一个 Tag"; alias = "tag prev"; key = "Tab"; mods = [ "Super" ]; category = "workspace"; }
      { desc = "切换到下一个已占用 Tag"; alias = "tag next occupied"; key = "apostrophe"; mods = [ "Super" ]; category = "workspace"; }
      { desc = "切换到上一个已占用 Tag"; alias = "tag prev occupied"; key = "semicolon"; mods = [ "Super" ]; category = "workspace"; }
      { desc = "移动窗口到下一个空闲 Tag"; alias = "move tag next empty"; key = "apostrophe"; mods = [ "Super" "Shift" ]; category = "workspace"; }
      { desc = "移动窗口到上一个空闲 Tag"; alias = "move tag prev empty"; key = "semicolon"; mods = [ "Super" "Shift" ]; category = "workspace"; }
    ] ++ tagBindings ++ [
      { desc = "移动浮动窗口→右"; alias = "float move right"; key = "l"; mods = [ "Super" ]; category = "floating"; mode = "floating"; }
      { desc = "移动浮动窗口→左"; alias = "float move left"; key = "h"; mods = [ "Super" ]; category = "floating"; mode = "floating"; }
      { desc = "移动浮动窗口→下"; alias = "float move down"; key = "j"; mods = [ "Super" ]; category = "floating"; mode = "floating"; }
      { desc = "移动浮动窗口→上"; alias = "float move up"; key = "k"; mods = [ "Super" ]; category = "floating"; mode = "floating"; }
      { desc = "调整浮动窗口大小→宽"; alias = "float resize wider"; key = "l"; mods = [ "Super" "Ctrl" ]; category = "floating"; mode = "floating"; }
      { desc = "调整浮动窗口大小→窄"; alias = "float resize narrower"; key = "h"; mods = [ "Super" "Ctrl" ]; category = "floating"; mode = "floating"; }
      { desc = "调整浮动窗口大小→高"; alias = "float resize taller"; key = "j"; mods = [ "Super" "Ctrl" ]; category = "floating"; mode = "floating"; }
      { desc = "调整浮动窗口大小→矮"; alias = "float resize shorter"; key = "k"; mods = [ "Super" "Ctrl" ]; category = "floating"; mode = "floating"; }
      { desc = "吸附到右边"; alias = "float snap right"; key = "l"; mods = [ "Super" "Shift" ]; category = "floating"; mode = "floating"; }
      { desc = "吸附到左边"; alias = "float snap left"; key = "h"; mods = [ "Super" "Shift" ]; category = "floating"; mode = "floating"; }
      { desc = "吸附到下边"; alias = "float snap down"; key = "j"; mods = [ "Super" "Shift" ]; category = "floating"; mode = "floating"; }
      { desc = "吸附到上边"; alias = "float snap up"; key = "k"; mods = [ "Super" "Shift" ]; category = "floating"; mode = "floating"; }

      { desc = "应用启动器 (fuzzel)"; alias = "launcher"; key = "p"; mods = [ "Super" ]; category = "app"; }
      { desc = "WiFi 网络管理 (networkmanager_dmenu)"; alias = "wifi"; key = "n"; mods = [ "Super" ]; category = "app"; }
      { desc = "终端 (foot)"; alias = "terminal"; key = "Return"; mods = [ "Super" "Shift" ]; category = "app"; }
      { desc = "锁屏 (waylock)"; alias = "lock"; key = "l"; mods = [ "Super" "Shift" ]; category = "app"; }
      { desc = "区域截图"; alias = "screenshot region"; key = "Print"; mods = []; category = "app"; }
      { desc = "取色器"; alias = "colorpick picker"; key = "Print"; mods = [ "Super" "Shift" ]; category = "app"; }
      { desc = "快捷键速查"; alias = "cheatsheet"; key = "slash"; mods = [ "Super" ]; category = "app"; }
      { desc = "下一曲"; alias = "next track"; key = "bracketright"; mods = [ "Super" ]; category = "media"; }
      { desc = "上一曲"; alias = "prev track"; key = "bracketleft"; mods = [ "Super" ]; category = "media"; }
      { desc = "音量增大"; alias = "volume up"; key = "XF86_AudioRaiseVolume"; mods = []; category = "media"; }
      { desc = "音量减小"; alias = "volume down"; key = "XF86_AudioLowerVolume"; mods = []; category = "media"; }
      { desc = "音量静音"; alias = "mute"; key = "XF86_AudioMute"; mods = []; category = "media"; }
      { desc = "亮度增大"; alias = "brightness up"; key = "XF86_MonBrightnessUp"; mods = []; category = "media"; }
      { desc = "亮度减小"; alias = "brightness down"; key = "XF86_MonBrightnessDown"; mods = []; category = "media"; }
      { desc = "播放/暂停"; alias = "play pause"; key = "XF86_AudioPlay"; mods = []; category = "media"; }

      { desc = "移动窗口(鼠标)"; alias = "mouse move"; key = "左键"; mods = [ "Super" ]; category = "mouse"; }
      { desc = "调整窗口大小(鼠标)"; alias = "mouse resize"; key = "右键"; mods = [ "Super" ]; category = "mouse"; }
    ];
  };

  firefox = {
    tier = "documented";
    desc = "Firefox — 应用专属快捷键，Ctrl+字母遵循通用编辑惯例";
    bindings = checkConflicts "firefox" [
      { desc = "聚焦地址栏"; alias = "address bar url"; key = "l"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "页面内查找"; alias = "find page"; key = "f"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "刷新页面"; alias = "refresh reload"; key = "r"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "强制刷新"; alias = "hard refresh"; key = "r"; mods = [ "Ctrl" "Shift" ]; category = "nav"; }
      { desc = "开发者工具"; alias = "devtools inspector"; key = "i"; mods = [ "Ctrl" "Shift" ]; category = "dev"; }
      { desc = "截图"; alias = "screenshot"; key = "s"; mods = [ "Ctrl" "Shift" ]; category = "tool"; }
      { desc = "打开文件"; alias = "open file"; key = "o"; mods = [ "Ctrl" ]; category = "tool"; }
      { desc = "保存页面"; alias = "save page"; key = "s"; mods = [ "Ctrl" ]; category = "tool"; }
      { desc = "放大"; alias = "zoom in"; key = "+"; mods = [ "Ctrl" ]; category = "zoom"; }
      { desc = "缩小"; alias = "zoom out"; key = "-"; mods = [ "Ctrl" ]; category = "zoom"; }
      { desc = "重置缩放"; alias = "zoom reset"; key = "0"; mods = [ "Ctrl" ]; category = "zoom"; }
    ];
  };

  foot = {
    tier = "documented";
    desc = "Foot 终端 — 终端专属操作，Ctrl+Shift 前缀避免与 Shell 冲突";
    bindings = checkConflicts "foot" [
      { desc = "复制"; alias = "copy"; key = "c"; mods = [ "Ctrl" "Shift" ]; category = "clipboard"; }
      { desc = "粘贴"; alias = "paste"; key = "v"; mods = [ "Ctrl" "Shift" ]; category = "clipboard"; }
      { desc = "搜索回溯"; alias = "search scrollback"; key = "r"; mods = [ "Ctrl" "Shift" ]; category = "search"; }
      { desc = "新建窗口"; alias = "new window"; key = "n"; mods = [ "Ctrl" "Shift" ]; category = "window"; }
      { desc = "URL 模式"; alias = "url mode"; key = "u"; mods = [ "Ctrl" "Shift" ]; category = "nav"; }
      { desc = "增大字体"; alias = "font bigger"; key = "+"; mods = [ "Ctrl" "Shift" ]; category = "font"; }
      { desc = "减小字体"; alias = "font smaller"; key = "-"; mods = [ "Ctrl" "Shift" ]; category = "font"; }
      { desc = "重置字体"; alias = "font reset"; key = "0"; mods = [ "Ctrl" "Shift" ]; category = "font"; }
      { desc = "向上翻页"; alias = "page up"; key = "PageUp"; mods = [ "Shift" ]; category = "scroll"; }
      { desc = "向下翻页"; alias = "page down"; key = "PageDown"; mods = [ "Shift" ]; category = "scroll"; }
    ];
  };

  fuzzel = {
    tier = "documented";
    desc = "Fuzzel — 启动器/速查内导航，无需 IME";
    bindings = checkConflicts "fuzzel" [
      { desc = "上一条"; alias = "prev up"; key = "p"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "下一条"; alias = "next down"; key = "n"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "选中"; alias = "select enter"; key = "Return"; mods = []; category = "select"; }
      { desc = "取消"; alias = "cancel"; key = "Escape"; mods = []; category = "select"; }
      { desc = "删除前一个词"; alias = "delete word back"; key = "w"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "清空输入"; alias = "clear input"; key = "u"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "光标到行首"; alias = "home line start"; key = "a"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "光标到行尾"; alias = "end line end"; key = "e"; mods = [ "Ctrl" ]; category = "edit"; }
    ];
  };

  trae-cn = {
    tier = "documented";
    desc = "Trae CN — VS Code 核心快捷键，Ctrl+字母遵循通用编辑惯例";
    bindings = checkConflicts "trae-cn" [
      { desc = "命令面板"; alias = "command palette"; key = "p"; mods = [ "Ctrl" "Shift" ]; category = "core"; }
      { desc = "快速打开文件"; alias = "quick open file"; key = "p"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "切换终端"; alias = "terminal toggle"; key = "`"; mods = [ "Ctrl" ]; category = "view"; }
      { desc = "切换侧边栏"; alias = "sidebar toggle"; key = "b"; mods = [ "Ctrl" ]; category = "view"; }
      { desc = "聚焦资源管理器"; alias = "explorer focus"; key = "e"; mods = [ "Ctrl" "Shift" ]; category = "view"; }
      { desc = "全局搜索"; alias = "search global"; key = "f"; mods = [ "Ctrl" "Shift" ]; category = "search"; }
      { desc = "源代码管理"; alias = "source control git"; key = "g"; mods = [ "Ctrl" "Shift" ]; category = "view"; }
      { desc = "跳转到行"; alias = "goto line"; key = "g"; mods = [ "Ctrl" ]; category = "nav"; }
      { desc = "拆分编辑器"; alias = "split editor"; key = "\\"; mods = [ "Ctrl" "Shift" ]; category = "editor"; }
      { desc = "聚焦第 N 编辑器组"; alias = "focus group"; key = "1"; mods = [ "Ctrl" ]; category = "editor"; }
      { desc = "选中下一个相同词"; alias = "select next word"; key = "d"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "选中所有相同词"; alias = "select all word"; key = "l"; mods = [ "Ctrl" "Shift" ]; category = "edit"; }
      { desc = "删除当前行"; alias = "delete line"; key = "k"; mods = [ "Ctrl" "Shift" ]; category = "edit"; }
      { desc = "触发补全"; alias = "complete suggest"; key = "Space"; mods = [ "Ctrl" ]; category = "edit"; }
      { desc = "重命名符号"; alias = "rename symbol"; key = "F2"; mods = []; category = "edit"; }
      { desc = "跳转到定义"; alias = "goto definition"; key = "F12"; mods = []; category = "nav"; }
      { desc = "查找所有引用"; alias = "find references"; key = "F12"; mods = [ "Shift" ]; category = "nav"; }
      { desc = "AI 行内编辑"; alias = "ai inline edit"; key = "i"; mods = [ "Ctrl" ]; category = "ai"; }
      { desc = "AI Chat"; alias = "ai chat"; key = "i"; mods = [ "Ctrl" "Shift" ]; category = "ai"; }
      { desc = "查找替换"; alias = "replace"; key = "h"; mods = [ "Ctrl" ]; category = "edit"; }
    ];
  };

  yazi = {
    tier = "documented";
    desc = "Yazi — 终端文件管理器，Vim 风格 hjkl 导航";
    bindings = checkConflicts "yazi" [
      { desc = "下移"; alias = "down"; key = "j"; mods = []; category = "nav"; }
      { desc = "上移"; alias = "up"; key = "k"; mods = []; category = "nav"; }
      { desc = "返回上级"; alias = "back parent"; key = "h"; mods = []; category = "nav"; }
      { desc = "打开/进入"; alias = "open enter"; key = "l"; mods = []; category = "nav"; }
      { desc = "跳到顶部"; alias = "top first"; key = "g"; mods = []; category = "nav"; mode = "gg"; }
      { desc = "跳到底部"; alias = "bottom last"; key = "G"; mods = []; category = "nav"; }
      { desc = "复制(yank)"; alias = "yank copy"; key = "y"; mods = []; category = "action"; }
      { desc = "剪切"; alias = "cut"; key = "d"; mods = []; category = "action"; }
      { desc = "粘贴"; alias = "paste"; key = "p"; mods = []; category = "action"; }
      { desc = "删除到回收站"; alias = "delete trash"; key = "D"; mods = []; category = "action"; }
      { desc = "重命名"; alias = "rename"; key = "r"; mods = []; category = "action"; }
      { desc = "新建文件/目录"; alias = "new create"; key = "a"; mods = []; category = "action"; }
      { desc = "搜索文件名"; alias = "search find"; key = "/"; mods = []; category = "search"; }
      { desc = "过滤文件"; alias = "filter"; key = "f"; mods = []; category = "search"; }
      { desc = "跳转目录(zoxide)"; alias = "zoxide jump"; key = "z"; mods = []; category = "nav"; }
      { desc = "切换隐藏文件"; alias = "hidden toggle"; key = "."; mods = []; category = "view"; }
      { desc = "退出"; alias = "quit"; key = "q"; mods = []; category = "session"; }
    ];
  };

  vim = {
    tier = "documented";
    desc = "Vim — Normal 模式核心操作，hjkl 移动 + 操作符-动作组合";
    bindings = checkConflicts "vim" [
      { desc = "左移"; alias = "left"; key = "h"; mods = []; category = "move"; }
      { desc = "下移"; alias = "down"; key = "j"; mods = []; category = "move"; }
      { desc = "上移"; alias = "up"; key = "k"; mods = []; category = "move"; }
      { desc = "右移"; alias = "right"; key = "l"; mods = []; category = "move"; }
      { desc = "下一词首"; alias = "word next"; key = "w"; mods = []; category = "move"; }
      { desc = "上一词首"; alias = "word back"; key = "b"; mods = []; category = "move"; }
      { desc = "行首/行尾"; alias = "line start end"; key = "0"; mods = []; category = "move"; }
      { desc = "文件首/末行"; alias = "file top bottom"; key = "g"; mods = []; category = "move"; mode = "gg/G"; }
      { desc = "下翻半页"; alias = "page down half"; key = "d"; mods = [ "Ctrl" ]; category = "move"; }
      { desc = "上翻半页"; alias = "page up half"; key = "u"; mods = [ "Ctrl" ]; category = "move"; }
      { desc = "插入(光标前)"; alias = "insert before"; key = "i"; mods = []; category = "edit"; }
      { desc = "插入(光标后)"; alias = "insert after append"; key = "a"; mods = []; category = "edit"; }
      { desc = "插入(下方新行)"; alias = "insert new line below open"; key = "o"; mods = []; category = "edit"; }
      { desc = "删除(剪切)行"; alias = "delete cut line"; key = "d"; mods = []; category = "edit"; mode = "dd"; }
      { desc = "复制行"; alias = "yank copy line"; key = "y"; mods = []; category = "edit"; mode = "yy"; }
      { desc = "粘贴"; alias = "paste"; key = "p"; mods = []; category = "edit"; }
      { desc = "撤销"; alias = "undo"; key = "u"; mods = []; category = "edit"; }
      { desc = "搜索"; alias = "search find"; key = "/"; mods = []; category = "search"; }
      { desc = "水平分屏"; alias = "split horizontal"; key = "s"; mods = [ "Ctrl" ]; category = "window"; mode = "Ctrl+w s"; }
      { desc = "垂直分屏"; alias = "split vertical"; key = "v"; mods = [ "Ctrl" ]; category = "window"; mode = "Ctrl+w v"; }
      { desc = "退出"; alias = "quit"; key = "q"; mods = []; category = "session"; mode = ":q"; }
    ];
  };
}

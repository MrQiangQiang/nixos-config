{ lib, ... }:

let
  tagBindings = lib.concatMap (i: [
    { desc = "切换到 Tag ${toString i}"; key = toString i; mods = [ "Super" ]; category = "工作区"; }
    { desc = "切换显示 Tag ${toString i}"; key = toString i; mods = [ "Super" "Ctrl" ]; category = "工作区"; }
    { desc = "移动窗口到 Tag ${toString i}"; key = toString i; mods = [ "Super" "Shift" ]; category = "工作区"; }
    { desc = "切换窗口在 Tag ${toString i}"; key = toString i; mods = [ "Super" "Ctrl" "Shift" ]; category = "工作区"; }
  ]) (lib.range 1 9) ++ [
    { desc = "切换到所有 Tag"; key = "0"; mods = [ "Super" ]; category = "工作区"; }
    { desc = "移动窗口到所有 Tag"; key = "0"; mods = [ "Super" "Shift" ]; category = "工作区"; }
  ];

in
{
  universal = {
    tier = "universal";
    desc = "全平台通用 — Windows/macOS/Linux 一致，肌肉记忆可跨设备复用";
    bindings = [
      { desc = "复制"; key = "c"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "粘贴"; key = "v"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "剪切"; key = "x"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "撤销"; key = "z"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "重做"; key = "z"; mods = [ "Ctrl" "Shift" ]; category = "编辑"; }
      { desc = "全选"; key = "a"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "查找"; key = "f"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "查找替换"; key = "h"; mods = [ "Ctrl" ]; category = "编辑"; }
      { desc = "保存"; key = "s"; mods = [ "Ctrl" ]; category = "编辑"; }

      { desc = "新建标签页"; key = "t"; mods = [ "Ctrl" ]; category = "标签页"; }
      { desc = "关闭标签页"; key = "w"; mods = [ "Ctrl" ]; category = "标签页"; }
      { desc = "恢复关闭的标签"; key = "t"; mods = [ "Ctrl" "Shift" ]; category = "标签页"; }
      { desc = "下一个标签页"; key = "Tab"; mods = [ "Ctrl" ]; category = "标签页"; }
      { desc = "上一个标签页"; key = "Tab"; mods = [ "Ctrl" "Shift" ]; category = "标签页"; }

      { desc = "截图"; key = "Print"; mods = []; category = "系统"; }
      { desc = "全屏切换"; key = "F11"; mods = []; category = "系统"; }

      { desc = "音量增大"; key = "XF86_AudioRaiseVolume"; mods = []; category = "媒体"; }
      { desc = "音量减小"; key = "XF86_AudioLowerVolume"; mods = []; category = "媒体"; }
      { desc = "音量静音"; key = "XF86_AudioMute"; mods = []; category = "媒体"; }
      { desc = "亮度增大"; key = "XF86_MonBrightnessUp"; mods = []; category = "媒体"; }
      { desc = "亮度减小"; key = "XF86_MonBrightnessDown"; mods = []; category = "媒体"; }
      { desc = "播放/暂停"; key = "XF86_AudioPlay"; mods = []; category = "媒体"; }
      { desc = "下一曲"; key = "XF86_AudioNext"; mods = []; category = "媒体"; }
      { desc = "上一曲"; key = "XF86_AudioPrev"; mods = []; category = "媒体"; }
    ];
  };

  kwm = {
    tier = "managed";
    desc = "kwm 默认 — dwm 风格，F=Floating 全家桶，Super+字母=基础 Super+Shift=破坏性";
    bindings = [
      { desc = "重载配置"; key = "r"; mods = [ "Super" "Shift" ]; category = "会话"; }
      { desc = "切换键盘直通模式"; key = "Escape"; mods = [ "Super" "Shift" ]; category = "会话"; }
      { desc = "退出会话"; key = "q"; mods = [ "Super" "Shift" ]; category = "会话"; }
      { desc = "关闭当前窗口"; key = "c"; mods = [ "Super" "Shift" ]; category = "会话"; }

      { desc = "与主窗口交换(Zoom)"; key = "Return"; mods = [ "Super" ]; category = "焦点"; }
      { desc = "聚焦下一个窗口"; key = "j"; mods = [ "Super" ]; category = "焦点"; }
      { desc = "聚焦上一个窗口"; key = "k"; mods = [ "Super" ]; category = "焦点"; }
      { desc = "聚焦下一个(跳过浮动)"; key = "j"; mods = [ "Super" "Ctrl" ]; category = "焦点"; }
      { desc = "聚焦上一个(跳过浮动)"; key = "k"; mods = [ "Super" "Ctrl" ]; category = "焦点"; }
      { desc = "焦点回到主窗口"; key = "h"; mods = [ "Super" "Ctrl" ]; category = "焦点"; }
      { desc = "焦点回到主窗口"; key = "l"; mods = [ "Super" "Ctrl" ]; category = "焦点"; }

      { desc = "与下一个窗口交换"; key = "j"; mods = [ "Super" "Shift" ]; category = "交换"; }
      { desc = "与上一个窗口交换"; key = "k"; mods = [ "Super" "Shift" ]; category = "交换"; }

      { desc = "聚焦下一个输出"; key = "period"; mods = [ "Super" ]; category = "输出"; }
      { desc = "聚焦上一个输出"; key = "comma"; mods = [ "Super" ]; category = "输出"; }
      { desc = "发送窗口到下一个输出"; key = "period"; mods = [ "Super" "Shift" ]; category = "输出"; }
      { desc = "发送窗口到上一个输出"; key = "comma"; mods = [ "Super" "Shift" ]; category = "输出"; }

      { desc = "切换到上一个布局"; key = "space"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Tile 布局"; key = "t"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Grid 布局"; key = "g"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Deck 布局"; key = "d"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Monocle 布局"; key = "m"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Scroller 布局"; key = "s"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Centered Master 布局"; key = "u"; mods = [ "Super" ]; category = "布局"; }
      { desc = "Float 布局"; key = "f"; mods = [ "Super" "Alt" ]; category = "布局"; }

      { desc = "切换浮动/平铺"; key = "f"; mods = [ "Super" ]; category = "窗口"; }
      { desc = "临时浮动模式"; key = "f"; mods = [ "Super" "Ctrl" ]; category = "窗口"; }
      { desc = "全屏(保留边框)"; key = "m"; mods = [ "Super" "Shift" ]; category = "窗口"; }
      { desc = "全屏(无边框)"; key = "f"; mods = [ "Super" "Shift" ]; category = "窗口"; }
      { desc = "最大化"; key = "e"; mods = [ "Super" "Shift" ]; category = "窗口"; }
      { desc = "切换 Sticky"; key = "s"; mods = [ "Super" "Ctrl" ]; category = "窗口"; }
      { desc = "切换 Swallow"; key = "a"; mods = [ "Super" ]; category = "窗口"; }
      { desc = "切换状态栏"; key = "b"; mods = [ "Super" ]; category = "窗口"; }
      { desc = "切换自动 Swallow"; key = "a"; mods = [ "Super" "Shift" ]; category = "窗口"; }
      { desc = "切换 Grid 方向"; key = "g"; mods = [ "Super" "Shift" ]; category = "窗口"; }
      { desc = "切换 Centered Master 方向"; key = "u"; mods = [ "Super" "Shift" ]; category = "窗口"; }

      { desc = "增大主区域比例"; key = "l"; mods = [ "Super" ]; category = "布局参数"; }
      { desc = "减小主区域比例"; key = "h"; mods = [ "Super" ]; category = "布局参数"; }
      { desc = "主区域位置→底部"; key = "j"; mods = [ "Super" "Alt" ]; category = "布局参数"; }
      { desc = "主区域位置→顶部"; key = "k"; mods = [ "Super" "Alt" ]; category = "布局参数"; }
      { desc = "主区域位置→右侧"; key = "l"; mods = [ "Super" "Alt" ]; category = "布局参数"; }
      { desc = "主区域位置→左侧"; key = "h"; mods = [ "Super" "Alt" ]; category = "布局参数"; }
      { desc = "增加主窗口数"; key = "="; mods = [ "Super" ]; category = "布局参数"; }
      { desc = "减少主窗口数"; key = "-"; mods = [ "Super" ]; category = "布局参数"; }
      { desc = "增大间距"; key = "="; mods = [ "Super" "Alt" ]; category = "布局参数"; }
      { desc = "减小间距"; key = "-"; mods = [ "Super" "Alt" ]; category = "布局参数"; }

      { desc = "切换到上一个 Tag"; key = "Tab"; mods = [ "Super" ]; category = "工作区"; }
      { desc = "切换到下一个已占用 Tag"; key = "apostrophe"; mods = [ "Super" ]; category = "工作区"; }
      { desc = "切换到上一个已占用 Tag"; key = "semicolon"; mods = [ "Super" ]; category = "工作区"; }
      { desc = "移动窗口到下一个空闲 Tag"; key = "apostrophe"; mods = [ "Super" "Shift" ]; category = "工作区"; }
      { desc = "移动窗口到上一个空闲 Tag"; key = "semicolon"; mods = [ "Super" "Shift" ]; category = "工作区"; }
    ] ++ tagBindings ++ [
      { desc = "移动浮动窗口→右"; key = "l"; mods = [ "Super" ]; category = "浮动"; mode = "floating"; }
      { desc = "移动浮动窗口→左"; key = "h"; mods = [ "Super" ]; category = "浮动"; mode = "floating"; }
      { desc = "移动浮动窗口→下"; key = "j"; mods = [ "Super" ]; category = "浮动"; mode = "floating"; }
      { desc = "移动浮动窗口→上"; key = "k"; mods = [ "Super" ]; category = "浮动"; mode = "floating"; }
      { desc = "调整浮动窗口大小→宽"; key = "l"; mods = [ "Super" "Ctrl" ]; category = "浮动"; mode = "floating"; }
      { desc = "调整浮动窗口大小→窄"; key = "h"; mods = [ "Super" "Ctrl" ]; category = "浮动"; mode = "floating"; }
      { desc = "调整浮动窗口大小→高"; key = "j"; mods = [ "Super" "Ctrl" ]; category = "浮动"; mode = "floating"; }
      { desc = "调整浮动窗口大小→矮"; key = "k"; mods = [ "Super" "Ctrl" ]; category = "浮动"; mode = "floating"; }
      { desc = "吸附到右边"; key = "l"; mods = [ "Super" "Shift" ]; category = "浮动"; mode = "floating"; }
      { desc = "吸附到左边"; key = "h"; mods = [ "Super" "Shift" ]; category = "浮动"; mode = "floating"; }
      { desc = "吸附到下边"; key = "j"; mods = [ "Super" "Shift" ]; category = "浮动"; mode = "floating"; }
      { desc = "吸附到上边"; key = "k"; mods = [ "Super" "Shift" ]; category = "浮动"; mode = "floating"; }

      { desc = "应用启动器 (fuzzel)"; key = "p"; mods = [ "Super" ]; category = "应用"; }
      { desc = "终端 (foot)"; key = "Return"; mods = [ "Super" "Shift" ]; category = "应用"; }
      { desc = "锁屏 (waylock)"; key = "l"; mods = [ "Super" "Shift" ]; category = "应用"; }
      { desc = "区域截图"; key = "Print"; mods = []; category = "应用"; }
      { desc = "快捷键速查"; key = "/"; mods = [ "Super" ]; category = "应用"; }

      { desc = "移动窗口(鼠标)"; key = "左键"; mods = [ "Super" ]; category = "鼠标"; }
      { desc = "调整窗口大小(鼠标)"; key = "右键"; mods = [ "Super" ]; category = "鼠标"; }
    ];
  };

  firefox = {
    tier = "documented";
    desc = "应用专属 — Firefox 特有，Ctrl+字母遵循通用编辑惯例";
    bindings = [
      { desc = "聚焦地址栏"; key = "l"; mods = [ "Ctrl" ]; category = "导航"; }
      { desc = "页面内查找"; key = "f"; mods = [ "Ctrl" ]; category = "导航"; }
      { desc = "刷新页面"; key = "r"; mods = [ "Ctrl" ]; category = "导航"; }
      { desc = "强制刷新"; key = "r"; mods = [ "Ctrl" "Shift" ]; category = "导航"; }
      { desc = "开发者工具"; key = "i"; mods = [ "Ctrl" "Shift" ]; category = "开发"; }
      { desc = "截图"; key = "s"; mods = [ "Ctrl" "Shift" ]; category = "工具"; }
      { desc = "打开文件"; key = "o"; mods = [ "Ctrl" ]; category = "工具"; }
      { desc = "保存页面"; key = "s"; mods = [ "Ctrl" ]; category = "工具"; }
      { desc = "放大"; key = "+"; mods = [ "Ctrl" ]; category = "缩放"; }
      { desc = "缩小"; key = "-"; mods = [ "Ctrl" ]; category = "缩放"; }
      { desc = "重置缩放"; key = "0"; mods = [ "Ctrl" ]; category = "缩放"; }
    ];
  };
}

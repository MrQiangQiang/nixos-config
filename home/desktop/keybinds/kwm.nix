{ lib, checkConflicts }:

let
  tagBindings =
    lib.concatMap (i: [
      {
        desc = "切换到 Tag ${toString i}";
        alias = "tag";
        key = toString i;
        mods = [ "Super" ];
        category = "workspace";
      }
      {
        desc = "切换显示 Tag ${toString i}";
        alias = "toggle tag";
        key = toString i;
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "workspace";
      }
      {
        desc = "移动窗口到 Tag ${toString i}";
        alias = "move tag";
        key = toString i;
        mods = [
          "Super"
          "Shift"
        ];
        category = "workspace";
      }
      {
        desc = "切换窗口在 Tag ${toString i}";
        alias = "toggle tag window";
        key = toString i;
        mods = [
          "Super"
          "Ctrl"
          "Shift"
        ];
        category = "workspace";
      }
    ]) (lib.range 1 9)
    ++ [
      {
        desc = "切换到所有 Tag";
        alias = "tag all";
        key = "0";
        mods = [ "Super" ];
        category = "workspace";
      }
      {
        desc = "移动窗口到所有 Tag";
        alias = "move tag all";
        key = "0";
        mods = [
          "Super"
          "Shift"
        ];
        category = "workspace";
      }
    ];
in
{
  tier = "managed";
  desc = "kwm 默认 — dwm 风格，F=Floating 全家桶，Super+字母=基础 Super+Shift=破坏性";
  bindings =
    checkConflicts "kwm" [
      {
        desc = "重载配置";
        alias = "reload";
        key = "r";
        mods = [
          "Super"
          "Shift"
        ];
        category = "session";
      }
      {
        desc = "进入键盘直通模式";
        alias = "passthrough enter";
        key = "Escape";
        mods = [
          "Super"
          "Shift"
        ];
        category = "session";
        mode = "default";
      }
      {
        desc = "退出键盘直通模式";
        alias = "passthrough exit";
        key = "Escape";
        mods = [
          "Super"
          "Shift"
        ];
        category = "session";
        mode = "passthrough";
      }
      {
        desc = "退出会话";
        alias = "quit";
        key = "q";
        mods = [
          "Super"
          "Shift"
        ];
        category = "session";
      }
      {
        desc = "关闭当前窗口";
        alias = "close";
        key = "c";
        mods = [
          "Super"
          "Shift"
        ];
        category = "session";
      }

      {
        desc = "与主窗口交换(Zoom)";
        alias = "zoom swap master";
        key = "Return";
        mods = [ "Super" ];
        category = "focus";
      }
      {
        desc = "聚焦下一个窗口";
        alias = "focus next";
        key = "j";
        mods = [ "Super" ];
        category = "focus";
      }
      {
        desc = "聚焦上一个窗口";
        alias = "focus prev";
        key = "k";
        mods = [ "Super" ];
        category = "focus";
      }
      {
        desc = "聚焦下一个(跳过浮动)";
        alias = "focus next tiled";
        key = "j";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "focus";
      }
      {
        desc = "聚焦上一个(跳过浮动)";
        alias = "focus prev tiled";
        key = "k";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "focus";
      }
      {
        desc = "焦点回到主窗口";
        alias = "focus master";
        key = "h";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "focus";
      }
      {
        desc = "焦点回到主窗口";
        alias = "focus master";
        key = "l";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "focus";
      }

      {
        desc = "与下一个窗口交换";
        alias = "swap next";
        key = "j";
        mods = [
          "Super"
          "Shift"
        ];
        category = "swap";
      }
      {
        desc = "与上一个窗口交换";
        alias = "swap prev";
        key = "k";
        mods = [
          "Super"
          "Shift"
        ];
        category = "swap";
      }

      {
        desc = "聚焦下一个输出";
        alias = "focus output next";
        key = "period";
        mods = [ "Super" ];
        category = "output";
      }
      {
        desc = "聚焦上一个输出";
        alias = "focus output prev";
        key = "comma";
        mods = [ "Super" ];
        category = "output";
      }
      {
        desc = "发送窗口到下一个输出";
        alias = "send output next";
        key = "period";
        mods = [
          "Super"
          "Shift"
        ];
        category = "output";
      }
      {
        desc = "发送窗口到上一个输出";
        alias = "send output prev";
        key = "comma";
        mods = [
          "Super"
          "Shift"
        ];
        category = "output";
      }

      {
        desc = "切换到上一个布局";
        alias = "layout prev";
        key = "space";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Tile 布局";
        alias = "layout tile";
        key = "t";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Grid 布局";
        alias = "layout grid";
        key = "g";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Deck 布局";
        alias = "layout deck";
        key = "d";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Monocle 布局";
        alias = "layout monocle";
        key = "m";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Scroller 布局";
        alias = "layout scroller";
        key = "s";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Centered Master 布局";
        alias = "layout centered";
        key = "u";
        mods = [ "Super" ];
        category = "layout";
      }
      {
        desc = "Float 布局";
        alias = "layout float";
        key = "f";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout";
      }

      {
        desc = "切换浮动/平铺";
        alias = "float toggle";
        key = "f";
        mods = [ "Super" ];
        category = "window";
      }
      {
        desc = "临时浮动模式";
        alias = "float temp";
        key = "f";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "window";
      }
      {
        desc = "全屏(保留边框)";
        alias = "fullscreen border";
        key = "m";
        mods = [
          "Super"
          "Shift"
        ];
        category = "window";
      }
      {
        desc = "全屏(无边框)";
        alias = "fullscreen noborder";
        key = "f";
        mods = [
          "Super"
          "Shift"
        ];
        category = "window";
      }
      {
        desc = "最大化";
        alias = "maximize";
        key = "e";
        mods = [
          "Super"
          "Shift"
        ];
        category = "window";
      }
      {
        desc = "切换 Sticky";
        alias = "sticky";
        key = "s";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "window";
      }
      {
        desc = "切换 Swallow";
        alias = "swallow";
        key = "a";
        mods = [ "Super" ];
        category = "window";
      }
      {
        desc = "切换状态栏";
        alias = "bar toggle";
        key = "b";
        mods = [ "Super" ];
        category = "window";
      }
      {
        desc = "切换自动 Swallow";
        alias = "autowsow";
        key = "a";
        mods = [
          "Super"
          "Shift"
        ];
        category = "window";
      }
      {
        desc = "切换 Grid 方向";
        alias = "grid direction";
        key = "g";
        mods = [
          "Super"
          "Shift"
        ];
        category = "window";
      }
      {
        desc = "切换 Centered Master 方向";
        alias = "centered direction";
        key = "u";
        mods = [
          "Super"
          "Shift"
        ];
        category = "window";
      }

      {
        desc = "增大主区域比例";
        alias = "master grow";
        key = "l";
        mods = [ "Super" ];
        category = "layout-param";
      }
      {
        desc = "减小主区域比例";
        alias = "master shrink";
        key = "h";
        mods = [ "Super" ];
        category = "layout-param";
      }
      {
        desc = "主区域位置→底部";
        alias = "master bottom";
        key = "j";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout-param";
      }
      {
        desc = "主区域位置→顶部";
        alias = "master top";
        key = "k";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout-param";
      }
      {
        desc = "主区域位置→右侧";
        alias = "master right";
        key = "l";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout-param";
      }
      {
        desc = "主区域位置→左侧";
        alias = "master left";
        key = "h";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout-param";
      }
      {
        desc = "增加主窗口数";
        alias = "master count inc";
        key = "equal";
        mods = [ "Super" ];
        category = "layout-param";
      }
      {
        desc = "减少主窗口数";
        alias = "master count dec";
        key = "minus";
        mods = [ "Super" ];
        category = "layout-param";
      }
      {
        desc = "增大间距";
        alias = "gap grow";
        key = "equal";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout-param";
      }
      {
        desc = "减小间距";
        alias = "gap shrink";
        key = "minus";
        mods = [
          "Super"
          "Alt"
        ];
        category = "layout-param";
      }

      {
        desc = "切换到上一个 Tag";
        alias = "tag prev";
        key = "Tab";
        mods = [ "Super" ];
        category = "workspace";
      }
      {
        desc = "切换到下一个已占用 Tag";
        alias = "tag next occupied";
        key = "apostrophe";
        mods = [ "Super" ];
        category = "workspace";
      }
      {
        desc = "切换到上一个已占用 Tag";
        alias = "tag prev occupied";
        key = "semicolon";
        mods = [ "Super" ];
        category = "workspace";
      }
      {
        desc = "移动窗口到下一个空闲 Tag";
        alias = "move tag next empty";
        key = "apostrophe";
        mods = [
          "Super"
          "Shift"
        ];
        category = "workspace";
      }
      {
        desc = "移动窗口到上一个空闲 Tag";
        alias = "move tag prev empty";
        key = "semicolon";
        mods = [
          "Super"
          "Shift"
        ];
        category = "workspace";
      }
    ]
    ++ tagBindings
    ++ [
      {
        desc = "移动浮动窗口→右";
        alias = "float move right";
        key = "l";
        mods = [ "Super" ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "移动浮动窗口→左";
        alias = "float move left";
        key = "h";
        mods = [ "Super" ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "移动浮动窗口→下";
        alias = "float move down";
        key = "j";
        mods = [ "Super" ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "移动浮动窗口→上";
        alias = "float move up";
        key = "k";
        mods = [ "Super" ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "调整浮动窗口大小→宽";
        alias = "float resize wider";
        key = "l";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "调整浮动窗口大小→窄";
        alias = "float resize narrower";
        key = "h";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "调整浮动窗口大小→高";
        alias = "float resize taller";
        key = "j";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "调整浮动窗口大小→矮";
        alias = "float resize shorter";
        key = "k";
        mods = [
          "Super"
          "Ctrl"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "吸附到右边";
        alias = "float snap right";
        key = "l";
        mods = [
          "Super"
          "Shift"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "吸附到左边";
        alias = "float snap left";
        key = "h";
        mods = [
          "Super"
          "Shift"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "吸附到下边";
        alias = "float snap down";
        key = "j";
        mods = [
          "Super"
          "Shift"
        ];
        category = "floating";
        mode = "floating";
      }
      {
        desc = "吸附到上边";
        alias = "float snap up";
        key = "k";
        mods = [
          "Super"
          "Shift"
        ];
        category = "floating";
        mode = "floating";
      }

      {
        desc = "应用启动器 (fuzzel)";
        alias = "launcher";
        key = "p";
        mods = [ "Super" ];
        category = "app";
      }
      {
        desc = "WiFi 网络管理 (networkmanager_dmenu)";
        alias = "wifi";
        key = "n";
        mods = [ "Super" ];
        category = "app";
      }
      {
        desc = "终端 (foot)";
        alias = "terminal";
        key = "Return";
        mods = [
          "Super"
          "Shift"
        ];
        category = "app";
      }
      {
        desc = "锁屏 (waylock)";
        alias = "lock";
        key = "l";
        mods = [
          "Super"
          "Shift"
        ];
        category = "app";
      }
      {
        desc = "区域截图";
        alias = "screenshot region";
        key = "Print";
        mods = [ ];
        category = "app";
      }
      {
        desc = "取色器";
        alias = "colorpick picker";
        key = "Print";
        mods = [
          "Super"
          "Shift"
        ];
        category = "app";
      }
      {
        desc = "快捷键速查";
        alias = "cheatsheet";
        key = "slash";
        mods = [ "Super" ];
        category = "app";
      }
      {
        desc = "下一曲";
        alias = "next track";
        key = "bracketright";
        mods = [ "Super" ];
        category = "media";
      }
      {
        desc = "上一曲";
        alias = "prev track";
        key = "bracketleft";
        mods = [ "Super" ];
        category = "media";
      }
      {
        desc = "音量增大";
        alias = "volume up";
        key = "XF86_AudioRaiseVolume";
        mods = [ ];
        category = "media";
      }
      {
        desc = "音量减小";
        alias = "volume down";
        key = "XF86_AudioLowerVolume";
        mods = [ ];
        category = "media";
      }
      {
        desc = "音量静音";
        alias = "mute";
        key = "XF86_AudioMute";
        mods = [ ];
        category = "media";
      }
      {
        desc = "亮度增大";
        alias = "brightness up";
        key = "XF86_MonBrightnessUp";
        mods = [ ];
        category = "media";
      }
      {
        desc = "亮度减小";
        alias = "brightness down";
        key = "XF86_MonBrightnessDown";
        mods = [ ];
        category = "media";
      }
      {
        desc = "播放/暂停";
        alias = "play pause";
        key = "XF86_AudioPlay";
        mods = [ ];
        category = "media";
      }

      {
        desc = "移动窗口(鼠标)";
        alias = "mouse move";
        key = "左键";
        mods = [ "Super" ];
        category = "mouse";
      }
      {
        desc = "调整窗口大小(鼠标)";
        alias = "mouse resize";
        key = "右键";
        mods = [ "Super" ];
        category = "mouse";
      }
    ];
}

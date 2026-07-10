{ checkConflicts }:

{
  tier = "documented";
  desc = "opencode — TUI AI 编程助手，Ctrl+X 为 leader 键组合前缀";
  bindings = checkConflicts "opencode" [
    # --- core ---
    {
      desc = "Leader 键";
      alias = "leader key";
      key = "x";
      mods = [ "Ctrl" ];
      category = "core";
    }
    {
      desc = "命令面板";
      alias = "command list";
      key = "p";
      mods = [ "Ctrl" ];
      category = "core";
    }

    # --- session ---
    {
      desc = "中断当前会话";
      alias = "session interrupt";
      key = "Escape";
      mods = [ ];
      category = "session";
    }
    {
      desc = "退出应用";
      alias = "app exit";
      key = "d";
      mods = [ "Ctrl" ];
      category = "session";
    }
    {
      desc = "后台同步子代理";
      alias = "session background";
      key = "b";
      mods = [ "Ctrl" ];
      category = "session";
    }
    {
      desc = "新建会话";
      alias = "session new";
      key = "Leader+n";
      mods = [ ];
      category = "session";
    }
    {
      desc = "列出会话";
      alias = "session list";
      key = "Leader+l";
      mods = [ ];
      category = "session";
    }
    {
      desc = "查看时间线";
      alias = "session timeline";
      key = "Leader+g";
      mods = [ ];
      category = "session";
    }
    {
      desc = "压缩会话";
      alias = "session compact";
      key = "Leader+c";
      mods = [ ];
      category = "session";
    }
    {
      desc = "导出到编辑器";
      alias = "session export";
      key = "Leader+x";
      mods = [ ];
      category = "session";
    }

    # --- agent / model ---
    {
      desc = "下一个代理";
      alias = "agent next";
      key = "Tab";
      mods = [ ];
      category = "agent";
    }
    {
      desc = "上一个代理";
      alias = "agent prev";
      key = "Tab";
      mods = [ "Shift" ];
      category = "agent";
    }
    {
      desc = "列出代理";
      alias = "agent list";
      key = "Leader+a";
      mods = [ ];
      category = "agent";
    }
    {
      desc = "列出模型";
      alias = "model list";
      key = "Leader+m";
      mods = [ ];
      category = "model";
    }

    # --- edit / input ---
    {
      desc = "提交输入";
      alias = "input submit";
      key = "Return";
      mods = [ ];
      category = "input";
    }
    {
      desc = "输入换行";
      alias = "input newline";
      key = "Return";
      mods = [ "Shift" ];
      category = "input";
    }
    {
      desc = "清空输入";
      alias = "input clear";
      key = "c";
      mods = [ "Ctrl" ];
      category = "input";
    }
    {
      desc = "打开外部编辑器";
      alias = "editor open";
      key = "Leader+e";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "撤销消息";
      alias = "message undo";
      key = "Leader+u";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "重做消息";
      alias = "message redo";
      key = "Leader+r";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "复制消息";
      alias = "message copy";
      key = "Leader+y";
      mods = [ ];
      category = "edit";
    }

    # --- view ---
    {
      desc = "切换侧边栏";
      alias = "sidebar toggle";
      key = "Leader+b";
      mods = [ ];
      category = "view";
    }
    {
      desc = "查看状态";
      alias = "status view";
      key = "Leader+s";
      mods = [ ];
      category = "view";
    }
    {
      desc = "切换主题";
      alias = "theme list";
      key = "Leader+t";
      mods = [ ];
      category = "view";
    }

    # --- navigate ---
    {
      desc = "跳到消息顶部";
      alias = "messages first";
      key = "g";
      mods = [ "Ctrl" ];
      category = "navigate";
    }
    {
      desc = "跳到最后消息";
      alias = "messages last";
      key = "g";
      mods = [
        "Ctrl"
        "Alt"
      ];
      category = "navigate";
    }
    {
      desc = "上翻一页";
      alias = "page up";
      key = "PageUp";
      mods = [ ];
      category = "navigate";
    }
    {
      desc = "下翻一页";
      alias = "page down";
      key = "PageDown";
      mods = [ ];
      category = "navigate";
    }

    # --- help ---
    {
      desc = "切换提示";
      alias = "tips toggle";
      key = "Leader+h";
      mods = [ ];
      category = "help";
    }
    {
      desc = "Which-Key 面板";
      alias = "which key toggle";
      key = "k";
      mods = [
        "Ctrl"
        "Alt"
      ];
      category = "help";
    }
  ];
}

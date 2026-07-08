{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "Foot 终端 — 终端专属操作，Ctrl+Shift 前缀避免与 Shell 冲突";
  bindings = checkConflicts "foot" [
    {
      desc = "复制";
      alias = "copy";
      key = "c";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "clipboard";
    }
    {
      desc = "粘贴";
      alias = "paste";
      key = "v";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "clipboard";
    }
    {
      desc = "搜索回溯";
      alias = "search scrollback";
      key = "r";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "search";
    }
    {
      desc = "新建窗口";
      alias = "new window";
      key = "n";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "window";
    }
    {
      desc = "URL 模式";
      alias = "url mode";
      key = "u";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "nav";
    }
    {
      desc = "增大字体";
      alias = "font bigger";
      key = "+";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "font";
    }
    {
      desc = "减小字体";
      alias = "font smaller";
      key = "-";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "font";
    }
    {
      desc = "重置字体";
      alias = "font reset";
      key = "0";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "font";
    }
    {
      desc = "向上翻页";
      alias = "page up";
      key = "PageUp";
      mods = [ "Shift" ];
      category = "scroll";
    }
    {
      desc = "向下翻页";
      alias = "page down";
      key = "PageDown";
      mods = [ "Shift" ];
      category = "scroll";
    }
  ];
}

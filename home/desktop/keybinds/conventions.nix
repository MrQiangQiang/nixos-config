{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "行业约定 — 跨应用行为一致的快捷键，不由 Nix 管理";
  bindings = checkConflicts "conventions" [
    {
      desc = "复制";
      alias = "copy";
      key = "c";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "粘贴";
      alias = "paste";
      key = "v";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "剪切";
      alias = "cut";
      key = "x";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "撤销";
      alias = "undo";
      key = "z";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "重做";
      alias = "redo";
      key = "z";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "edit";
    }
    {
      desc = "全选";
      alias = "select all";
      key = "a";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "查找";
      alias = "find";
      key = "f";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "保存";
      alias = "save";
      key = "s";
      mods = [ "Ctrl" ];
      category = "edit";
    }

    {
      desc = "新建标签页";
      alias = "new tab";
      key = "t";
      mods = [ "Ctrl" ];
      category = "tab";
    }
    {
      desc = "关闭标签页";
      alias = "close tab";
      key = "w";
      mods = [ "Ctrl" ];
      category = "tab";
    }
    {
      desc = "恢复关闭的标签";
      alias = "reopen tab";
      key = "t";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "tab";
    }
    {
      desc = "下一个标签页";
      alias = "next tab";
      key = "Tab";
      mods = [ "Ctrl" ];
      category = "tab";
    }
    {
      desc = "上一个标签页";
      alias = "prev tab";
      key = "Tab";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "tab";
    }

    {
      desc = "全屏切换";
      alias = "fullscreen";
      key = "F11";
      mods = [ ];
      category = "media";
    }
  ];
}

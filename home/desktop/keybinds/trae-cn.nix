{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "Trae CN — VS Code 核心快捷键，Ctrl+字母遵循通用编辑惯例";
  bindings = checkConflicts "trae-cn" [
    {
      desc = "命令面板";
      alias = "command palette";
      key = "p";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "core";
    }
    {
      desc = "快速打开文件";
      alias = "quick open file";
      key = "p";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "切换终端";
      alias = "terminal toggle";
      key = "`";
      mods = [ "Ctrl" ];
      category = "view";
    }
    {
      desc = "切换侧边栏";
      alias = "sidebar toggle";
      key = "b";
      mods = [ "Ctrl" ];
      category = "view";
    }
    {
      desc = "聚焦资源管理器";
      alias = "explorer focus";
      key = "e";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "view";
    }
    {
      desc = "全局搜索";
      alias = "search global";
      key = "f";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "search";
    }
    {
      desc = "源代码管理";
      alias = "source control git";
      key = "g";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "view";
    }
    {
      desc = "跳转到行";
      alias = "goto line";
      key = "g";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "拆分编辑器";
      alias = "split editor";
      key = "\\";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "editor";
    }
    {
      desc = "聚焦第 N 编辑器组";
      alias = "focus group";
      key = "1";
      mods = [ "Ctrl" ];
      category = "editor";
    }
    {
      desc = "选中下一个相同词";
      alias = "select next word";
      key = "d";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "选中所有相同词";
      alias = "select all word";
      key = "l";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "edit";
    }
    {
      desc = "删除当前行";
      alias = "delete line";
      key = "k";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "edit";
    }
    {
      desc = "触发补全";
      alias = "complete suggest";
      key = "Space";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "重命名符号";
      alias = "rename symbol";
      key = "F2";
      mods = [ ];
      category = "edit";
    }
    {
      desc = "跳转到定义";
      alias = "goto definition";
      key = "F12";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "查找所有引用";
      alias = "find references";
      key = "F12";
      mods = [ "Shift" ];
      category = "nav";
    }
    {
      desc = "AI 行内编辑";
      alias = "ai inline edit";
      key = "i";
      mods = [ "Ctrl" ];
      category = "ai";
    }
    {
      desc = "AI Chat";
      alias = "ai chat";
      key = "i";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "ai";
    }
    {
      desc = "查找替换";
      alias = "replace";
      key = "h";
      mods = [ "Ctrl" ];
      category = "edit";
    }
  ];
}

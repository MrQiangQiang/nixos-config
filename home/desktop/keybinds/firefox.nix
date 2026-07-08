{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "Firefox — 应用专属快捷键，Ctrl+字母遵循通用编辑惯例";
  bindings = checkConflicts "firefox" [
    {
      desc = "聚焦地址栏";
      alias = "address bar url";
      key = "l";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "页面内查找";
      alias = "find page";
      key = "f";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "刷新页面";
      alias = "refresh reload";
      key = "r";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "强制刷新";
      alias = "hard refresh";
      key = "r";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "nav";
    }
    {
      desc = "开发者工具";
      alias = "devtools inspector";
      key = "i";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "dev";
    }
    {
      desc = "截图";
      alias = "screenshot";
      key = "s";
      mods = [
        "Ctrl"
        "Shift"
      ];
      category = "tool";
    }
    {
      desc = "打开文件";
      alias = "open file";
      key = "o";
      mods = [ "Ctrl" ];
      category = "tool";
    }
    {
      desc = "保存页面";
      alias = "save page";
      key = "s";
      mods = [ "Ctrl" ];
      category = "tool";
    }
    {
      desc = "放大";
      alias = "zoom in";
      key = "+";
      mods = [ "Ctrl" ];
      category = "zoom";
    }
    {
      desc = "缩小";
      alias = "zoom out";
      key = "-";
      mods = [ "Ctrl" ];
      category = "zoom";
    }
    {
      desc = "重置缩放";
      alias = "zoom reset";
      key = "0";
      mods = [ "Ctrl" ];
      category = "zoom";
    }
  ];
}

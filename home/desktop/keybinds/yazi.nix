{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "Yazi — 终端文件管理器，Vim 风格 hjkl 导航";
  bindings = checkConflicts "yazi" [
    {
      desc = "下移";
      alias = "down";
      key = "j";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "上移";
      alias = "up";
      key = "k";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "返回上级";
      alias = "back parent";
      key = "h";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "打开/进入";
      alias = "open enter";
      key = "l";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "跳到顶部";
      alias = "top first";
      key = "g";
      mods = [ ];
      category = "nav";
      mode = "gg";
    }
    {
      desc = "跳到底部";
      alias = "bottom last";
      key = "G";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "复制(yank)";
      alias = "yank copy";
      key = "y";
      mods = [ ];
      category = "action";
    }
    {
      desc = "剪切";
      alias = "cut";
      key = "d";
      mods = [ ];
      category = "action";
    }
    {
      desc = "粘贴";
      alias = "paste";
      key = "p";
      mods = [ ];
      category = "action";
    }
    {
      desc = "删除到回收站";
      alias = "delete trash";
      key = "D";
      mods = [ ];
      category = "action";
    }
    {
      desc = "重命名";
      alias = "rename";
      key = "r";
      mods = [ ];
      category = "action";
    }
    {
      desc = "新建文件/目录";
      alias = "new create";
      key = "a";
      mods = [ ];
      category = "action";
    }
    {
      desc = "搜索文件名";
      alias = "search find";
      key = "/";
      mods = [ ];
      category = "search";
    }
    {
      desc = "过滤文件";
      alias = "filter";
      key = "f";
      mods = [ ];
      category = "search";
    }
    {
      desc = "跳转目录(zoxide)";
      alias = "zoxide jump";
      key = "z";
      mods = [ ];
      category = "nav";
    }
    {
      desc = "切换隐藏文件";
      alias = "hidden toggle";
      key = ".";
      mods = [ ];
      category = "view";
    }
    {
      desc = "退出";
      alias = "quit";
      key = "q";
      mods = [ ];
      category = "session";
    }
  ];
}

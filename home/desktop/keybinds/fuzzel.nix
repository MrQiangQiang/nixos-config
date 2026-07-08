{ lib, checkConflicts }:

{
  tier = "documented";
  desc = "Fuzzel — 启动器/速查内导航，无需 IME";
  bindings = checkConflicts "fuzzel" [
    {
      desc = "上一条";
      alias = "prev up";
      key = "p";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "下一条";
      alias = "next down";
      key = "n";
      mods = [ "Ctrl" ];
      category = "nav";
    }
    {
      desc = "选中";
      alias = "select enter";
      key = "Return";
      mods = [ ];
      category = "select";
    }
    {
      desc = "取消";
      alias = "cancel";
      key = "Escape";
      mods = [ ];
      category = "select";
    }
    {
      desc = "删除前一个词";
      alias = "delete word back";
      key = "w";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "清空输入";
      alias = "clear input";
      key = "u";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "光标到行首";
      alias = "home line start";
      key = "a";
      mods = [ "Ctrl" ];
      category = "edit";
    }
    {
      desc = "光标到行尾";
      alias = "end line end";
      key = "e";
      mods = [ "Ctrl" ];
      category = "edit";
    }
  ];
}

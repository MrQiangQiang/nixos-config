# 共享内容 SSOT：commands / skills / agents / rules / references
# 空集时对所有工具零副作用
# 架构参考：ai-nixCfg（lib 模式）+ superpowers（references 模式）+ i9wa4（SSOT 模式）
{ lib, ... }:
let
  ## 读取 shared/ 目录下的 .md 源文件
  ## 路径相对于此文件（Nix 路径字面量特性）
  readContent = type: name: builtins.readFile (./shared + "/${type}/${name}.md");

  ## YAML frontmatter 生成器（来自 ai-nixCfg，支持 list/attrs，自动过滤 null/空值）
  mkFrontmatter =
    attrs:
    let
      formatValue =
        v:
        if builtins.isList v then
          "[${lib.concatMapStringsSep ", " (x: "\"${x}\"") v}]"
        else if builtins.isAttrs v then
          "\n${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: val: "  ${k}: ${val}") v)}"
        else
          v;
      filtered = lib.filterAttrs (_: v: v != null && v != "" && v != [ ] && v != { }) attrs;
      lines = lib.mapAttrsToList (k: v: "${k}: ${formatValue v}") filtered;
    in
    "---\n${lib.concatStringsSep "\n" lines}\n---\n";

  ## 内容元数据（当前为空，添加内容时在此注册）
  ## 跨工具字段示例（参考 ai-nixCfg agentMeta 模式）：
  ##   commandMeta.commit = { description = "Create git commit"; argument-hint = "[msg]"; };
  ##   skillMeta.nix-flakes = { description = "Use when working with Nix flake inputs or outputs"; };
  ##   agentMeta.code-reviewer = {
  ##     description = "Reviews code changes";
  ##     model = "sonnet";              # Claude Code 必需（inherit/sonnet/opus/haiku）
  ##     tools = [ "Read" "Grep" ];     # 可选
  ##     color = "green";               # Claude Code 可选
  ##   };
  commandMeta = { };
  skillMeta = { };
  agentMeta = { };
  ruleNames = [ "guidelines" ];
  referenceNames = [ ];

  ## 构建各工具消费的 attrset（name 由 key 自动注入，所有 meta 字段透传到 frontmatter）
  commands = lib.mapAttrs (
    name: meta: mkFrontmatter meta + readContent "commands" name
  ) commandMeta;

  skills = lib.mapAttrs (
    name: meta: mkFrontmatter (meta // { inherit name; }) + readContent "skills" name
  ) skillMeta;

  agents = lib.mapAttrs (
    name: meta: mkFrontmatter (meta // { inherit name; }) + readContent "agents" name
  ) agentMeta;

  rules = builtins.listToAttrs (
    map (name: lib.nameValuePair name (readContent "rules" name)) ruleNames
  );

  references = builtins.listToAttrs (
    map (name: lib.nameValuePair name (readContent "references" name)) referenceNames
  );

  ## 合并所有 rules（供 context 选项使用）
  combinedRules = lib.concatStringsSep "\n\n---\n\n" (builtins.attrValues rules);
in
{
  inherit
    commands
    skills
    agents
    rules
    references
    combinedRules
    ;
}

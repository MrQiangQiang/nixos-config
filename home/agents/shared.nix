# 共享内容 SSOT：commands / skills / agents / context
# context = 常驻上下文（行为准则），写入各工具的全局 context 文件：
#   OpenCode/Codex → AGENTS.md (context 选项)
#   Claude Code    → ~/.claude/CLAUDE.md (context 选项)
#   Trae           → ~/.trae-cn/user_rules/<name>.md (home.file)
# 项目级 rules（条件加载，如 .claude/rules/、.trae/rules/）不通过此 SSOT 管理，
# 应在项目仓库中维护。
# 空集时对所有工具零副作用
# 架构参考：ai-nixCfg（lib 模式 + *Meta attrset 承载工具特定映射）+ i9wa4（SSOT 模式）
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
  ## context（常驻上下文）硬性约束：
  ##   - 合计 ≤100 行（严于 ECC 309 行 advisory；ECC/Superpowers 源码验证：常驻越短模型遵循越可靠）
  ##   - 只放行为准则，不放方法论（方法论放 skill，按需加载）
  ##   - 少即是多：每加一条规则都摊薄已有规则的权重
  commandMeta = { };
  skillMeta = {
    research = {
      description = "Systematic research on technical topics, tool comparisons, framework evaluations, and latest developments. Use when the user wants research, comparisons, deep dives, or evidence-backed answers - 技术调研/方案对比/工具选型/最新动态调研";
    };
  };
  ## skill/MCP 总量控制（少即是多）：
  ##   - skill description 常驻 catalog，每条 ~30 tokens；数量多了不触发也占 context，
  ##     且选择过多导致模型无法准确触发——保持个位数
  ##   - MCP tool schema 每会话常驻，每个工具 ~500 tokens；新增必须通过 ECC 两轮测试
  ##     (Universal + MCP-genuinely-beats-CLI)，否则用 skill 包 CLI
  agentMeta = { };
  contextNames = [ "guidelines" ];

  ## 构建各工具消费的 attrset（name 由 key 自动注入，所有 meta 字段透传到 frontmatter）
  commands = lib.mapAttrs (name: meta: mkFrontmatter meta + readContent "commands" name) commandMeta;

  skills = lib.mapAttrs (
    name: meta: mkFrontmatter (meta // { inherit name; }) + readContent "skills" name
  ) skillMeta;

  agents = lib.mapAttrs (
    name: meta: mkFrontmatter (meta // { inherit name; }) + readContent "agents" name
  ) agentMeta;

  context = builtins.listToAttrs (
    map (name: lib.nameValuePair name (readContent "context" name)) contextNames
  );

  ## 合并所有 context（供各工具 context 选项使用）
  combinedContext = lib.concatStringsSep "\n\n---\n\n" (builtins.attrValues context);
in
{
  inherit
    commands
    skills
    agents
    context
    combinedContext
    ;
}

# LiteLLM CustomLogger — 过滤非标准工具类型
#
# 问题：Codex 0.142+ 通过 Responses API 发送 `type: namespace` 工具分组，
#       LiteLLM 桥接 Responses→Chat 时原样透传 tools 数组，
#       DeepSeek/GLM/Kimi 等 OpenAI 兼容 provider 仅认 `function` 类型 → 400。
#
# 源码依据（LiteLLM 1.89.0）：
#   - drop_params 仅过滤顶层 key，不遍历 tools（litellm/utils.py:3760-3800）
#   - modify_params 仅插入占位消息，不删工具（litellm/__init__.py:230）
#   - Tool Permission Guardrail 跳过非 function 工具（tool_permission.py:497-504）
#   - DeepSeek/OpenAI transformer 原样透传 tools（gpt_transformation.py:429-456）
#   - 唯一过滤点：async_pre_call_hook 返回 dict 替换请求体
#     （litellm/proxy/utils.py:1403-1511 → common_request_processing.py:970）
#
# 加载机制：litellm_settings.callbacks 引用本文件模块级实例，
#          get_instance_fn 相对 config.yaml 目录解析（types_utils/utils.py:8-65）。
#
# 设计原则：单一职责（只过滤工具类型），面向未来（任何非 function 类型都被过滤），
#          低复杂度（无外部依赖，纯 LiteLLM SDK）。
from typing import Optional

from litellm.integrations.custom_logger import CustomLogger
from litellm.proxy._types import UserAPIKeyAuth
from litellm.caching.dual_cache import DualCache
from litellm.types.utils import CallTypesLiteral


class NonFunctionToolFilter(CustomLogger):
    """
    过滤 tools 数组中非 function 类型的工具。

    OpenAI Chat Completions API 标准仅支持 `function` 类型。
    Codex Responses API 的 `namespace` 工具分组、`web_search`、`file_search`
    等类型在转发到 OpenAI 兼容 provider 前必须移除。
    """

    ALLOWED_TOOL_TYPES = {"function"}

    # Anthropic Messages 端点 (/v1/messages) 的 tools 使用 Anthropic 格式：
    #   function 工具无 type 字段（{"name": ..., "input_schema": ...}）
    #   非函数工具有 type 字段（{"type": "web_search_20260209", ...}）
    # LiteLLM 内部的 LiteLLMMessagesToCompletionTransformationHandler 会将 Anthropic 格式
    # 转换为 OpenAI function 格式。跳过此 callback，避免误删所有 function 工具。
    SKIP_CALL_TYPES = {"anthropic_messages"}

    async def async_pre_call_hook(
        self,
        user_api_key_dict: UserAPIKeyAuth,
        cache: DualCache,
        data: dict,
        call_type: CallTypesLiteral,
    ) -> Optional[dict]:
        if call_type in self.SKIP_CALL_TYPES:
            return None

        tools = data.get("tools")
        if not isinstance(tools, list) or not tools:
            return None

        filtered = [
            t for t in tools
            if isinstance(t, dict) and t.get("type") in self.ALLOWED_TOOL_TYPES
        ]

        if len(filtered) == len(tools):
            return None

        data["tools"] = filtered

        # 若 tool_choice 指向被删除的非 function 工具，退化为 auto
        tc = data.get("tool_choice")
        if isinstance(tc, dict) and tc.get("type") not in self.ALLOWED_TOOL_TYPES:
            data["tool_choice"] = "auto"

        return data


# 模块级实例 — get_instance_fn 通过 getattr 加载
non_function_tool_filter = NonFunctionToolFilter()

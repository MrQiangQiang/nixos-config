# CONTEXT.md 格式

## 结构

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## 规则

- **要有主见。** 当同一个概念存在多个词时，选最好的那个，把其余的列在 `_Avoid_` 下。
- **定义要精炼。** 一到两句话最多。定义它是什么，而非它做什么。
- **只包含特定于此项目上下文的术语。** 通用编程概念（超时、错误类型、工具模式）即使项目大量使用它们也不应纳入。添加一个术语前，先问：这是此上下文独有的概念，还是通用编程概念？只有前者才属于这里。
- **当自然形成聚类时，用子标题分组术语。** 如果所有术语都属于同一个连贯领域，扁平列表也可以。

## 单一上下文 vs 多上下文仓库

**单一上下文（大多数仓库）：** 仓库根目录下一个 `CONTEXT.md`。

**多个上下文：** 仓库根目录下的 `CONTEXT-MAP.md` 列出各个上下文、它们所在位置以及彼此之间的关系：

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) — manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

skill 会推断适用哪种结构：

- 如果存在 `CONTEXT-MAP.md`，读取它来找到各个上下文
- 如果只存在根目录的 `CONTEXT.md`，则是单一上下文
- 如果两者都不存在，在第一个术语确定时惰性创建一个根 `CONTEXT.md`

当存在多个上下文时，推断当前主题关联的是哪一个。如果不清楚，就问。

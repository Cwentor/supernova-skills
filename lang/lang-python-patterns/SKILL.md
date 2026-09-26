---
name: lang-python-patterns
description: 编写、评审或重构 Python 代码时使用：需要 Python 惯用法（Pythonic）、PEP 8 风格或类型提示（type hints）参考；症状包括可变默认参数、裸 except、类型标注缺失、手写循环代替推导式、资源未用 with 管理。Use when writing, reviewing, or refactoring Python code that needs Pythonic idioms, PEP 8 style, type hints, or anti-pattern fixes.
---

# lang-python-patterns

写、改、评 Python 代码的惯用法基准：可读、显式、地道。拿不准时，清晰度优先于技巧性（最小惊讶原则）。

## 核心速查表

| 场景 | 惯用法 | 要点 |
|---|---|---|
| 风格基准 | PEP 8 + 描述性命名 | 行宽 88；格式与导入排序交给工具，不手工调；难读就拆 |
| 类型提示 | 内置泛型（Python 3.9+） | 用 `list[str]`、`dict[str, int]`、`X \| None`，不用 `Optional`/`List`；复杂类型起别名；鸭子类型用 `Protocol` 结构化声明，不强制继承 |
| 异常处理 | EAFP + 特定异常 | 直接尝试，按类型捕获；转换错误用 `raise New(...) from e` 保留回溯；业务异常统一继承一个基类；绝不裸 `except:` |
| 资源管理 | `with` 上下文管理器 | 文件/连接/锁一律 with；定制用 `@contextmanager` 或 `__enter__`/`__exit__`，`__exit__` 返回 False 不吞异常 |
| 集合变换 | 推导式 | 单一变换/过滤用推导式；条件一多就展开成显式循环或函数 |
| 大数据 | 生成器惰性求值 | `sum(x * x for x in ...)` 不建中间列表；读大文件逐行 `yield` |
| 数据建模 | `@dataclass` | 自动 `__init__/__repr__/__eq__`；验证集中在 `__post_init__`；不可变值对象用 `NamedTuple` 或 `frozen=True`；海量实例加 `__slots__` 省内存 |
| 装饰器 | `functools.wraps` | 包装函数必加 `@functools.wraps` 保留元信息；参数化装饰器写成三层嵌套 |
| 字符串 | f-string + `join` | 格式化用 f-string；循环内 `+=` 是 O(n²)，用 `"".join(...)` |
| 常用内置 | `pathlib.Path`、`enumerate` | 路径不拼字符串；循环要索引用 enumerate |
| 并发 | 按负载选型 | I/O 密集用 `ThreadPoolExecutor` 或 `asyncio.gather`；CPU 密集用 `ProcessPoolExecutor` |
| 包组织 | src 布局 + `pyproject.toml` | 导入顺序：标准库→第三方→本地；`__init__.py` 用 `__all__` 显式导出 |

## 反模式红线自查

| 坏味道 | 修正 |
|---|---|
| `def f(items=[])` 可变默认参数 | 默认 `None`，函数体内建新列表 |
| `except:` / `except: pass` | 捕获特定异常并处理或记日志 |
| `type(x) == list` | `isinstance(x, list)` |
| `x == None` | `x is None` |
| `from m import *` | 显式导入具体名字 |
| 循环内 `result += s` | `"".join(...)` |
| 手动 `open()`/`close()` | `with open(...)` |
| 大结果集整体载入内存 | 生成器逐个产出 |
| 公共函数无类型标注 | 补全签名并过 mypy |

## 一个最佳示例

dataclass 建模 + 类型提示 + EAFP + 异常链 + pathlib，一段代码融合核心模式：

```python
from dataclasses import dataclass
from json import JSONDecodeError, loads
from pathlib import Path


class ConfigError(Exception):
    """配置相关错误的基类，调用方可统一捕获。"""


@dataclass
class Config:
    host: str
    port: int

    def __post_init__(self) -> None:
        if not 0 < self.port < 65536:
            raise ValueError(f"非法端口: {self.port}")


def load_config(path: Path) -> Config:
    """读取并校验 JSON 配置；所有失败路径都抛 ConfigError 并保留原因。"""
    try:
        data = loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as e:
        raise ConfigError(f"配置文件不存在: {path}") from e
    except JSONDecodeError as e:
        raise ConfigError(f"非法 JSON: {path}") from e
    try:
        return Config(host=data["host"], port=int(data["port"]))
    except (KeyError, TypeError, ValueError) as e:
        raise ConfigError(f"配置字段缺失或非法: {e}") from e
```

## 工具链

```bash
ruff check . && black .    # lint + 格式化（导入排序交给工具）
mypy .                     # 类型检查
pytest --cov=mypackage     # 测试 + 覆盖率
bandit -r .                # 安全扫描
```

## 相关技能

- `lang-python-testing`：为 Python 代码写测试、配 pytest 时
- `dev-tdd`：动手实现前决定测试先行流程时
- `dev-review-code`：对 Python diff / 分支发起评审时
- `dev-debugging`：Python 代码报错或行为异常，先诊断再修复时

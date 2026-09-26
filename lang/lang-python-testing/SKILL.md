---
name: lang-python-testing
description: 为 Python 项目编写、修复或评审测试，或搭建测试基础设施时使用；触发词与症状：pytest、unittest、fixture、conftest.py、mock/patch、parametrize、覆盖率、--cov、test_*.py、tests/ 目录组织，或 Python 代码缺测试、测试失败待修。Use when writing, fixing, or reviewing tests in a Python project — pytest, fixtures, mocking, parametrization, coverage, conftest, or failing test files.
---

# Python 测试（pytest）

定位：dev-tdd 管语言无关的 TDD 纪律（何时写测试、红-绿-重构节奏）；本技能只管 pytest 生态的落地写法（怎么写）：fixture、mock、参数化、标记、覆盖率。宣称「测试通过」之前的证据要求见 dev-verification。

## 模式速查表

| 场景 | 写法 | 要点与陷阱 |
|---|---|---|
| 基本断言 | `assert result == expected`；`assert result is None`；`assert isinstance(result, str)` | 直接裸 assert，pytest 自动展开失败详情 |
| 异常 | `with pytest.raises(ValueError, match="invalid input"):` | `match` 是正则搜索；禁止 try/except 捕获后手动断言 |
| 夹具 | `@pytest.fixture`，测试函数按名注入；`yield` 前是 setup、后是 teardown | teardown 无论测试成败都执行 |
| 作用域 | `scope="function"`（默认）/ `"module"` / `"session"` | 放大作用域省时间但引入共享状态，无理由不放大 |
| 共享夹具 | `tests/conftest.py` | 同级及子目录自动发现，无需 import |
| 隐式夹具 | `@pytest.fixture(autouse=True)` | 所有测试静默生效，慎用——隐藏依赖 |
| 参数化 | `@pytest.mark.parametrize(("a", "b", "expected"), [...], ids=[...])` | 一条用例跑多组输入；`ids` 让失败报告可读 |
| 参数化夹具 | `@pytest.fixture(params=["sqlite", "postgresql"])` + `request.param` | 同一测试对每个后端各跑一次 |
| mock | `@patch("mypackage.service.notify")`，多个装饰器自下而上对应 | patch 使用处（import 它的模块），不是定义处 |
| mock 行为 | `mock.return_value = ...`；`mock.side_effect = ConnectionError(...)` | `side_effect` 可抛异常，也可按序返回多个值 |
| 防误用 | `@patch(..., autospec=True)` | 被模拟对象签名一变，mock 立即报错 |
| 交互断言 | `mock.assert_called_once_with(...)`；异步用 `assert_awaited_once()` | 只断言返回值不够，调用契约也是行为 |
| 异步 | `@pytest.mark.asyncio` + `async def`（pytest-asyncio） | 异步 mock 用 `AsyncMock` |
| 临时文件 | 内置夹具 `tmp_path` | `pathlib.Path`，自动清理；不要手写 tempfile + os.remove |
| 挑选与调试 | `pytest -m "not slow"`、`-k "user"`、`-x`、`--lf`、`--pdb` | `-m` 按标记选，`-k` 按名字选 |
| 覆盖率 | `pytest --cov=mypackage --cov-report=term-missing` | 目标 ≥80%，关键路径 100%；盯未覆盖行，不是盯分数 |
| 配置 | `pyproject.toml` 的 `[tool.pytest.ini_options]`：`testpaths`、`addopts`、`markers` | `addopts` 常驻 `--strict-markers`，未注册标记直接报错 |
| 目录组织 | `tests/unit/`、`tests/integration/`、`tests/e2e/` + 顶层 `conftest.py` | 按速度与外部依赖分层，慢测试用标记隔离 |

## 最佳示例

一个文件覆盖夹具 teardown、参数化、异常、mock 四类核心模式：

```python
# tests/test_user_service.py
from unittest.mock import patch

import pytest

from myapp.service import UserService


@pytest.fixture
def service():
    svc = UserService(db=":memory:")   # setup
    yield svc                          # 测试在此期间运行
    svc.close()                        # teardown：成败都执行


@pytest.mark.parametrize(
    ("name", "expected"),
    [("Alice", "ALICE"), ("Bob", "BOB")],
    ids=["alice", "bob"],
)
def test_register_uppercases_display_name(service, name, expected):
    user = service.register(name)
    assert user.display_name == expected


def test_register_rejects_empty_name(service):
    with pytest.raises(ValueError, match="empty name"):
        service.register("")


@patch("myapp.service.notify")   # patch 使用处：service 模块里 import 的 notify
def test_register_notifies(mock_notify, service):
    service.register("Alice")
    mock_notify.assert_called_once_with("Alice")
```

## 借口 vs 现实

| 借口 | 现实 |
|---|---|
| 「用 try/except 捕获异常更好控制」 | 忘记重新断言就是假绿；`pytest.raises` 才是断言异常的姿势 |
| 「mock 得越细越安全」 | 过度指定的 mock 一改实现就碎——测行为，别测实现细节 |
| 「失败测试先跳过，回头再修」 | 失败必须当场处置：修实现，或证明测试本身写错了再改测试 |
| 「测试间共享对象省时间」 | 测试必须独立；共享可变状态是顺序耦合与 flaky 的根源 |
| 「print 看一眼就行」 | 用断言表达期望；要看过程用 `pytest -v` / `--lf` / `--pdb` |
| 「第三方库的行为也得测」 | 信任库本身，测自己写的胶水代码与边界处理 |
| 「覆盖率到 80% 就交差」 | 覆盖率是下限不是终点；关键路径要 100%，未覆盖行逐行说明 |
| 「测试类里写个 setup 方法更顺手」 | 夹具按名注入即可；`autouse` 只留给真正全局的清理逻辑 |

## 红线自查

- 没有靠跳过、注释或放宽断言让失败测试「变绿」。
- 每条测试只验证一个行为，命名描述行为（如 `test_user_login_with_invalid_credentials_fails`）。
- 所有 `@patch` 目标都是使用处；对外部依赖加了 `autospec=True`。
- 测试之间无共享可变状态；夹具作用域没有无理由放大。
- 异常路径一律用 `pytest.raises(match=...)` 断言。
- 宣称完成前 `pytest` 全绿且 `--cov` 达标（证据纪律见 dev-verification）。

## 与相关技能的分工

- dev-tdd：语言无关的 TDD 纪律——何时写测试、红-绿-重构节奏；本技能是它在 pytest 生态的落地。
- dev-verification：宣称「测试通过 / 工作完成」之前的证据纪律。
- dev-debugging：测试失败时先诊断根因，再动手修。
- lang-python-patterns：被测代码本身的 Python 结构与风格模式。

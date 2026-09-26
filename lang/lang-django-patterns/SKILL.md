---
name: lang-django-patterns
description: 当用户在 Django / Django REST Framework (DRF) 项目中设计 models 与 ORM 查询、编写 serializer / viewset / REST API，或处理 settings 拆分、缓存、信号 (Signals)、中间件 (Middleware)、N+1 查询时使用；症状关键词：models.py、select_related、ModelViewSet、AUTH_USER_MODEL、apps.py、cache_page。Use when building or reviewing Django or DRF applications — models, REST API, caching, signals, or middleware.
---

# lang-django-patterns：Django 架构模式速查

生产级 Django/DRF 的结构与模式参考。核心立场：结构化组织优先于省事的写法——apps 按领域分层、settings 按环境拆分、业务流程下沉 service 层，为可维护性而构建。

## 模式速查表

| 模式 | 何时用 | 关键点 |
|---|---|---|
| settings 拆分 | 存在多环境（开发/生产/测试） | `config/settings/{base,development,production}.py`；各环境 `from .base import *` 后覆写；密钥一律走环境变量 |
| 自定义 User | 项目一开始就定 | 继承 `AbstractUser` + 设 `AUTH_USER_MODEL`；中途替换代价极大 |
| 自定义 QuerySet | 同一筛选逻辑出现 ≥2 次 | `objects = ProductQuerySet.as_manager()`；每个方法返回 `self.filter/select_related(...)`，支持链式组合 |
| 服务层 services.py | 视图出现多步写库、事务、外部调用 | `@transaction.atomic` 包住整个流程；视图只做解析参数 → 调 service → 组响应 |
| 读写分离 serializer | 创建与读取的字段/校验不同 | `get_serializer_class()` 按 `self.action`（create/list/…）切换 |
| ViewSet + @action | 标准 CRUD 加少量非标端点 | queryset 上预加载关联；`perform_create` 注入 `request.user`；写操作挂权限类 |
| select_related / prefetch_related | 循环或序列化里访问关联对象 | 外键/一对一用 `select_related`（单条 JOIN）；多对多/反向外键用 `prefetch_related`（二次查询） |
| 缓存 | 读多写少的昂贵查询/计算 | 页面级 `cache_page(N)`；低级 `cache.get/set` 的 key 要含参数维度；数据变更处主动 `cache.delete` |
| 信号 Signals | 与第三方模型解耦的联动（如建 User 时建 Profile） | `@receiver(post_save, sender=…)`；必须在 `AppConfig.ready()` 里 import 才生效；自己项目的逻辑显式调用优先于信号 |
| 中间件 Middleware | 全局横切关注点（请求日志、耗时统计） | 只做轻量处理；每请求写库这类重活交给视图/信号 |
| bulk 操作 | 循环逐条 create/save | `bulk_create` / `bulk_update` 一次往返；注意它们不触发 `save()` 与大多数信号 |

## 最佳示例：一条 DRF 数据流

Model（自定义 QuerySet + 索引）→ Serializer（读写分离、分层校验）→ ViewSet（预加载 + 按动作切换）→ Service（事务业务流）。

```python
# models.py —— QuerySet 承载可复用筛选；Meta 管排序/索引/约束
class ProductQuerySet(models.QuerySet):
    def active(self):
        return self.filter(is_active=True)

    def with_relations(self):   # 防 N+1：外键 + 多对多一次配齐
        return self.select_related('category').prefetch_related('tags')

class Product(models.Model):
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    price = models.DecimalField(max_digits=10, decimal_places=2,
                                validators=[MinValueValidator(0)])
    category = models.ForeignKey('Category', on_delete=models.CASCADE,
                                related_name='products')
    created_at = models.DateTimeField(auto_now_add=True)
    objects = ProductQuerySet.as_manager()

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['category', '-created_at'])]
```

```python
# serializers.py —— 读/写两个类；单字段校验用 validate_x，跨字段校验用 validate()
class ProductSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'category_name', 'created_at']
        read_only_fields = ['id', 'created_at']

class ProductCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['name', 'price', 'category']

    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError("价格不能为负数。")
        return value
```

```python
# views.py —— queryset 预加载；按 action 切 serializer；非标端点用 @action 转调 service
class ProductViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    ordering = ['-created_at']

    def get_queryset(self):
        return Product.objects.active().with_relations()

    def get_serializer_class(self):
        return ProductCreateSerializer if self.action == 'create' else ProductSerializer

    @action(detail=True, methods=['post'])
    def purchase(self, request, pk=None):
        result = OrderService.create_order(request.user, self.get_object())
        return Response(result, status=status.HTTP_201_CREATED)
```

```python
# services.py —— 多步业务放这里，事务包全程；视图永远不直接拼业务流程
class OrderService:
    @staticmethod
    @transaction.atomic
    def create_order(user, product):
        order = Order.objects.create(user=user, total_price=product.price)
        OrderItem.objects.create(order=order, product=product,
                                 quantity=1, price=product.price)
        return order
```

## 常见错误

| 反模式 | 后果 | 正确做法 |
|---|---|---|
| 循环/序列化中直接访问 `obj.category.name`、`obj.tags.all()` | N+1 查询 | queryset 里 `select_related` / `prefetch_related` |
| 写了 signals.py 却没在 `AppConfig.ready()` 里 import | 信号静默不触发 | `ready()` 中 `import myapp.signals  # noqa: F401` |
| 依赖 `bulk_create` 触发信号或重写的 `save()` | 不触发，副作用悄悄丢失 | 需要副作用就改走 service 显式调用 |
| 业务流程（多表写、支付、发信）写在视图里 | 无法复用、难测试、事务易碎 | 下沉 services.py + `@transaction.atomic` |
| 一个 serializer 通吃读与写 | 响应多暴露字段 / 校验不足 | 读写分离，按 action 切换 |
| 循环内逐条 `save()` 更新 | 慢（每行一次数据库往返） | `bulk_update(objs, ['field'])` |
| 模型裸奔不设索引/约束 | 列表页越跑越慢、脏数据入库 | `Meta.indexes` / `Meta.constraints` / `db_index=True` |

## 相关技能

- `lang-python-patterns`：Python 通用模式与语言层约定（本技能只覆盖 Django 特有部分）
- `lang-python-testing`：Django 项目里的 Python 测试组织
- `dev-tdd`：动手实现前的测试先行纪律
- `dev-review-code`：评审 Django 代码时的检查视角
- `dev-verification`：宣称完成前的验证要求

# 截图替换说明

把下列截图文件放到当前目录后，重新在 `report/` 目录执行：

```bash
xelatex main.tex
```

如果某张图还没准备好，`main.tex` 会自动显示占位框，不会阻止编译。

## 页面截图

- `page-login.png`：登录页
- `page-profile-pets.png`：主人信息 + 宠物列表页
- `page-medicine-store.png`：药物库存页
- `page-plans.png`：喂药计划页

## 配置与数据库设计

- `conn-string-code.png`：`config.py` 和 `db.py` 中数据库连接代码截图
- `navicat-er.png`：Navicat 生成的关系图截图

## 事务删除

- `delete-app-code.png`：删除功能的高级语言代码截图
- `delete-sql-code.png`：删除事务或相关 SQL 代码截图
- `delete-demo.png`：删除前后演示截图

## 触发器添加

- `trigger-insert-app-code.png`：新增喂药计划的应用层代码截图
- `trigger-insert-sql.png`：触发器与插入 SQL 截图
- `trigger-pass-demo.png`：合法插入成功截图
- `trigger-fail-demo.png`：非法插入失败截图

## 存储过程更新

- `proc-update-app-code.png`：调用存储过程的后端代码截图
- `proc-create-sql.png`：创建存储过程截图
- `proc-exec-sql.png`：执行存储过程截图
- `proc-pass-demo.png`：库存扣减成功截图
- `proc-fail-demo.png`：库存不足或批次无效时报错截图

## 视图查询

- `view-create-sql.png`：创建视图截图
- `view-query-code.png`：后端查询视图的代码截图
- `view-demo.png`：查询结果演示截图

## Navicat 截图建议

- 关系图尽量覆盖：`owner_table`、`pet`、`cat`、`dog`、`medicine`、`medicine_store`、`medicine_plan`、`food`、`food_store`
- SQL 代码截图优先截取带对象名、条件与关键语句的部分，避免只截一小段看不出上下文
- 页面截图时尽量让浏览器窗口完整，保留标题、按钮和表格区域

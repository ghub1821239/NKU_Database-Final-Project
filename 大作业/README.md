# Pet Database Project

## 使用方法

先把 `init.sql` 导入你自己的 MySQL 数据库中，例如数据库名为 `pet`。

然后在项目根目录依次执行：

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 -m py_compile app.py db.py config.py
DB_PASSWORD='password' DB_NAME='pet' python3 app.py
```

其中：

- `DB_PASSWORD` 改成你自己的 MySQL 密码
- `DB_NAME` 改成你导入 `init.sql` 后使用的数据库名

启动成功后，访问：

```text
http://127.0.0.1:5000
```

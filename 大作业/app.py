import json
import re
from functools import wraps

from flask import Flask, jsonify, request, send_from_directory, session

from config import Config
from db import get_cursor, set_log_context, write_select_log


app = Flask(__name__)
app.secret_key = Config.SECRET_KEY


def json_response(data=None, message="ok", status=200):
    payload = {
        "message": message,
        "data": data,
    }
    return jsonify(payload), status


def require_json():
    return request.get_json(silent=True) or {}


def require_fields(payload, field_names):
    missing_fields = [field_name for field_name in field_names if payload.get(field_name) in (None, "")]
    if missing_fields:
        return json_response(message=f"缺少字段: {', '.join(missing_fields)}", status=400)
    return None


def validate_sex(value, field_name):
    if value is None:
        return None
    if value not in ("男", "女"):
        return json_response(message=f"{field_name} 只能是 男 或 女", status=400)
    return None


def validate_category(value, field_name):
    if value is None:
        return None
    if value not in ("猫", "狗"):
        return json_response(message=f"{field_name} 只能是 猫 或 狗", status=400)
    return None


def validate_positive_int(value, field_name, allow_zero=False):
    if value is None or value == "":
        return json_response(message=f"{field_name} 不能为空", status=400)
    try:
        number = int(value)
    except (TypeError, ValueError):
        return json_response(message=f"{field_name} 必须是整数", status=400)
    if allow_zero:
        if number < 0:
            return json_response(message=f"{field_name} 不能小于 0", status=400)
    else:
        if number <= 0:
            return json_response(message=f"{field_name} 必须大于 0", status=400)
    return None


def validate_password_strength(password):
    if password is None or password == "":
        return json_response(message="新密码不能为空", status=400)
    if len(password) < 8 or not re.search(r"[A-Z]", password) or not re.search(r"[a-z]", password) or not re.search(r"[0-9]", password):
        return json_response(message="新密码格式不对，应至少 8 位并包含大小写和数字", status=400)
    return None


def password_format_error_response():
    return json_response(message="新密码格式不对，应至少 8 位并包含大小写和数字", status=400)


def get_owner_password(cursor, owner_id):
    cursor.execute(
        """
        SELECT owner_password
        FROM owner_table
        WHERE owner_id = %s
        """,
        (owner_id,),
    )
    row = cursor.fetchone()
    return row["owner_password"] if row else None


def fetch_owner_profile(cursor, owner_id):
    cursor.execute(
        """
        SELECT owner_id, owner_nickname, owner_phone, owner_address, owner_birthday, owner_sex
        FROM owner_table
        WHERE owner_id = %s
        """,
        (owner_id,),
    )
    return cursor.fetchone()


def fetch_owner_pet(cursor, owner_id, pet_id):
    cursor.execute(
        """
        SELECT *
        FROM v_owner_pet_detail
        WHERE owner_id = %s
          AND pet_id = %s
        """,
        (owner_id, pet_id),
    )
    return cursor.fetchone()


def current_app_user_id():
    return session.get("owner_id")


def normalize_owner_id(raw_owner_id):
    if raw_owner_id is None:
        return None

    text = str(raw_owner_id).strip()
    if not text.isdigit():
        return None

    return int(text)


def format_owner_id(owner_id):
    return f"{int(owner_id):05d}"


def enrich_owner_fields(record):
    if not record:
        return record

    new_record = dict(record)
    if "owner_id" in new_record and new_record["owner_id"] is not None:
        new_record["owner_code"] = format_owner_id(new_record["owner_id"])
    return new_record


def enrich_owner_fields_list(records):
    return [enrich_owner_fields(record) for record in records]


def login_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        if not current_app_user_id():
            return json_response(message="please login first", status=401)
        return func(*args, **kwargs)

    return wrapper


def require_owner_access(owner_id):
    if current_app_user_id() != owner_id:
        return json_response(message="forbidden", status=403)
    return None


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,PATCH,DELETE,OPTIONS"
    return response


@app.route("/health", methods=["GET"])
def health():
    return json_response({"service": "pet-backend"})


@app.route("/", methods=["GET"])
def index():
    return send_from_directory("static", "index.html")


@app.route("/favicon.ico", methods=["GET"])
def favicon():
    return ("", 204)


@app.route("/auth/login", methods=["POST"])
def login():
    payload = request.get_json(silent=True) or {}
    owner_id = normalize_owner_id(payload.get("owner_id"))
    password = payload.get("password")

    if not owner_id or not password:
        return json_response(message="owner_id and password are required", status=400)

    with get_cursor() as (connection, cursor):
        try:
            cursor.execute(
                """
                SELECT owner_id, owner_nickname, owner_phone, owner_address, owner_birthday, owner_sex
                FROM owner_table
                WHERE owner_id = %s
                  AND owner_password = %s
                """,
                (owner_id, password),
            )
            owner = cursor.fetchone()
            if not owner:
                connection.rollback()
                return json_response(message="账号或密码不匹配", status=401)

            owner = enrich_owner_fields(owner)
            session["owner_id"] = owner["owner_id"]
            session["owner_nickname"] = owner["owner_nickname"]
            connection.commit()
            return json_response(owner, message="login success")
        except Exception as exc:
            connection.rollback()
            error_text = str(exc)
            if "owner_password" in error_text:
                return json_response(message="数据库中缺少 owner_password 字段，请先更新表结构", status=500)
            return json_response(message=error_text, status=500)


@app.route("/auth/logout", methods=["POST"])
def logout():
    session.clear()
    return json_response(message="logout success")


@app.route("/me", methods=["GET"])
@login_required
def get_me():
    owner_id = current_app_user_id()

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看本人信息")
        write_select_log(cursor, "owner_table", "查看本人信息", json.dumps({"owner_id": owner_id}))
        cursor.execute(
            """
            SELECT owner_id, owner_nickname, owner_phone, owner_address, owner_birthday, owner_sex
            FROM owner_table
            WHERE owner_id = %s
            """,
            (owner_id,),
        )
        row = cursor.fetchone()
        connection.commit()
        if not row:
            return json_response(message="owner not found", status=404)
        return json_response(enrich_owner_fields(row))


@app.route("/me", methods=["PUT"])
@login_required
def update_me():
    owner_id = current_app_user_id()
    payload = require_json()

    sex_error = validate_sex(payload.get("owner_sex"), "主人性别")
    if sex_error:
        return sex_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "修改本人信息")
            cursor.execute(
                """
                UPDATE owner_table
                SET owner_nickname = COALESCE(%s, owner_nickname),
                    owner_phone = COALESCE(%s, owner_phone),
                    owner_address = %s,
                    owner_birthday = %s,
                    owner_sex = %s
                WHERE owner_id = %s
                """,
                (
                    payload.get("owner_nickname"),
                    payload.get("owner_phone"),
                    payload.get("owner_address"),
                    payload.get("owner_birthday"),
                    payload.get("owner_sex"),
                    owner_id,
                ),
            )
            row = fetch_owner_profile(cursor, owner_id)
            connection.commit()
            return json_response(enrich_owner_fields(row), message="owner updated")
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/me/password", methods=["PUT"])
@login_required
def update_my_password():
    owner_id = current_app_user_id()
    payload = require_json()
    fields_error = require_fields(payload, ["old_password", "new_password"])
    if fields_error:
        return fields_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "修改本人密码")
            current_password = get_owner_password(cursor, owner_id)
            if current_password is None:
                connection.rollback()
                return json_response(message="owner not found", status=404)
            if current_password != payload["old_password"]:
                connection.rollback()
                return json_response(message="旧密码不正确", status=400)

            password_error = validate_password_strength(payload["new_password"])
            if password_error:
                connection.rollback()
                return password_error

            cursor.execute(
                """
                UPDATE owner_table
                SET owner_password = %s
                WHERE owner_id = %s
                """,
                (payload["new_password"], owner_id),
            )
            connection.commit()
            return json_response(message="密码修改成功")
        except Exception as exc:
            connection.rollback()
            error_text = str(exc)
            if "check constraint" in error_text.lower() or "owner_table_chk" in error_text.lower():
                return password_format_error_response()
            return json_response(message=str(exc), status=400)


@app.route("/owners/<int:owner_id>", methods=["GET"])
@login_required
def get_owner_detail(owner_id):
    access_error = require_owner_access(owner_id)
    if access_error:
        return access_error

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看本人信息")
        write_select_log(
            cursor,
            "owner_table",
            "查看本人信息",
            json.dumps({"owner_id": owner_id}),
        )
        cursor.execute(
            """
            SELECT owner_id, owner_nickname, owner_phone, owner_address, owner_birthday, owner_sex
            FROM owner_table
            WHERE owner_id = %s
            """,
            (owner_id,),
        )
        row = cursor.fetchone()
        connection.commit()
        if not row:
            return json_response(message="owner not found", status=404)
        return json_response(enrich_owner_fields(row))


@app.route("/owners/<int:owner_id>/pets", methods=["GET"])
@login_required
def get_owner_pets(owner_id):
    access_error = require_owner_access(owner_id)
    if access_error:
        return access_error

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看本人的全部宠物")
        write_select_log(
            cursor,
            "v_owner_pet_detail",
            "查看本人的全部宠物",
            json.dumps({"owner_id": owner_id}),
        )
        cursor.execute(
            """
            SELECT *
            FROM v_owner_pet_detail
            WHERE owner_id = %s
            ORDER BY pet_id
            """,
            (owner_id,),
        )
        rows = cursor.fetchall()
        connection.commit()
        return json_response(enrich_owner_fields_list(rows))


@app.route("/me/pets", methods=["GET"])
@login_required
def get_my_pets():
    return get_owner_pets(current_app_user_id())


@app.route("/pets/<int:pet_id>", methods=["PUT"])
@login_required
def update_pet(pet_id):
    owner_id = current_app_user_id()
    payload = require_json()

    sex_error = validate_sex(payload.get("pet_sex"), "宠物性别")
    if sex_error:
        return sex_error

    category_error = validate_category(payload.get("pet_category"), "宠物种类")
    if category_error:
        return category_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "修改宠物信息")
            cursor.execute(
                """
                SELECT pet_id, pet_category
                FROM pet
                WHERE pet_id = %s
                  AND owner_id = %s
                """,
                (pet_id, owner_id),
            )
            pet_row = cursor.fetchone()
            if not pet_row:
                connection.rollback()
                return json_response(message="pet not found", status=404)

            old_category = pet_row["pet_category"]
            new_category = payload.get("pet_category") or old_category

            cursor.execute(
                """
                UPDATE pet
                SET pet_name = COALESCE(%s, pet_name),
                    pet_sex = %s,
                    pet_birthday = COALESCE(%s, pet_birthday),
                    pet_category = %s
                WHERE pet_id = %s
                  AND owner_id = %s
                """,
                (
                    payload.get("pet_name"),
                    payload.get("pet_sex"),
                    payload.get("pet_birthday"),
                    new_category,
                    pet_id,
                    owner_id,
                ),
            )

            if new_category != old_category:
                cursor.execute(
                    """
                    DELETE FROM medicine_plan
                    WHERE pet_id = %s
                    """,
                    (pet_id,),
                )

                if new_category == "猫":
                    cursor.execute("DELETE FROM dog WHERE pet_id = %s", (pet_id,))
                    cursor.execute(
                        """
                        INSERT INTO cat(pet_id, cat_claw_cycle, cat_litter)
                        VALUES(%s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            cat_claw_cycle = VALUES(cat_claw_cycle),
                            cat_litter = VALUES(cat_litter)
                        """,
                        (pet_id, payload.get("cat_claw_cycle") or 14, payload.get("cat_litter")),
                    )
                else:
                    cursor.execute("DELETE FROM cat WHERE pet_id = %s", (pet_id,))
                    cursor.execute(
                        """
                        INSERT INTO dog(pet_id, dog_walk_level, dog_license_no)
                        VALUES(%s, %s, %s)
                        ON DUPLICATE KEY UPDATE
                            dog_walk_level = VALUES(dog_walk_level),
                            dog_license_no = VALUES(dog_license_no)
                        """,
                        (pet_id, payload.get("dog_walk_level"), payload.get("dog_license_no")),
                    )
            elif new_category == "猫":
                cursor.execute(
                    """
                    UPDATE cat
                    SET cat_claw_cycle = %s,
                        cat_litter = %s
                    WHERE pet_id = %s
                    """,
                    (payload.get("cat_claw_cycle"), payload.get("cat_litter"), pet_id),
                )
            else:
                cursor.execute(
                    """
                    UPDATE dog
                    SET dog_walk_level = %s,
                        dog_license_no = %s
                    WHERE pet_id = %s
                    """,
                    (payload.get("dog_walk_level"), payload.get("dog_license_no"), pet_id),
                )

            row = fetch_owner_pet(cursor, owner_id, pet_id)
            connection.commit()
            return json_response(enrich_owner_fields(row), message="pet updated")
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/owners/<int:owner_id>/food-store", methods=["GET"])
@login_required
def get_owner_food_store(owner_id):
    access_error = require_owner_access(owner_id)
    if access_error:
        return access_error

    expire_before = request.args.get("expire_before")

    sql = """
        SELECT *
        FROM v_food_store_detail
        WHERE owner_id = %s
    """
    params = [owner_id]
    query_params = {"owner_id": owner_id}

    if expire_before:
        sql += " AND food_store_expire_time <= %s"
        params.append(expire_before)
        query_params["expire_before"] = expire_before

    sql += " ORDER BY food_store_expire_time, food_store_batch_no"

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看本人的全部食品库存")
        write_select_log(
            cursor,
            "v_food_store_detail",
            "查看本人的全部食品库存",
            json.dumps(query_params),
        )
        cursor.execute(sql, tuple(params))
        rows = cursor.fetchall()
        connection.commit()
        return json_response(rows)


@app.route("/me/food-store", methods=["GET"])
@login_required
def get_my_food_store():
    return get_owner_food_store(current_app_user_id())


@app.route("/foods", methods=["GET"])
@login_required
def get_food_dictionary():
    pet_category = request.args.get("pet_category")
    owner_id = current_app_user_id()

    sql = """
        SELECT
            f.food_id,
            f.food_name,
            f.food_category,
            fm.food_manu_id,
            fm.food_manu_phone,
            fm.food_manu_addr
        FROM food f
        LEFT JOIN food_manu fm
          ON f.food_manu_id = fm.food_manu_id
        WHERE 1 = 1
    """
    params = []
    if pet_category:
        sql += " AND f.food_category = %s"
        params.append(pet_category)
    sql += " ORDER BY f.food_category, f.food_id"

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看食物字典")
        write_select_log(cursor, "food", "查看食物字典", json.dumps({"pet_category": pet_category}))
        cursor.execute(sql, tuple(params))
        rows = cursor.fetchall()
        connection.commit()
        return json_response(rows)


@app.route("/me/food-store", methods=["POST"])
@login_required
def create_food_store():
    owner_id = current_app_user_id()
    payload = require_json()
    fields_error = require_fields(payload, ["food_id", "food_store_batch_no", "food_store_expire_time", "food_store_remaining_amount"])
    if fields_error:
        return fields_error

    amount_error = validate_positive_int(payload.get("food_store_remaining_amount"), "食品剩余量")
    if amount_error:
        return amount_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "新增食品库存")
            cursor.execute(
                """
                INSERT INTO food_store(
                    food_id, owner_id, food_store_batch_no, food_store_expire_time, food_store_remaining_amount
                ) VALUES(%s, %s, %s, %s, %s)
                """,
                (
                    payload["food_id"],
                    owner_id,
                    payload["food_store_batch_no"],
                    payload["food_store_expire_time"],
                    payload["food_store_remaining_amount"],
                ),
            )
            cursor.execute(
                """
                SELECT *
                FROM v_food_store_detail
                WHERE owner_id = %s
                  AND food_id = %s
                  AND food_store_batch_no = %s
                """,
                (owner_id, payload["food_id"], payload["food_store_batch_no"]),
            )
            row = cursor.fetchone()
            connection.commit()
            return json_response(row, message="food store created")
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/me/food-store/<int:food_id>/<int:batch_no>", methods=["PUT"])
@login_required
def update_food_store(food_id, batch_no):
    owner_id = current_app_user_id()
    payload = require_json()
    amount_error = validate_positive_int(payload.get("food_store_remaining_amount"), "食品剩余量")
    if amount_error:
        return amount_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "修改食品库存")
            cursor.execute(
                """
                UPDATE food_store
                SET food_store_expire_time = %s,
                    food_store_remaining_amount = %s
                WHERE owner_id = %s
                  AND food_id = %s
                  AND food_store_batch_no = %s
                """,
                (
                    payload.get("food_store_expire_time"),
                    payload.get("food_store_remaining_amount"),
                    owner_id,
                    food_id,
                    batch_no,
                ),
            )
            cursor.execute(
                """
                SELECT *
                FROM v_food_store_detail
                WHERE owner_id = %s
                  AND food_id = %s
                  AND food_store_batch_no = %s
                """,
                (owner_id, food_id, batch_no),
            )
            row = cursor.fetchone()
            connection.commit()
            return json_response(row, message="food store updated")
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/me/food-feed", methods=["POST"])
@login_required
def feed_food():
    owner_id = current_app_user_id()
    payload = require_json()
    fields_error = require_fields(payload, ["pet_id", "food_id", "amount"])
    if fields_error:
        return fields_error

    amount_error = validate_positive_int(payload.get("amount"), "喂食量")
    if amount_error:
        return amount_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "执行食品喂食")
            cursor.execute(
                """
                SELECT pet_id, pet_category, pet_name
                FROM pet
                WHERE pet_id = %s
                  AND owner_id = %s
                """,
                (payload["pet_id"], owner_id),
            )
            pet_row = cursor.fetchone()
            if not pet_row:
                connection.rollback()
                return json_response(message="pet not found", status=404)

            cursor.execute(
                """
                SELECT food_id, food_name, food_category
                FROM food
                WHERE food_id = %s
                """,
                (payload["food_id"],),
            )
            food_row = cursor.fetchone()
            if not food_row:
                connection.rollback()
                return json_response(message="food not found", status=404)
            if food_row["food_category"] != pet_row["pet_category"]:
                connection.rollback()
                return json_response(message="该食物与宠物种类不匹配", status=400)

            cursor.execute(
                """
                SELECT food_store_batch_no, food_store_remaining_amount, food_store_expire_time
                FROM food_store
                WHERE owner_id = %s
                  AND food_id = %s
                  AND food_store_remaining_amount >= %s
                ORDER BY food_store_expire_time ASC, food_store_batch_no ASC
                LIMIT 1
                """,
                (owner_id, payload["food_id"], payload["amount"]),
            )
            stock_row = cursor.fetchone()
            if not stock_row:
                connection.rollback()
                return json_response(message="没有可用食品批次可完成本次喂食", status=400)

            cursor.execute(
                """
                UPDATE food_store
                SET food_store_remaining_amount = food_store_remaining_amount - %s
                WHERE owner_id = %s
                  AND food_id = %s
                  AND food_store_batch_no = %s
                """,
                (payload["amount"], owner_id, payload["food_id"], stock_row["food_store_batch_no"]),
            )
            connection.commit()
            return json_response(
                {
                    "pet_id": payload["pet_id"],
                    "pet_name": pet_row["pet_name"],
                    "food_id": payload["food_id"],
                    "food_name": food_row["food_name"],
                    "amount": int(payload["amount"]),
                    "food_store_batch_no": stock_row["food_store_batch_no"],
                },
                message="food fed",
            )
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/owners/<int:owner_id>/medicine-store", methods=["GET"])
@login_required
def get_owner_medicine_store(owner_id):
    access_error = require_owner_access(owner_id)
    if access_error:
        return access_error

    expire_before = request.args.get("expire_before")

    sql = """
        SELECT *
        FROM v_medicine_store_detail
        WHERE owner_id = %s
    """
    params = [owner_id]
    query_params = {"owner_id": owner_id}

    if expire_before:
        sql += " AND medicine_store_expire_time <= %s"
        params.append(expire_before)
        query_params["expire_before"] = expire_before

    sql += " ORDER BY medicine_store_expire_time, medicine_batch_no"

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看本人的全部药物库存")
        write_select_log(
            cursor,
            "v_medicine_store_detail",
            "查看本人的全部药物库存",
            json.dumps(query_params),
        )
        cursor.execute(sql, tuple(params))
        rows = cursor.fetchall()
        connection.commit()
        return json_response(rows)


@app.route("/me/medicine-store", methods=["GET"])
@login_required
def get_my_medicine_store():
    return get_owner_medicine_store(current_app_user_id())


@app.route("/medicines", methods=["GET"])
@login_required
def get_medicine_dictionary():
    pet_category = request.args.get("pet_category")
    owner_id = current_app_user_id()

    sql = """
        SELECT
            m.medicine_id,
            m.medicine_name,
            m.medicine_instruction,
            m.medicine_category,
            mm.medicine_manu_id,
            mm.medicine_manu_phone,
            mm.medicine_manu_addr
        FROM medicine m
        LEFT JOIN medicine_manu mm
          ON m.medicine_manu_id = mm.medicine_manu_id
        WHERE 1 = 1
    """
    params = []
    if pet_category:
        sql += " AND m.medicine_category = %s"
        params.append(pet_category)
    sql += " ORDER BY m.medicine_category, m.medicine_id"

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看药物字典")
        write_select_log(cursor, "medicine", "查看药物字典", json.dumps({"pet_category": pet_category}))
        cursor.execute(sql, tuple(params))
        rows = cursor.fetchall()
        connection.commit()
        return json_response(rows)


@app.route("/me/medicine-store", methods=["POST"])
@login_required
def create_medicine_store():
    owner_id = current_app_user_id()
    payload = require_json()
    fields_error = require_fields(payload, ["medicine_id", "medicine_batch_no", "medicine_store_expire_time", "medicine_store_remaining_amount"])
    if fields_error:
        return fields_error

    amount_error = validate_positive_int(payload.get("medicine_store_remaining_amount"), "药物剩余量")
    if amount_error:
        return amount_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "新增药物库存")
            cursor.execute(
                """
                INSERT INTO medicine_store(
                    medicine_id, owner_id, medicine_batch_no, medicine_store_expire_time, medicine_store_remaining_amount
                ) VALUES(%s, %s, %s, %s, %s)
                """,
                (
                    payload["medicine_id"],
                    owner_id,
                    payload["medicine_batch_no"],
                    payload["medicine_store_expire_time"],
                    payload["medicine_store_remaining_amount"],
                ),
            )
            cursor.execute(
                """
                SELECT *
                FROM v_medicine_store_detail
                WHERE owner_id = %s
                  AND medicine_id = %s
                  AND medicine_batch_no = %s
                """,
                (owner_id, payload["medicine_id"], payload["medicine_batch_no"]),
            )
            row = cursor.fetchone()
            connection.commit()
            return json_response(row, message="medicine store created")
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/me/medicine-store/<int:medicine_id>/<int:batch_no>", methods=["PUT"])
@login_required
def update_medicine_store(medicine_id, batch_no):
    owner_id = current_app_user_id()
    payload = require_json()
    amount_error = validate_positive_int(payload.get("medicine_store_remaining_amount"), "药物剩余量")
    if amount_error:
        return amount_error

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "修改药物库存")
            cursor.execute(
                """
                UPDATE medicine_store
                SET medicine_store_expire_time = %s,
                    medicine_store_remaining_amount = %s
                WHERE owner_id = %s
                  AND medicine_id = %s
                  AND medicine_batch_no = %s
                """,
                (
                    payload.get("medicine_store_expire_time"),
                    payload.get("medicine_store_remaining_amount"),
                    owner_id,
                    medicine_id,
                    batch_no,
                ),
            )
            cursor.execute(
                """
                SELECT *
                FROM v_medicine_store_detail
                WHERE owner_id = %s
                  AND medicine_id = %s
                  AND medicine_batch_no = %s
                """,
                (owner_id, medicine_id, batch_no),
            )
            row = cursor.fetchone()
            connection.commit()
            return json_response(row, message="medicine store updated")
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.route("/pets/<int:pet_id>/plans", methods=["GET"])
@login_required
def get_pet_plans(pet_id):
    before_time = request.args.get("before_time")
    owner_id = current_app_user_id()

    sql = """
        SELECT *
        FROM v_pet_medicine_plan_detail
        WHERE pet_id = %s
          AND owner_id = %s
    """
    params = [pet_id, owner_id]
    query_params = {"pet_id": pet_id}

    if before_time:
        sql += " AND medicine_feed_time <= %s"
        params.append(before_time)
        query_params["before_time"] = before_time

    sql += " ORDER BY medicine_feed_time"

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看某只宠物的喂药计划")
        write_select_log(
            cursor,
            "v_pet_medicine_plan_detail",
            "查看某只宠物的喂药计划",
            json.dumps(query_params),
        )
        cursor.execute(sql, tuple(params))
        rows = cursor.fetchall()
        connection.commit()
        return json_response(rows)


@app.route("/me/plans", methods=["GET"])
@login_required
def get_my_plans():
    owner_id = current_app_user_id()
    pet_id = request.args.get("pet_id", type=int)
    before_time = request.args.get("before_time")

    sql = """
        SELECT *
        FROM v_pet_medicine_plan_detail
        WHERE owner_id = %s
    """
    params = [owner_id]
    query_params = {"owner_id": owner_id}

    if pet_id:
        sql += " AND pet_id = %s"
        params.append(pet_id)
        query_params["pet_id"] = pet_id

    if before_time:
        sql += " AND medicine_feed_time <= %s"
        params.append(before_time)
        query_params["before_time"] = before_time

    sql += " ORDER BY medicine_feed_time"

    with get_cursor() as (connection, cursor):
        set_log_context(cursor, owner_id, "查看本人的喂药计划")
        write_select_log(
            cursor,
            "v_pet_medicine_plan_detail",
            "查看本人的喂药计划",
            json.dumps(query_params),
        )
        cursor.execute(sql, tuple(params))
        rows = cursor.fetchall()
        connection.commit()
        return json_response(rows)


@app.route("/plans/<int:plan_id>/execute", methods=["POST"])
@login_required
def execute_plan(plan_id):
    payload = request.get_json(silent=True) or {}
    medicine_batch_no = payload.get("medicine_batch_no")
    owner_id = current_app_user_id()

    with get_cursor() as (connection, cursor):
        try:
            set_log_context(cursor, owner_id, "执行喂药计划")
            if not medicine_batch_no:
                cursor.execute(
                    """
                    SELECT ms.medicine_batch_no
                    FROM medicine_store ms
                    JOIN medicine_plan mp
                      ON ms.medicine_id = mp.medicine_id
                    WHERE mp.plan_id = %s
                      AND ms.owner_id = %s
                      AND ms.medicine_store_remaining_amount >= mp.medicine_feed_amount
                    ORDER BY ms.medicine_store_expire_time ASC, ms.medicine_batch_no ASC
                    LIMIT 1
                    """,
                    (plan_id, owner_id),
                )
                batch_row = cursor.fetchone()
                if not batch_row:
                    connection.rollback()
                    return json_response(message="没有可用药物批次可执行该计划", status=400)
                medicine_batch_no = batch_row["medicine_batch_no"]

            cursor.callproc(
                "proc_execute_medicine_plan",
                (plan_id, owner_id, medicine_batch_no),
            )
            connection.commit()
            return json_response(
                {
                    "plan_id": plan_id,
                    "owner_id": owner_id,
                    "medicine_batch_no": medicine_batch_no,
                },
                message="plan executed",
            )
        except Exception as exc:
            connection.rollback()
            return json_response(message=str(exc), status=400)


@app.errorhandler(Exception)
def handle_error(error):
    error_text = str(error)
    if "check constraint" in error_text.lower() or "owner_table_chk" in error_text.lower():
        return password_format_error_response()
    return json_response(message=str(error), status=500)


if __name__ == "__main__":
    app.run(host=Config.HOST, port=Config.PORT, debug=Config.DEBUG)

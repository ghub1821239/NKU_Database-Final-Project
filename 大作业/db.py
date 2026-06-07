from contextlib import contextmanager

import pymysql
from pymysql.cursors import DictCursor

from config import Config


def create_connection():
    return pymysql.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=False,
    )


@contextmanager
def get_cursor():
    connection = create_connection()
    try:
        with connection.cursor() as cursor:
            yield connection, cursor
    finally:
        connection.close()


def set_log_context(cursor, app_user_id=None, action_note=None):
    cursor.execute("SET @app_user_id = %s", (app_user_id,))
    cursor.execute("SET @app_action_note = %s", (action_note,))


def write_select_log(cursor, target_name, query_name, query_params=None):
    cursor.callproc(
        "proc_write_select_log",
        (target_name, query_name, query_params),
    )


import sqlite3, os, sys
from sqlite3 import Error

def create_connection(db_file):
    """ create a database connection to the SQLite database
        specified by db_file
    :param db_file: database file
    :return: Connection object or None
    """
    conn = None
    try:
        conn = sqlite3.connect(db_file)
        return conn
    except Error as e:
        print(e)

    return conn

def create_table(conn, create_table_sql):
    """ create a table from the create_table_sql statement
    :param conn: Connection object
    :param create_table_sql: a CREATE TABLE statement
    :return:
    """
    try:
        c = conn.cursor()
        c.execute(create_table_sql)
    except Error as e:
        print(e)

def insert_data(conn, path, id):
    try:
        c = conn.cursor()
        with open(path, "r") as file:
            content = file.read()
            request = (id, content)
            # print(id + ": " + content)
            c.execute('INSERT INTO stats(id, def_text) VALUES(?,?)', request)
        conn.commit()
    except Error as e:
        print(e)

def create():
    database = "/tmp/stats/stats.db"
    conn = create_connection(database)
    sql_create_projects_table = "CREATE TABLE stats (id VARCHAR(5), def_text TEXT)"

    # create tables
    if conn is not None:
        # create stats table
        create_table(conn, sql_create_projects_table)
        conn.close()
    else:
        print("Error! cannot create the database connection.")

def insert(id):
    database = "/tmp/stats/stats.db"
    conn = create_connection(database)
    if conn is not None:
        insert_data(conn, "/tmp/stats/sector.stats", id)
        conn.close()
    else:
        print("Error! cannot create the database connection.")

if sys.argv[1] == 'create':
    create()

if sys.argv[1] == 'insert':
    insert(sys.argv[2])

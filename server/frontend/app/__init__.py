#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import scoped_session, mapper
from sqlalchemy.orm.session import sessionmaker
import sys
import os

# Platform-aware database path
if os.path.exists("/opt/spyguard/database/database.sqlite3"):
    db_path = "/opt/spyguard/database/database.sqlite3"
else:
    parent = "/".join(sys.path[0].split("/")[:-2])
    db_path = '{}/database.sqlite3'.format(parent)

engine = create_engine('sqlite:///{}'.format(db_path), convert_unicode=True)
metadata = MetaData(bind=engine)
session = scoped_session(sessionmaker(autocommit=False, autoflush=False, bind=engine))

class Model(object):
    query = session.query_property()

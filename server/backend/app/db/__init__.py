#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import scoped_session, mapper
from sqlalchemy.orm.session import sessionmaker

engine = create_engine('sqlite:////opt/spyguard/database/database.sqlite3', convert_unicode=True)
metadata = MetaData(bind=engine)
session = scoped_session(sessionmaker(
    autocommit=False, autoflush=False, bind=engine))


class Model(object):
    query = session.query_property()

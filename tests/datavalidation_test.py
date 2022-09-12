import pytest
from subprocess import TimeoutExpired
from ftw import logchecker, testrunner, http
from ftw.ruleset import Input
import os
from ml_model_server import placeholder as ph
def test_scoretype():
    s = ph.predict("POST", "localhost", [], 16, 12)
    assert type(s) == type(5)
    
'''
def test_query():
    b = ph.query_ml()
    assert type(b) == type(('a', 1))
'''


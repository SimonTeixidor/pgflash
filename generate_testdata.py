#!/usr/bin/env python3
import random
import itertools
import sys

def sql_generator(insert, vals):
    yield insert
    yield next(vals)
    for v in vals:
        yield ','
        yield v
    yield ';'


users = ["s"+str(i) for i in range(0,100)]
decks = [(i, str(j)) for i in users for j in range(0,10)]
user_inserts = ("drop role " + i + "; insert into flash_card_user(name,pass) values ('"+i+"','1234');" for i in users)
deck_insert = sql_generator("insert into pub.deck(owner, name) values ", 
        ("('{}', '{}')".format(i,j) for i,j in decks))
card_insert = sql_generator("insert into pub.card(front,back,bucket,deck_owner, deck_name) values ",
        (("('front{}', 'back3',{}, '{}','{}')".format(i,random.randint(1,100),j,k) for i in range(0, 100) for j,k in decks)))

sys.stdout.writelines(itertools.chain(
            user_inserts,
            deck_insert,
            card_insert))

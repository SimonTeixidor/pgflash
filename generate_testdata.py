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


deck_insert = sql_generator("insert into deck(owner, name) values ", 
        ("('sp','"+str(i)+"')" for i in range(1,10000)))
card_insert = sql_generator("insert into card(front,back,bucket,deck_owner, deck_name) values ",
        (("('front" + str(i) + "', 'back3'," + str(random.randint(10000,1000000))+", 'sp',"
            + str(random.randint(1,9999))+")" for i in range(0, 10000))))

sys.stdout.writelines(itertools.chain(
    ["drop role sp; insert into flash_card_user(name,pass) values('sp','1');"], 
    deck_insert,
    card_insert))

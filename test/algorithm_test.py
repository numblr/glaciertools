#!/usr/bin/python

from pprint import pprint

def next_itr(last):
    for i in range(1, last + 1):
        yield str(i)

def calculate_root(level, itr):
    # Base case level
    if level == 0:
        return next(itr, None)

    left = calculate_root(level - 1, itr)
    right = calculate_root(level - 1, itr)

    return combine(left, right) if right else left

def calculate_hash(left, level, itr):
    if not left:
        left = calculate_root(0, itr)
        return calculate_hash(left, 0, itr) if left else None

    right = calculate_root(level, itr)

    return calculate_hash(combine(left, right), level + 1, itr) if right else left


def combine(a, b):
    return "[" + ",".join([a,b]) + "]"

if __name__ == '__main__':
    def assertEquals(a, b):
        if not a == b:
            raise ValueError(a + " - " + b)

    assertEquals(calculate_hash(None, 0, next_itr(2)), "[1,2]")
    assertEquals(calculate_hash(None, 0, next_itr(3)), "[[1,2],3]")
    assertEquals(calculate_hash(None, 0, next_itr(4)), "[[1,2],[3,4]]")
    assertEquals(calculate_hash(None, 0, next_itr(5)), "[[[1,2],[3,4]],5]")
    assertEquals(calculate_hash(None, 0, next_itr(6)), "[[[1,2],[3,4]],[5,6]]")
    assertEquals(calculate_hash(None, 0, next_itr(7)), "[[[1,2],[3,4]],[[5,6],7]]")
    assertEquals(calculate_hash(None, 0, next_itr(8)), "[[[1,2],[3,4]],[[5,6],[7,8]]]")
    assertEquals(calculate_hash(None, 0, next_itr(9)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],9]")
    assertEquals(calculate_hash(None, 0, next_itr(10)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[9,10]]")
    assertEquals(calculate_hash(None, 0, next_itr(11)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[[9,10],11]]")
    assertEquals(calculate_hash(None, 0, next_itr(12)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[[9,10],[11,12]]]")
    assertEquals(calculate_hash(None, 0, next_itr(13)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[[[9,10],[11,12]],13]]")
    assertEquals(calculate_hash(None, 0, next_itr(14)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[[[9,10],[11,12]],[13,14]]]")
    assertEquals(calculate_hash(None, 0, next_itr(15)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[[[9,10],[11,12]],[[13,14],15]]]")
    assertEquals(calculate_hash(None, 0, next_itr(16)), "[[[[1,2],[3,4]],[[5,6],[7,8]]],[[[9,10],[11,12]],[[13,14],[15,16]]]]")

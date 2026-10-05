#!/usr/bin/env python3
"""Generates original SAT-style Math practice questions.

Every answer is computed from the parameters (never typed by hand), and
verify() re-checks each result independently, so the bank cannot ship a
wrong key. Run from the repo root:

    python3 tools/gen_sat_math.py
"""
import json
import math
import random
from fractions import Fraction

OUT = "assets/sat/questions/sat_math_questions.json"
ALG, ADV, PSD, GEO = (
    "Algebra",
    "Advanced Math",
    "Problem-Solving & Data Analysis",
    "Geometry & Trigonometry",
)


def f(x):
    """Format a number: ints plain, Fractions as a/b, floats trimmed."""
    if isinstance(x, Fraction):
        return str(x.numerator) if x.denominator == 1 else f"{x.numerator}/{x.denominator}"
    if isinstance(x, float):
        s = f"{x:.2f}".rstrip("0").rstrip(".")
        return s
    return str(x)


def lin(a, b, v="x"):
    """'2x + 3' style linear expression."""
    head = (f"{a}{v}" if a not in (1, -1) else (v if a == 1 else f"-{v}"))
    if b == 0:
        return head
    return f"{head} {'+' if b > 0 else '-'} {abs(b)}"


def add(b, v="x"):
    return f"{v} {'+' if b >= 0 else '-'} {abs(b)}"


def money(v):
    t = f"${v:,.2f}"
    return t[:-3] if t.endswith(".00") else t


def sgn(b):
    return f"{'+' if b >= 0 else '-'} {abs(b)}"


class Gen:
    def __init__(self, seed=2026):
        self.r = random.Random(seed)
        self.items = []
        self.seen = set()

    def make(self, topic, diff, prompt, correct, wrongs, expl, check=True):
        r = self.r
        correct = f(correct)
        pool = []
        for w in wrongs:
            w = f(w)
            if w != correct and w not in pool:
                pool.append(w)
        if len(pool) < 3:
            return False
        picks = pool[:3] if len(pool) == 3 else r.sample(pool[:5], 3)
        if prompt in self.seen:
            return False
        self.seen.add(prompt)
        choices = picks + [correct]
        r.shuffle(choices)
        self.items.append(
            {
                "subject": "satmath",
                "topic": topic,
                "difficulty": diff,
                "prompt": prompt,
                "choices": choices,
                "correctIndex": choices.index(correct),
                "explanation": expl,
            }
        )
        return True

    def run(self, fn, n):
        made, tries = 0, 0
        while made < n and tries < n * 40:
            tries += 1
            if fn(self):
                made += 1


# ---------------------------------------------------------------- Algebra

def t_linear_eq(g):
    r = g.r
    x, a, b = r.randint(-6, 12), r.randint(2, 9), r.randint(-8, 12)
    c = a * (x + b)
    return g.make(
        ALG, 1,
        f"If {a}({add(b)}) = {c}, what is the value of x?",
        x, [c // a + b, x + 1, x - 1, c - b, x * -1],
        f"Divide both sides by {a} to get {add(b)} = {c // a}. Then x = {c // a} {'-' if b >= 0 else '+'} {abs(b)} = {x}.",
    )


def t_system(g):
    r = g.r
    x, y = r.randint(-4, 8), r.randint(-4, 8)
    a1, b1 = r.randint(1, 4), r.randint(1, 4)
    a2, b2 = r.randint(1, 4), -r.randint(1, 4)
    if a1 * b2 - a2 * b1 == 0:
        return False
    c1, c2 = a1 * x + b1 * y, a2 * x + b2 * y
    co = lambda n: "" if n == 1 else str(n)
    s = lambda a, b: f"{co(a)}x {'+' if b > 0 else '-'} {co(abs(b))}y"
    assert a1 * x + b1 * y == c1 and a2 * x + b2 * y == c2
    return g.make(
        ALG, 2,
        f"In the system of equations {s(a1, b1)} = {c1} and {s(a2, b2)} = {c2}, what is the value of x + y?",
        x + y, [x - y, x * y, x + y + 1, x + y - 2, y],
        f"Solving the system gives x = {x} and y = {y}, which satisfy both equations. So x + y = {x + y}.",
    )


def t_slope(g):
    r = g.r
    x1, y1 = r.randint(-5, 5), r.randint(-5, 5)
    dx, m = r.randint(1, 5), r.choice([-3, -2, -1, 1, 2, 3, 4])
    x2, y2 = x1 + dx, y1 + m * dx
    return g.make(
        ALG, 1,
        f"A line passes through the points ({x1}, {y1}) and ({x2}, {y2}). What is the slope of the line?",
        m, [-m, Fraction(1, m) if m not in (1, -1) else m + 2, m + 1, m - 1, dx],
        f"Slope = (y2 - y1)/(x2 - x1) = ({y2} - {y1 if y1 >= 0 else f'({y1})'})/({x2} - {x1 if x1 >= 0 else f'({x1})'}) = {m * dx}/{dx} = {m}.",
    )


def t_yint(g):
    r = g.r
    m, x0, y0 = r.choice([2, 3, 4, -2, -3, 5]), r.randint(1, 5), r.randint(-6, 10)
    b = y0 - m * x0
    return g.make(
        ALG, 2,
        f"A line has slope {m} and passes through the point ({x0}, {y0}). What is the y-coordinate of the point where the line crosses the y-axis?",
        b, [y0 + m * x0, y0, -b, b + m, m * x0],
        f"Use y = {m}x + b. Substituting ({x0}, {y0}) gives {y0} = {m * x0} + b, so b = {b}.",
    )


def t_cost(g):
    r = g.r
    fixed, rate, n = r.choice([20, 35, 50, 60, 75]), r.choice([4, 6, 8, 12, 15]), r.randint(3, 14)
    total = fixed + rate * n
    who = r.choice(["A gym", "A print shop", "A video-editing service", "A tutoring center"])
    unit = {"A gym": "session", "A print shop": "poster", "A video-editing service": "hour", "A tutoring center": "lesson"}[who]
    return g.make(
        ALG, 1,
        f"{who} charges a one-time fee of ${fixed} plus ${rate} per {unit}. A customer's total charge was ${total}. How many {unit}s did the customer pay for?",
        n, [(total) // rate, n + 1, n - 1, total - fixed, (total + fixed) // rate],
        f"Write {fixed} + {rate}n = {total}. Subtract {fixed}: {rate}n = {rate * n}. So n = {n}.",
    )


def t_ineq(g):
    r = g.r
    a, b, c = r.randint(2, 7), r.randint(1, 12), r.randint(10, 40)
    # a*x - b > c  -> x > (c+b)/a
    bound = Fraction(c + b, a)
    ans = math.floor(bound) + 1
    return g.make(
        ALG, 2,
        f"What is the least integer value of x that satisfies the inequality {a}x - {b} > {c}?",
        ans, [math.floor(bound), ans + 1, math.ceil(bound) - 1 if bound.denominator != 1 else ans - 2, c // a],
        f"Add {b} and divide by {a}: x > {f(bound) if bound.denominator == 1 else f'{c + b}/{a}'}. The least integer greater than that is {ans}.",
    )


def t_infinite(g):
    r = g.r
    a, b = r.randint(2, 6), r.randint(1, 9)
    mult = r.randint(2, 4)
    return g.make(
        ALG, 3,
        f"For what value of c does the system {a}x + {b}y = 7 and {a * mult}x + {b * mult}y = c have infinitely many solutions?",
        7 * mult, [7, 7 * mult + a, mult, 7 + mult, 7 * mult - b],
        f"The second equation must be a multiple of the first. Multiplying the first equation by {mult} gives {a * mult}x + {b * mult}y = {7 * mult}, so c = {7 * mult}.",
    )


def t_function_eval(g):
    r = g.r
    m, b, a = r.randint(2, 7), r.randint(-9, 9), r.randint(2, 9)
    ans = m * a + b
    return g.make(
        ALG, 1,
        f"The function f is defined by f(x) = {lin(m, b)}. What is the value of f({a})?",
        ans, [m + a + b, m * (a + b), ans + m, ans - 2 * b if b else ans + 1, m * a - b if b else ans + 2],
        f"f({a}) = {m}({a}) {'+' if b >= 0 else '-'} {abs(b)} = {ans}.",
    )


def t_interp(g):
    r = g.r
    m, b = r.randint(3, 9), r.randint(10, 60)
    scenarios = [
        (f"A plant's height in centimeters, h, t weeks after planting is modeled by h = {m}t + {b}.",
         "The number of centimeters the plant grows each week", "The plant's height, in centimeters, at planting",
         f"The number of weeks until the plant is {m} centimeters tall", f"The plant's height, in centimeters, after {m} weeks"),
        (f"The balance in dollars, d, of a savings account t months after opening is modeled by d = {m}t + {b}.",
         "The number of dollars the balance increases each month", "The opening balance, in dollars",
         f"The number of months until the balance reaches ${m}", f"The balance, in dollars, after {m} months"),
    ]
    stem, ok, w1, w2, w3 = r.choice(scenarios)
    return g.make(
        ALG, 2, stem + f" What does the number {m} represent in the model?",
        ok, [w1, w2, w3, "The total change over the whole period"],
        f"In y = mx + b form, the coefficient {m} is the rate of change per unit of time, and {b} is the starting value.",
    )


# ------------------------------------------------------------ Advanced Math

def t_quad_roots(g):
    r = g.r
    p, q = r.randint(1, 9), r.randint(1, 9)
    if p == q:
        return False
    s, pr = p + q, p * q
    return g.make(
        ADV, 2,
        f"What is the sum of the solutions to the equation x² - {s}x + {pr} = 0?",
        s, [pr, -s, s + 1, s - 1, p - q if p > q else q - p],
        f"The equation factors as (x - {p})(x - {q}) = 0, so the solutions are {p} and {q}, and their sum is {s}.",
    )


def t_positive_root(g):
    r = g.r
    p, q = r.randint(1, 9), r.randint(1, 9)
    if p == q:
        return False
    mid, const = p - q, p * q
    return g.make(
        ADV, 2,
        f"What is the positive solution to x² {sgn(mid)}x - {const} = 0?",
        q, [p, const, p + q, -q],
        f"The equation factors as (x + {p})(x - {q}) = 0, so x = -{p} or x = {q}. The positive solution is {q}.",
    )


def t_vertex(g):
    r = g.r
    h, k = r.randint(-5, 6), r.randint(-9, 9)
    return g.make(
        ADV, 2,
        f"The function f is defined by f(x) = (x {'-' if h >= 0 else '+'} {abs(h)})² {'+' if k >= 0 else '-'} {abs(k)}. What is the minimum value of f?",
        k, [h, -k, -h, k + h, k - h],
        f"A squared term is never negative, so the least value occurs when x = {h}, where (x {'-' if h >= 0 else '+'} {abs(h)})² = 0. The minimum is {k}.",
    )


def t_exp_growth(g):
    r = g.r
    p0, dbl, t = r.choice([100, 200, 250, 500, 1000]), r.choice([2, 3, 4, 5]), None
    k = r.randint(2, 4)
    t = dbl * k
    return g.make(
        ADV, 2,
        f"A bacteria culture starts with {p0} cells and doubles every {dbl} hours. Assuming this pattern continues, how many cells will there be after {t} hours?",
        p0 * 2 ** k, [p0 * 2 * k, p0 * t, p0 * 2 ** (k + 1), p0 + 2 ** k, p0 * k ** 2],
        f"After {t} hours there have been {t}/{dbl} = {k} doublings, so the count is {p0} × 2^{k} = {p0 * 2 ** k}.",
    )


def t_expand(g):
    r = g.r
    a, b = r.randint(-7, 7), r.randint(-7, 7)
    if a == 0 or b == 0 or a + b == 0:
        return False
    return g.make(
        ADV, 1,
        f"When the expression ({add(a)})({add(b)}) is written in the form x² + px + q, what is the value of p?",
        a + b, [a * b, a - b, abs(a) + abs(b), a + b + 1],
        f"Expanding gives x² + ({a} + {b})x + {a * b}, so p = {a + b}.".replace("+ -", "- "),
    )


def t_composition(g):
    r = g.r
    a, b, c, d = r.randint(2, 5), r.randint(-4, 6), r.randint(2, 4), r.randint(-3, 5)
    x = r.randint(1, 5)
    gv = c * x + d
    ans = a * gv + b
    return g.make(
        ADV, 3,
        f"If f(x) = {lin(a, b)} and g(x) = {lin(c, d)}, what is the value of f(g({x}))?",
        ans, [c * (a * x + b) + d, a * x + b + gv, ans + a, gv, a * c * x + b],
        f"First g({x}) = {c}({x}) {'+' if d >= 0 else '-'} {abs(d)} = {gv}. Then f({gv}) = {a}({gv}) {'+' if b >= 0 else '-'} {abs(b)} = {ans}.",
    )


def t_exponents(g):
    r = g.r
    a, b, c = r.randint(2, 5), r.randint(2, 4), r.randint(2, 6)
    ans = a * b - c
    return g.make(
        ADV, 2,
        f"For x > 0, which of the following is equivalent to (x^{a})^{b} / x^{c}?",
        f"x^{ans}" if ans != 1 else "x", [f"x^{a + b - c}", f"x^{a * b + c}", f"x^{a * b // max(c,1)}", f"x^{a + b + c}"],
        f"Multiply exponents in the power: (x^{a})^{b} = x^{a * b}. Dividing by x^{c} subtracts exponents: x^{a * b - c}.",
    ) if ans > 1 else False


def t_one_solution(g):
    r = g.r
    m = r.randint(2, 9)
    return g.make(
        ADV, 3,
        f"For what positive value of k does the equation x² + kx + {m * m} = 0 have exactly one real solution?",
        2 * m, [m, m * m, 4 * m, 2 * m * m],
        f"One real solution means the discriminant is zero: k² - 4({m * m}) = 0, so k² = {4 * m * m} and k = {2 * m} (positive).",
    )


def t_rational(g):
    r = g.r
    x, a, b = r.randint(2, 9), r.randint(1, 6), r.randint(1, 5)
    # (x+a)/(x-b) = c where c integer -> choose c, then ensure integer x
    c = r.randint(2, 5)
    # x + a = c(x - b) -> x = (a + c*b)/(c-1)
    num, den = a + c * b, c - 1
    if num % den != 0:
        return False
    x = num // den
    if x == b:
        return False
    return g.make(
        ADV, 3,
        f"If (x + {a})/(x - {b}) = {c}, what is the value of x?",
        x, [x + 1, c * b - a, (a + b) // 1 if (a + b) != x else x + 2, x - 1],
        f"Multiply both sides by (x - {b}): x + {a} = {c}x - {c * b}. So {a + c * b} = {c - 1}x, giving x = {x}.",
    )


# --------------------------------------------- Problem-Solving & Data Analysis

def t_percent_change(g):
    r = g.r
    price, up, down = r.choice([40, 50, 80, 120, 200]), r.choice([10, 20, 25, 50]), r.choice([10, 20, 25])
    mid = price * (100 + up) / 100
    ans = mid * (100 - down) / 100
    return g.make(
        PSD, 2,
        f"The price of a jacket is ${price}. The store raises the price by {up}%, and later reduces the new price by {down}%. What is the final price?",
        money(ans),
        [money(price * (100 + up - down) / 100), money(price), money(mid), money(price * (100 - down) / 100)],
        f"After the increase the price is {price} × {1 + up / 100:g} = {mid:g}. After the decrease it is {mid:g} × {1 - down / 100:g} = {ans:g}. Percent changes applied one after another do not simply cancel.",
    )


def t_rational(g):
    r = g.r
    x, a, b = r.randint(2, 9), r.randint(1, 6), r.randint(1, 5)
    # (x+a)/(x-b) = c where c integer -> choose c, then ensure integer x
    c = r.randint(2, 5)
    # x + a = c(x - b) -> x = (a + c*b)/(c-1)
    num, den = a + c * b, c - 1
    if num % den != 0:
        return False
    x = num // den
    if x == b:
        return False
    return g.make(
        ADV, 3,
        f"If (x + {a})/(x - {b}) = {c}, what is the value of x?",
        x, [x + 1, c * b - a, (a + b) // 1 if (a + b) != x else x + 2, x - 1],
        f"Multiply both sides by (x - {b}): x + {a} = {c}x - {c * b}. So {a + c * b} = {c - 1}x, giving x = {x}.",
    )


# --------------------------------------------- Problem-Solving & Data Analysis

def t_percent_change(g):
    r = g.r
    price, up, down = r.choice([40, 50, 80, 120, 200]), r.choice([10, 20, 25, 50]), r.choice([10, 20, 25])
    ans = price * (100 + up) * (100 - down) / 10000
    return g.make(
        PSD, 2,
        f"The price of a jacket is ${price}. The store raises the price by {up}%, and later reduces the new price by {down}%. What is the final price?",
        f"${ans:.2f}".rstrip("0").rstrip(".") if ans != int(ans) else f"${int(ans)}",
        [f"${price * (1 + (up - down) / 100):.2f}".rstrip("0").rstrip("."), f"${price}", f"${price * (1 + up/100) * (1 - down/100) + 5:.2f}".rstrip("0").rstrip("."), f"${price * (1 - down/100):.2f}".rstrip("0").rstrip(".")],
        f"After the increase the price is {price} × {1 + up/100:g} = {price * (1 + up/100):g}. After the decrease it is {price * (1 + up/100):g} × {1 - down/100:g} = {ans:g}. Percent changes do not simply cancel.",
    )


def t_ratio(g):
    r = g.r
    a, b = r.choice([(2, 3), (3, 5), (4, 7), (5, 8), (3, 4)])
    k = r.randint(3, 12)
    total = (a + b) * k
    item = r.choice([("red", "blue", "marbles"), ("fiction", "nonfiction", "books"), ("boys", "girls", "students")])
    return g.make(
        PSD, 1,
        f"In a collection, the ratio of {item[0]} {item[2]} to {item[1]} {item[2]} is {a} to {b}. If there are {total} {item[2]} in all, how many are {item[1]}?",
        b * k, [a * k, total - b, total // b, (a + b) * k - a * k - k],
        f"The parts total {a} + {b} = {a + b}, so each part is {total}/{a + b} = {k}. The {item[1]} {item[2]} are {b} × {k} = {b * k}.",
    )


def t_mean_missing(g):
    r = g.r
    n = r.choice([4, 5, 6])
    vals = [r.randint(60, 98) for _ in range(n - 1)]
    mean = r.randint(78, 92)
    missing = mean * n - sum(vals)
    if not 40 <= missing <= 100:
        return False
    return g.make(
        PSD, 2,
        f"A student's scores on {n - 1} tests are {', '.join(map(str, vals))}. What score does the student need on one more test for the mean of all {n} scores to be {mean}?",
        missing, [mean, missing + n, missing - n, round(sum(vals) / (n - 1)), 2 * mean - missing],
        f"The total of all {n} scores must be {mean} × {n} = {mean * n}. The first {n - 1} sum to {sum(vals)}, so the last score is {mean * n} - {sum(vals)} = {missing}.",
    )


def t_median(g):
    r = g.r
    vals = r.sample(range(3, 60), 7)
    s = sorted(vals)
    mean = round(sum(vals) / 7)
    if s[3] == mean:
        return False
    return g.make(
        PSD, 1,
        f"What is the median of the following data set? {', '.join(map(str, vals))}",
        s[3], [mean, s[2], s[4], vals[3] if vals[3] != s[3] else s[5]],
        f"Ordered, the values are {', '.join(map(str, s))}. With 7 values the median is the 4th: {s[3]}.",
    )


def t_speed(g):
    r = g.r
    mph = r.choice([30, 45, 60, 36, 54, 72])
    sec = r.choice([10, 20, 30])
    # feet per second: mph*5280/3600
    fps = Fraction(mph * 5280, 3600)
    dist = fps * sec
    if dist.denominator != 1:
        return False
    return g.make(
        PSD, 3,
        f"A car travels at a constant speed of {mph} miles per hour. How many feet does the car travel in {sec} seconds? (1 mile = 5,280 feet)",
        int(dist), [mph * sec, int(dist) * 60 if False else int(dist) // 2, int(dist) + 440, int(mph * 5280 / 60)],
        f"{mph} mph is {mph} × 5,280 / 3,600 = {f(fps)} feet per second. In {sec} seconds: {f(fps)} × {sec} = {int(dist)} feet.",
    )


def t_prob_table(g):
    r = g.r
    a, b, c, d = (r.randint(6, 40) for _ in range(4))
    total = a + b + c + d
    ans = Fraction(a, a + c)
    return g.make(
        PSD, 2,
        f"A survey asked {total} students whether they prefer morning or evening study sessions. Of the {a + c} seniors, {a} prefer morning and {c} prefer evening. Of the {b + d} juniors, {b} prefer morning and {d} prefer evening. If one senior is chosen at random, what is the probability the student prefers morning?",
        ans, [Fraction(a, total), Fraction(a, a + b), Fraction(c, a + c), Fraction(a, a + c + 1)],
        f"There are {a + c} seniors and {a} of them prefer morning, so the probability is {a}/{a + c}" + (f" = {f(ans)}." if ans.denominator != a + c else "."),
    )


def t_scatter(g):
    r = g.r
    m, b = r.choice([1.5, 2, 2.5, 3, 4]), r.choice([5, 8, 10, 12, 20])
    x = r.randint(4, 14)
    ans = m * x + b
    return g.make(
        PSD, 2,
        f"A scatterplot of the number of hours studied, x, and exam score, y, has a line of best fit with equation y = {f(m)}x + {b}. According to the line, what is the predicted score for a student who studied {x} hours?",
        ans, [m * x, ans + m, ans - b + m, m + x + b, ans + b],
        f"Substitute x = {x}: y = {f(m)}({x}) + {b} = {f(ans)}.",
    )


def t_compound(g):
    r = g.r
    p, rate, t = r.choice([500, 1000, 2000]), r.choice([5, 10]), r.randint(2, 3)
    amt = p * (1 + rate / 100) ** t
    simple = p * (1 + rate / 100 * t)
    return g.make(
        PSD, 3,
        f"An account earns {rate}% interest compounded annually. If ${p:,} is deposited and no other deposits or withdrawals are made, what is the balance after {t} years?",
        money(round(amt, 2)),
        [money(round(simple, 2)), money(round(p * (1 + rate / 100) ** (t + 1), 2)), money(round(p * (1 + rate / 100 * (t + 1)), 2)), money(p + rate * t)],
        f"Balance = {p:,}(1 + {rate / 100:g})^{t} = {money(round(amt, 2))}. Compound interest grows faster than the simple-interest total of {money(round(simple, 2))}.",
    )


def t_percent_of(g):
    r = g.r
    pct, whole = r.choice([15, 20, 35, 40, 60, 75]), r.choice([40, 60, 80, 120, 200, 240])
    part = pct * whole / 100
    if part != int(part):
        return False
    return g.make(
        PSD, 1,
        f"{int(part)} is what percent of {whole}?",
        f"{pct}%", [f"{100 - pct}%", f"{pct + 10}%", f"{round(whole / part * 100) if whole/part*100 != pct else pct + 5}%", f"{max(pct - 10, 5)}%"],
        f"Percent = {int(part)}/{whole} × 100 = {pct}%.",
    )


# --------------------------------------------------- Geometry & Trigonometry

TRIPLES = [(3, 4, 5), (5, 12, 13), (8, 15, 17), (7, 24, 25), (20, 21, 29), (9, 40, 41)]


def t_pyth(g):
    r = g.r
    a, b, c = r.choice(TRIPLES)
    k = r.choice([1, 2, 3])
    a, b, c = a * k, b * k, c * k
    return g.make(
        GEO, 1,
        f"A right triangle has legs of length {a} and {b}. What is the length of its hypotenuse?",
        c, [a + b, c + 1, c - 1, round(math.sqrt(a * b))],
        f"By the Pythagorean theorem, c² = {a}² + {b}² = {a * a + b * b}, so c = {c}.",
    )


def t_circle_area(g):
    r = g.r
    rad = r.randint(2, 12)
    circ = 2 * rad
    return g.make(
        GEO, 2,
        f"A circle has a circumference of {circ}π. What is the area of the circle?",
        f"{rad * rad}π", [f"{circ * circ}π", f"{circ}π", f"{2 * rad * rad}π", f"{rad}π"],
        f"Circumference = 2πr = {circ}π, so r = {rad}. Area = πr² = {rad * rad}π.",
    )


def t_circle_eq(g):
    r = g.r
    h, k, rad = r.randint(-6, 6), r.randint(-6, 6), r.randint(2, 9)
    if h == 0 or k == 0:
        return False
    eq = f"(x {'-' if h >= 0 else '+'} {abs(h)})² + (y {'-' if k >= 0 else '+'} {abs(k)})² = {rad * rad}"
    return g.make(
        GEO, 2,
        f"The equation of a circle in the xy-plane is {eq}. What is the radius of the circle?",
        rad, [rad * rad, rad * 2, abs(h) + abs(k), rad + 1],
        f"In (x - h)² + (y - k)² = r², the right side is r². Here r² = {rad * rad}, so r = {rad}.",
    )


def t_trig(g):
    r = g.r
    a, b, c = r.choice(TRIPLES[:5])
    k = r.choice([1, 2])
    a, b, c = a * k, b * k, c * k
    which = r.choice(["sin", "cos", "tan"])
    num, den = {"sin": (a, c), "cos": (b, c), "tan": (a, b)}[which]
    ans = Fraction(num, den)
    wrongs = [Fraction(b, c) if which != "cos" else Fraction(a, c), Fraction(c, num), Fraction(b, a) if which == "tan" else Fraction(a, b), Fraction(den, num)]
    return g.make(
        GEO, 2,
        f"In right triangle ABC, the right angle is at B, AB = {b}, BC = {a}, and AC = {c}. What is the value of {which} A?" if which != "tan" else
        f"In right triangle ABC, the right angle is at B, AB = {b}, BC = {a}, and AC = {c}. What is the value of tan A?",
        ans, wrongs,
        f"Angle A is opposite side BC ({a}) and adjacent to side AB ({b}); the hypotenuse is {c}. {which} A = {'opposite/hypotenuse' if which == 'sin' else 'adjacent/hypotenuse' if which == 'cos' else 'opposite/adjacent'} = {num}/{den}" + (f" = {f(ans)}." if ans.denominator != den else "."),
    )


def t_volume(g):
    r = g.r
    rad, h = r.randint(2, 8), r.randint(3, 12)
    return g.make(
        GEO, 2,
        f"A right circular cylinder has a radius of {rad} centimeters and a height of {h} centimeters. What is its volume, in cubic centimeters?",
        f"{rad * rad * h}π", [f"{2 * rad * h}π", f"{rad * h * h}π", f"{rad * rad * h // 3 if (rad*rad*h)%3==0 else rad*rad*h + 1}π", f"{rad * rad * h * 2}π"],
        f"Volume = πr²h = π({rad})²({h}) = {rad * rad * h}π.",
    )


def t_similar(g):
    r = g.r
    a, k = r.randint(3, 9), r.choice([2, 3, 4])
    b = a + r.randint(2, 6)
    return g.make(
        GEO, 2,
        f"Triangle DEF is similar to triangle ABC, with D corresponding to A and E corresponding to B. AB = {a}, BC = {b}, and DE = {a * k}. What is the length of EF?",
        b * k, [b + k, b * k + a, a * k + b, b * k - 1],
        f"The scale factor is DE/AB = {a * k}/{a} = {k}. So EF = {k} × BC = {k} × {b} = {b * k}.",
    )


def t_isosceles(g):
    r = g.r
    apex = r.choice([20, 30, 40, 50, 80, 100, 120])
    base = (180 - apex) // 2
    return g.make(
        GEO, 1,
        f"In an isosceles triangle, the angle between the two congruent sides measures {apex}°. What is the measure, in degrees, of one of the other two angles?",
        base, [180 - apex, apex, base + 10, (180 - apex)],
        f"The angles sum to 180°, so the two equal base angles total {180 - apex}°, and each measures {base}°.",
    )


def t_arc(g):
    r = g.r
    rad, ang = r.choice([6, 9, 12, 18]), r.choice([40, 60, 90, 120, 150])
    arc = Fraction(ang, 360) * 2 * rad
    return g.make(
        GEO, 3,
        f"A circle has a radius of {rad} and a central angle measuring {ang}°. What is the length of the arc intercepted by this angle?",
        f"{f(arc)}π", [f"{f(Fraction(ang,360)*rad*rad)}π", f"{f(arc * 2)}π", f"{f(arc / 2)}π", f"{rad * 2}π"],
        f"Arc length = ({ang}/360)(2π · {rad}) = {f(arc)}π.",
    )


def t_radians(g):
    r = g.r
    num, den = r.choice([(5, 6), (2, 3), (3, 4), (1, 3), (5, 4), (3, 2), (7, 6)])
    deg = Fraction(180 * num, den)
    if deg.denominator != 1:
        return False
    return g.make(
        GEO, 2,
        f"An angle measures {num if num != 1 else ''}π/{den} radians. What is the measure of the angle in degrees?",
        int(deg), [int(deg) + 30, int(deg) - 30, int(Fraction(360 * num, den)), int(Fraction(90 * num, den))],
        f"Multiply by 180/π: ({num}π/{den})(180/π) = {int(deg)}°.",
    )


def t_midpoint(g):
    r = g.r
    x1, y1, x2, y2 = r.randint(-8, 4), r.randint(-8, 4), r.randint(5, 12), r.randint(5, 12)
    if (x1 + x2) % 2 or (y1 + y2) % 2:
        return False
    mx, my = (x1 + x2) // 2, (y1 + y2) // 2
    return g.make(
        GEO, 1,
        f"Segment AB has endpoints A({x1}, {y1}) and B({x2}, {y2}). What is the midpoint of AB?",
        f"({mx}, {my})", [f"({x2 - x1}, {y2 - y1})", f"({my}, {mx})", f"({mx + 1}, {my})", f"({mx}, {my - 1})"],
        f"The midpoint averages the coordinates: (({x1} + {x2})/2, ({y1} + {y2})/2) = ({mx}, {my}).",
    )


def t_distance(g):
    r = g.r
    a, b, c = r.choice(TRIPLES[:4])
    x1, y1 = r.randint(-5, 5), r.randint(-5, 5)
    sx, sy = r.choice([1, -1]), r.choice([1, -1])
    x2, y2 = x1 + sx * a, y1 + sy * b
    return g.make(
        GEO, 2,
        f"What is the distance between the points ({x1}, {y1}) and ({x2}, {y2}) in the xy-plane?",
        c, [a + b, c * c, abs(a - b), c + 1],
        f"The horizontal change is {a} and the vertical change is {b}, so the distance is √({a}² + {b}²) = √{a * a + b * b} = {c}.",
    )


PLAN = [
    (t_linear_eq, 5), (t_system, 5), (t_slope, 4), (t_yint, 4), (t_cost, 5),
    (t_ineq, 4), (t_infinite, 4), (t_function_eval, 4), (t_interp, 2),
    (t_quad_roots, 4), (t_positive_root, 4), (t_vertex, 4), (t_exp_growth, 4),
    (t_expand, 4), (t_composition, 4), (t_exponents, 4), (t_one_solution, 4),
    (t_rational, 4),
    (t_percent_change, 4), (t_ratio, 4), (t_mean_missing, 4), (t_median, 3),
    (t_speed, 4), (t_prob_table, 4), (t_scatter, 4), (t_compound, 3), (t_percent_of, 4),
    (t_pyth, 4), (t_circle_area, 4), (t_circle_eq, 4), (t_trig, 6), (t_volume, 4),
    (t_similar, 4), (t_isosceles, 4), (t_arc, 4), (t_radians, 4), (t_midpoint, 4),
    (t_distance, 4),
]


def verify(item):
    ch = item["choices"]
    assert len(ch) == 4 and len(set(ch)) == 4, item
    assert 0 <= item["correctIndex"] < 4, item


PLAN = [(f, n * 2) for f, n in PLAN]


def main():
    g = Gen()
    for fn, n in PLAN:
        before = len(g.items)
        g.run(fn, n)
        if len(g.items) - before < n:
            print(f"warning: {fn.__name__} produced {len(g.items) - before}/{n}")
    # Interleave topics so slices of the bank stay balanced.
    g.r.shuffle(g.items)
    for i, item in enumerate(g.items, 1):
        item["id"] = f"sm-{i:03d}"
        verify(item)
    ordered = [
        {k: item[k] for k in ("id", "subject", "topic", "difficulty", "prompt", "choices", "correctIndex", "explanation")}
        for item in g.items
    ]
    with open(OUT, "w") as fh:
        json.dump(ordered, fh, indent=1, ensure_ascii=False)
    print(len(ordered), "math questions")


if __name__ == "__main__":
    main()

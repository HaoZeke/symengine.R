context("Conversion between R expression and Basic")

test_that("S(SYMSXP) works", {
    s <- quote(x)
    expect_true(S(s) == S("x"))
    
    s <- quote(e)
    expect_true(S(s) != S("e"))
})

test_that("S(LANGSXP) works", {
    s <- quote(x^b + 3)
    expect_true(is(S(s), "Basic"))
})

test_that("S(EXPRSXP) works", {
    s <- expression(x^b + 3)
    ## TODO
})

test_that("S(formula) works", {
    s <- local({
        ~ x^b + 3
    })
    expect_true(is(S(s), "Basic"))
})

test_that("S(LANGSXP) does not check whole number", {
    s <- quote(x^b + 3)
    num <- get_args(S(s))[[1L]]
    expect_true(get_type(num) == "RealDouble")
})

test_that("S(formula) will convert whole number to Integer", {
    s <- ~ x^b + 3
    num <- get_args(S(s))[[1L]]
    expect_true(get_type(num) == "Integer")
})

test_that("backquote works in formula", {
    s <- local({
        m <- 42L
        ~ x^.(m)
    })
    expect_true(S(s) == S("x^42"))
    
    s <- quote(x^.(m))
    expect_error(S(s))
})

test_that("Nested formula works", {
    s1 <- local({
        aa <- S("a")
        ~ x^.(aa)
    })
    s2 <- local({
        bb <- S("b")
        ~ .(s1) + y^.(bb)
    })
    expect_true(S(s2) == S("x^a + y^b"))
})

test_that("as.language(Basic) works", {
    s <- S("x ^ a")
    expect_true(identical(as.language(s), quote(x^a)))
})

test_that("as.expression(Basic) works", {
    s <- S("x ^ a")
    expect_true(identical(as.expression(s), expression(x^a)))
})

expect_twoway_equivalent <- function(r, b) {
    r_tob <- as(r, "Basic")
    expect_true(r_tob == b)
    r_back <- as.language(r_tob)
    expect_identical(r, r_back)
    
    b_tor <- as.language(b)
    expect_identical(b_tor, r)
    b_back <- as(b_tor, "Basic")
    expect_true(b_back == b)
}

expect_lang2basic <- function(r, b) {
    r_tob <- as(r, "Basic")
    expect_true(r_tob == b)
}
expect_basic2lang <- function(r, b) {
    b_tor <- as.language(b)
    expect_identical(b_tor, r)
}

test_that("+ - * / ^", {
    expect_lang2basic(quote(a + b), S("a + b"))
    expect_basic2lang(quote(b + a), S("a + b"))
    
    expect_lang2basic(quote(a - b),            S("a - b"))
    expect_basic2lang(bquote(.(-1L) * b + a),  S("a - b"))
    
    expect_twoway_equivalent(bquote(.(-1L) * x), S("-x"))
    expect_twoway_equivalent(quote(a * b), S("a * b"))
    
    expect_lang2basic(quote(a/b),             S("a/b"))
    expect_basic2lang(bquote(a * b ^ .(-1L)), S("a/b"))
    
    expect_twoway_equivalent(quote(a^b), S("a^b"))
})

test_that("Supported Math@groupMembers", {
    expect_twoway_equivalent(quote(abs(x)), S("abs(x)"))
    
    expect_lang2basic(quote(sqrt(x)), S("sqrt(x)"))
    expect_basic2lang(bquote(x^.(0.5)), S("sqrt(x)"))
    
    expect_lang2basic(quote(exp(x)), S("exp(x)"))
    expect_basic2lang(bquote(.(exp(1))^x), S("exp(x)"))
    
    expect_lang2basic(quote(expm1(x)), S("exp(x) - 1"))
    
    expect_twoway_equivalent(quote(log(x)), S("log(x)"))
    
    expect_lang2basic(quote(log10(x)), S("log(x)/log(10)"))
    expect_lang2basic(quote(log2(x)) , S("log(x)/log(2)"))
    expect_lang2basic(quote(log1p(x)), S("log(1+x)"))
    
    expect_twoway_equivalent(quote(cos(x)),   S("cos(x)"))
    expect_twoway_equivalent(quote(cosh(x)),  S("cosh(x)"))
    expect_twoway_equivalent(quote(sin(x)),   S("sin(x)"))
    expect_twoway_equivalent(quote(sinh(x)),  S("sinh(x)"))
    expect_twoway_equivalent(quote(tan(x)),   S("tan(x)"))
    expect_twoway_equivalent(quote(tanh(x)),  S("tanh(x)"))
    expect_twoway_equivalent(quote(acos(x)),  S("acos(x)"))
    expect_twoway_equivalent(quote(acosh(x)), S("acosh(x)"))
    expect_twoway_equivalent(quote(asin(x)),  S("asin(x)"))
    expect_twoway_equivalent(quote(asinh(x)), S("asinh(x)"))
    expect_twoway_equivalent(quote(atan(x)),  S("atan(x)"))
    expect_twoway_equivalent(quote(atanh(x)), S("atanh(x)"))
    
    expect_lang2basic(quote(cospi(x)), S("cos(pi*x)"))
    expect_lang2basic(quote(sinpi(x)), S("sin(pi*x)"))
    expect_lang2basic(quote(tanpi(x)), S("tan(pi*x)"))
    
    expect_twoway_equivalent(quote(gamma(x)),  S("gamma(x)"))
    expect_twoway_equivalent(quote(lgamma(x)), S("loggamma(x)"))

    expect_lang2basic(quote(digamma(x)), S("polygamma(0,x)"))
    expect_basic2lang(quote(psigamma(x, 0L)), S("polygamma(0,x)"))

    expect_lang2basic(quote(trigamma(x)), S("polygamma(1,x)"))
    expect_basic2lang(quote(psigamma(x, 1L)), S("polygamma(1,x)"))
    
    ## Currently unsupported Math@groupMembers
    #"sign", "ceiling", "floor", "trunc", "cummax", "cummin", "cumprod", "cumsum",
})

test_that("Misc functions", {
    expect_twoway_equivalent(quote(lambertw      (x)) , S("lambertw(x)"))
    expect_twoway_equivalent(quote(zeta          (x)) , S("zeta(x)"))
    expect_twoway_equivalent(quote(dirichlet_eta (x)) , S("dirichlet_eta(x)"))
    expect_twoway_equivalent(quote(erf           (x)) , S("erf(x)"))
    expect_twoway_equivalent(quote(erfc          (x)) , S("erfc(x)"))
})

test_that("asLanguageTable", {
    expect_twoway_equivalent(quote(x)   , Symbol("x")) # Symbol
    expect_twoway_equivalent(quote(3L)  , S(3L))       # Integer
    expect_twoway_equivalent(quote(3)   , S("3.0"))    # RealDouble
    expect_basic2lang(bquote(.(pi))     , S("pi"))     # Constant
    expect_basic2lang(bquote(.(1L/42L)) , S("1/42"))   # Rational
    expect_basic2lang(quote(NaN)        , S("nan"))    # NaN
    expect_basic2lang(quote(Inf)        , S("inf"))    # Infty
    expect_basic2lang(bquote(.(-Inf))   , S("-inf"))   # Infty
    expect_twoway_equivalent(quote(atan2(y, x))      , atan2(S("y"), S("x"))) # ATan2
    expect_twoway_equivalent(quote(beta(b, a))       , S("beta(b, a)"))       # Beta
    expect_twoway_equivalent(quote(psigamma(x, d))   , S("polygamma(d, x)"))  # PolyGamma
    expect_twoway_equivalent(quote(uppergamma(x, a)) , S("uppergamma(a, x)")) # UpperGamma
    expect_twoway_equivalent(quote(lowergamma(x, a)) , S("lowergamma(a, x)")) # LowerGamma
    expect_twoway_equivalent(quote(kronecker_delta(x, y)), S("kronecker_delta(x, y)")) # KroneckerDelta
    # TODO:
    #   LeviCivita
    #   Sign, Floor, Ceiling,
})


## Old tests from test-lambdify.R
test_that("basic to expr conversion", {
    # Symbol
    expect_identical(as.language(Symbol(" w w")), quote(` w w`))
    # Add
    expect_setequal(
        all.vars(as.language(S("a + b + c"))),
        c("a", "b", "c")
    )
    expect_identical(as.language(S("1 + a")), quote(1L + a))
    # Mul
    expect_setequal(
        all.vars(as.language(S("a * b * c"))),
        c("a", "b", "c")
    )
    # Pow
    expect_identical(as.language(S("x ^ y")), quote(x ^ y))
    # Rational
    expect_identical(as.language(S("3/4")), 3/4)
    expect_identical(as.language(S("1/3")), 1/3)
    expect_identical(eval(as.language(S("1/pi"))), 1/pi)
    expect_identical(eval(as.language(S("1.5/pi"))), 1.5/pi)
    # Integer
    expect_identical(as.language(S("42")), 42L)
    # RealDouble
    expect_identical(as.language(S("4.2")), 4.2)
    # Infty
    expect_identical(as.language(S("inf")), Inf)
    expect_identical(eval(as.language(S("-inf"))), -Inf)
    # Constant
    expect_identical(as.language(S("pi")), pi)
})

test_that("as.expression", {
    x <- S("42")
    expect_true(is.expression(as.expression(x)))
})

test_that("as.symbol", {
    x <- S("42")
    expect_error(as.symbol(x))
    
    x <- S("x")
    expect_true(is.symbol(as.symbol(x)))
    expect_identical(as.symbol(x), quote(x))
})

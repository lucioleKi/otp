%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2026. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%
-module(bitops_SUITE).
-export([suite/0, all/0, id/1, init_per_suite/1, end_per_suite/1,
         test_ctz_smalls/1, test_ctz_bignums/1,
         test_invalid_types/1, test_ctz_in_guard/1, test_ctz_repeated_calls/1,
         test_popcount_smalls/1, test_popcount_bignums/1,
         test_popcount_in_guard/1,
         test_popcount_repeated_calls/1, test_mixed_bitops/1,
         test_ctz_popcount_conditional_logic/1,
         test_unsigned_width_smalls/1, test_unsigned_width_bignums/1,
         test_unsigned_width_in_guard/1, test_unsigned_width_repeated_calls/1,
         test_signed_width_smalls/1, test_signed_width_bignums/1,
         test_signed_width_in_guard/1, test_signed_width_repeated_calls/1,
         test_width_relationships/1, test_width_conditional_logic/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").

suite() -> [{timetrap, {seconds, 30}}].

all() -> [
    test_ctz_smalls,
    test_ctz_bignums,
    test_invalid_types,
    test_ctz_in_guard,
    test_ctz_repeated_calls,

    test_popcount_smalls,
    test_popcount_bignums,
    test_popcount_in_guard,
    test_popcount_repeated_calls,

    test_unsigned_width_smalls,
    test_unsigned_width_bignums,
    test_unsigned_width_in_guard,
    test_unsigned_width_repeated_calls,

    test_signed_width_smalls,
    test_signed_width_bignums,
    test_signed_width_in_guard,
    test_signed_width_repeated_calls,

    test_mixed_bitops,
    test_ctz_popcount_conditional_logic,
    test_width_relationships,
    test_width_conditional_logic
].

init_per_suite(Config) -> Config.
end_per_suite(_Config) -> ok.

%% ===== integer_trailing_zeroes/1 Tests =====

test_ctz_smalls(_Config) ->
    0 = integer_trailing_zeroes(id(1)),
    1 = integer_trailing_zeroes(id(2)),
    0 = integer_trailing_zeroes(id(3)),
    2 = integer_trailing_zeroes(id(4)),
    3 = integer_trailing_zeroes(id(8)),
    4 = integer_trailing_zeroes(id(16)),

    ?assertError(badarg, integer_trailing_zeroes(id(0))),

    % Trailing zero count is invariant under negation, so negatives give the
    % same answer as their magnitude
    0 = integer_trailing_zeroes(id(-1)),
    3 = integer_trailing_zeroes(id(-8)),
    2 = integer_trailing_zeroes(id(-100)),

    32 = integer_trailing_zeroes(id(1 bsl 32)),
    48 = integer_trailing_zeroes(id(1 bsl 48)),
    62 = integer_trailing_zeroes(id(1 bsl 62)),
    63 = integer_trailing_zeroes(id(1 bsl 63)),

    % Test around SMALL_INT_MAX transition (56 bits on 64-bit systems)
    SmallMax = (1 bsl 56) - 1,
    0 = integer_trailing_zeroes(id(SmallMax)),
    BeyondMax = SmallMax + 1,
    56 = integer_trailing_zeroes(id(BeyondMax)),

    ok.

test_ctz_bignums(_Config) ->
    BigNum64 = 1 bsl 64,
    64 = integer_trailing_zeroes(id(BigNum64)),
    BigNum100 = 1 bsl 100,
    100 = integer_trailing_zeroes(id(BigNum100)),
    BigNum128 = 1 bsl 128,
    128 = integer_trailing_zeroes(id(BigNum128)),
    % multi-limb bignum with low set bit in a lower limb
    BigMixed = (1 bsl 70) + (1 bsl 5),
    5 = integer_trailing_zeroes(id(BigMixed)),
    % bignum with trailing zeros spanning multiple limbs
    BigSpan = (1 bsl 192) + (1 bsl 130) + (1 bsl 5),
    5 = integer_trailing_zeroes(id(BigSpan)),

    % All-ones bignums: bit 0 is always set, so integer_trailing_zeroes = 0
    AllOnes64 = (1 bsl 64) - 1,
    0 = integer_trailing_zeroes(id(AllOnes64)),
    AllOnes100 = (1 bsl 100) - 1,
    0 = integer_trailing_zeroes(id(AllOnes100)),
    AllOnes200 = (1 bsl 200) - 1,
    0 = integer_trailing_zeroes(id(AllOnes200)),
    ok.

%% ===== integer_set_bits/1 Tests =====

test_popcount_smalls(_Config) ->
    0 = integer_set_bits(id(0)),
    1 = integer_set_bits(id(1)),
    1 = integer_set_bits(id(2)),
    2 = integer_set_bits(id(3)),
    1 = integer_set_bits(id(4)),
    4 = integer_set_bits(id(15)),
    1 = integer_set_bits(id(8)),

    % Negative numbers should raise badarg in Erlang
    ?assertError(badarg, integer_set_bits(id(-1))),
    ?assertError(badarg, integer_set_bits(id(-7))),
    ?assertError(badarg, integer_set_bits(id(-128))),

    32 = integer_set_bits(id((1 bsl 32) - 1)),
    48 = integer_set_bits(id((1 bsl 48) - 1)),

    % Test around SMALL_INT_MAX transition
    SmallMax = (1 bsl 56) - 1,
    56 = integer_set_bits(id(SmallMax)),
    BeyondMax = SmallMax + 1,
    1 = integer_set_bits(id(BeyondMax)),
    % Test large all-ones
    AllOnes63 = (1 bsl 63) - 1,
    63 = integer_set_bits(id(AllOnes63)),
    ok.

test_popcount_bignums(_Config) ->
    BigNum128AllBits = (1 bsl 128) - 1,
    128 = integer_set_bits(id(BigNum128AllBits)),
    BigNum128SingleBit = 1 bsl 128,
    1 = integer_set_bits(id(BigNum128SingleBit)),
    BigNum = (1 bsl 96) + (1 bsl 65) + (1 bsl 32) + 1,
    4 = integer_set_bits(id(BigNum)),
    % larger multi-limb all-ones
    BigAll192 = (1 bsl 192) - 1,
    192 = integer_set_bits(id(BigAll192)),
    % scattered bits across many limbs
    BigScattered = (1 bsl 200) + (1 bsl 150) + (1 bsl 70) + (1 bsl 1),
    4 = integer_set_bits(id(BigScattered)),

    % All-ones bignums: all bits up to N are set, so integer_set_bits = N
    AllOnes64 = (1 bsl 64) - 1,
    64 = integer_set_bits(id(AllOnes64)),
    AllOnes100 = (1 bsl 100) - 1,
    100 = integer_set_bits(id(AllOnes100)),
    AllOnes200 = (1 bsl 200) - 1,
    200 = integer_set_bits(id(AllOnes200)),
    ok.

%% ===== integer_unsigned_width/1 Tests =====

test_unsigned_width_smalls(_Config) ->
    0 = integer_unsigned_width(id(0)),
    1 = integer_unsigned_width(id(1)),
    2 = integer_unsigned_width(id(2)),
    2 = integer_unsigned_width(id(3)),
    3 = integer_unsigned_width(id(4)),
    3 = integer_unsigned_width(id(7)),
    4 = integer_unsigned_width(id(8)),
    4 = integer_unsigned_width(id(15)),
    5 = integer_unsigned_width(id(16)),
    8 = integer_unsigned_width(id(255)),
    9 = integer_unsigned_width(id(256)),

    % Negative numbers have no unsigned representation
    ?assertError(badarg, integer_unsigned_width(id(-1))),
    ?assertError(badarg, integer_unsigned_width(id(-8))),
    ?assertError(badarg, integer_unsigned_width(id(-100))),

    % A single set bit at position N needs N+1 bits
    33 = integer_unsigned_width(id(1 bsl 32)),
    49 = integer_unsigned_width(id(1 bsl 48)),
    63 = integer_unsigned_width(id(1 bsl 62)),
    64 = integer_unsigned_width(id(1 bsl 63)),

    % All-ones values of N bits need exactly N bits
    32 = integer_unsigned_width(id((1 bsl 32) - 1)),
    48 = integer_unsigned_width(id((1 bsl 48) - 1)),
    63 = integer_unsigned_width(id((1 bsl 63) - 1)),

    % Test around SMALL_INT_MAX transition (56 bits on 64-bit systems)
    SmallMax = (1 bsl 56) - 1,
    56 = integer_unsigned_width(id(SmallMax)),
    BeyondMax = SmallMax + 1,
    57 = integer_unsigned_width(id(BeyondMax)),

    ok.

test_unsigned_width_bignums(_Config) ->
    BigNum64 = 1 bsl 64,
    65 = integer_unsigned_width(id(BigNum64)),
    BigNum100 = 1 bsl 100,
    101 = integer_unsigned_width(id(BigNum100)),
    BigNum128 = 1 bsl 128,
    129 = integer_unsigned_width(id(BigNum128)),

    % Only the most significant bit decides the width; lower limbs are
    % irrelevant
    BigMixed = (1 bsl 70) + (1 bsl 5),
    71 = integer_unsigned_width(id(BigMixed)),
    BigSpan = (1 bsl 192) + (1 bsl 130) + (1 bsl 5),
    193 = integer_unsigned_width(id(BigSpan)),

    % All-ones bignums: N bits set means a width of N
    AllOnes64 = (1 bsl 64) - 1,
    64 = integer_unsigned_width(id(AllOnes64)),
    AllOnes100 = (1 bsl 100) - 1,
    100 = integer_unsigned_width(id(AllOnes100)),
    AllOnes200 = (1 bsl 200) - 1,
    200 = integer_unsigned_width(id(AllOnes200)),

    % Negative bignums are rejected just like negative smalls
    ?assertError(badarg, integer_unsigned_width(id(-BigNum100))),
    ?assertError(badarg, integer_unsigned_width(id(-AllOnes200))),
    ok.

%% ===== integer_signed_width/1 Tests =====

test_signed_width_smalls(_Config) ->
    1 = integer_signed_width(id(0)),

    % Positive values need one extra bit for the sign
    2 = integer_signed_width(id(1)),
    3 = integer_signed_width(id(2)),
    3 = integer_signed_width(id(3)),
    4 = integer_signed_width(id(4)),
    4 = integer_signed_width(id(7)),
    5 = integer_signed_width(id(8)),
    5 = integer_signed_width(id(15)),
    8 = integer_signed_width(id(127)),
    9 = integer_signed_width(id(128)),
    9 = integer_signed_width(id(255)),

    % The 2's complement range is asymmetric: -(1 bsl (W-1)) still fits in W
    % bits, while one less than that needs an extra bit
    1 = integer_signed_width(id(-1)),
    2 = integer_signed_width(id(-2)),
    3 = integer_signed_width(id(-3)),
    3 = integer_signed_width(id(-4)),
    4 = integer_signed_width(id(-5)),
    4 = integer_signed_width(id(-7)),
    4 = integer_signed_width(id(-8)),
    5 = integer_signed_width(id(-9)),
    8 = integer_signed_width(id(-127)),
    8 = integer_signed_width(id(-128)),
    9 = integer_signed_width(id(-129)),
    9 = integer_signed_width(id(-256)),
    10 = integer_signed_width(id(-257)),

    33 = integer_signed_width(id((1 bsl 32) - 1)),
    32 = integer_signed_width(id(-(1 bsl 31))),
    64 = integer_signed_width(id(1 bsl 62)),
    63 = integer_signed_width(id(-(1 bsl 62))),

    % Test around SMALL_INT_MAX transition (56 bits on 64-bit systems)
    SmallMax = (1 bsl 56) - 1,
    57 = integer_signed_width(id(SmallMax)),
    BeyondMax = SmallMax + 1,
    58 = integer_signed_width(id(BeyondMax)),

    ok.

test_signed_width_bignums(_Config) ->
    BigNum64 = 1 bsl 64,
    66 = integer_signed_width(id(BigNum64)),
    BigNum100 = 1 bsl 100,
    102 = integer_signed_width(id(BigNum100)),
    BigNum128 = 1 bsl 128,
    130 = integer_signed_width(id(BigNum128)),

    % Negated powers of two are the extreme value of their width, so they do
    % not need an extra bit
    65 = integer_signed_width(id(-BigNum64)),
    101 = integer_signed_width(id(-BigNum100)),
    129 = integer_signed_width(id(-BigNum128)),

    % One step beyond the extreme value does need an extra bit
    66 = integer_signed_width(id(-BigNum64 - 1)),
    102 = integer_signed_width(id(-BigNum100 - 1)),

    % Multi-limb values with more than one set bit
    BigMixed = (1 bsl 70) + (1 bsl 5),
    72 = integer_signed_width(id(BigMixed)),
    72 = integer_signed_width(id(-BigMixed)),
    BigSpan = (1 bsl 192) + (1 bsl 130) + (1 bsl 5),
    194 = integer_signed_width(id(BigSpan)),
    194 = integer_signed_width(id(-BigSpan)),

    % All-ones bignums are never powers of two, so both signs need N+1 bits
    AllOnes64 = (1 bsl 64) - 1,
    65 = integer_signed_width(id(AllOnes64)),
    65 = integer_signed_width(id(-AllOnes64)),
    AllOnes100 = (1 bsl 100) - 1,
    101 = integer_signed_width(id(AllOnes100)),
    101 = integer_signed_width(id(-AllOnes100)),
    AllOnes200 = (1 bsl 200) - 1,
    201 = integer_signed_width(id(AllOnes200)),
    201 = integer_signed_width(id(-AllOnes200)),
    ok.

test_invalid_types(_Config) ->
    % Type errors should raise badarg
    ?assertError(badarg, integer_trailing_zeroes(id(3.14))),
    ?assertError(badarg, integer_trailing_zeroes(id(atom))),
    ?assertError(badarg, integer_trailing_zeroes(id([1,2,3]))),
    ?assertError(badarg, integer_trailing_zeroes(id({}))),

    ?assertError(badarg, integer_set_bits(id(3.14))),
    ?assertError(badarg, integer_set_bits(id(foo))),
    ?assertError(badarg, integer_set_bits(id(ok))),
    ?assertError(badarg, integer_set_bits(id([1,2,3]))),

    ?assertError(badarg, integer_unsigned_width(id(3.14))),
    ?assertError(badarg, integer_unsigned_width(id(atom))),
    ?assertError(badarg, integer_unsigned_width(id([1,2,3]))),
    ?assertError(badarg, integer_unsigned_width(id({}))),

    ?assertError(badarg, integer_signed_width(id(3.14))),
    ?assertError(badarg, integer_signed_width(id(-3.14))),
    ?assertError(badarg, integer_signed_width(id(foo))),
    ?assertError(badarg, integer_signed_width(id([1,2,3]))),
    ?assertError(badarg, integer_signed_width(id({}))),
    ok.

test_ctz_in_guard(_Config) ->
    % Test integer_trailing_zeroes/1 in guard context (different JIT code
    % path). id/1 cannot be called from a guard, so the input is made opaque
    % before the guard test.
    Eight = id(8),
    One = id(1),
    Sixteen = id(16),
    ok = if integer_trailing_zeroes(Eight) =:= 3 -> ok; true -> fail end,
    ok = if integer_trailing_zeroes(One) =:= 0 -> ok; true -> fail end,
    ok = if integer_trailing_zeroes(Sixteen) > 3 -> ok; true -> fail end,
    ok.

test_popcount_in_guard(_Config) ->
    % Test integer_set_bits in guard context (different JIT code path)
    Fifteen = id(15),
    One = id(1),
    TwoFiftyFive = id(255),
    ok = if integer_set_bits(Fifteen) =:= 4 -> ok; true -> fail end,
    ok = if integer_set_bits(One) > 0 -> ok; true -> fail end,
    ok = if integer_set_bits(TwoFiftyFive) =:= 8 -> ok; true -> fail end,
    ok.

test_ctz_repeated_calls(_Config) ->
    [N = integer_trailing_zeroes(id(1 bsl N)) || N <- lists:seq(0, 63)],
    ok.

test_popcount_repeated_calls(_Config) ->
    [1 = integer_set_bits(id(1 bsl N)) || N <- lists:seq(0, 127)],
    ok.

test_unsigned_width_in_guard(_Config) ->
    % Test integer_unsigned_width/1 in guard context (different JIT code path)
    Zero = id(0),
    Fifteen = id(15),
    Sixteen = id(16),
    Big = id(1 bsl 100),
    ok = if integer_unsigned_width(Zero) =:= 0 -> ok; true -> fail end,
    ok = if integer_unsigned_width(Fifteen) =:= 4 -> ok; true -> fail end,
    ok = if integer_unsigned_width(Sixteen) > 4 -> ok; true -> fail end,
    ok = if integer_unsigned_width(Big) =:= 101 -> ok;
            true -> fail
         end,

    Neg = id(-1),
    ok = if integer_unsigned_width(Neg) =:= 1 -> fail; true -> ok end,
    ok.

test_signed_width_in_guard(_Config) ->
    % Test integer_signed_width/1 in guard context (different JIT code path)
    Zero = id(0),
    Pos127 = id(127),
    Neg128 = id(-128),
    Neg129 = id(-129),
    NegBig = id(-(1 bsl 100)),
    ok = if integer_signed_width(Zero) =:= 1 -> ok; true -> fail end,
    ok = if integer_signed_width(Pos127) =:= 8 -> ok; true -> fail end,
    ok = if integer_signed_width(Neg128) =:= 8 -> ok; true -> fail end,
    ok = if integer_signed_width(Neg129) > 8 -> ok; true -> fail end,
    ok = if integer_signed_width(NegBig) =:= 101 -> ok;
            true -> fail
         end,

    NotAnInt = id(foo),
    ok = if integer_signed_width(NotAnInt) =:= 1 -> fail;
            true -> ok
         end,
    ok.

test_unsigned_width_repeated_calls(_Config) ->
    [begin
         W = integer_unsigned_width(id(1 bsl N)),
         W = N + 1
     end || N <- lists:seq(0, 127)],
    [N = integer_unsigned_width(id((1 bsl N) - 1)) || N <- lists:seq(1, 127)],
    ok.

test_signed_width_repeated_calls(_Config) ->
    [begin
         W = integer_signed_width(id(1 bsl N)),
         W = N + 2
     end || N <- lists:seq(0, 127)],
    [begin
         W = integer_signed_width(id(-(1 bsl N))),
         W = N + 1
     end || N <- lists:seq(0, 127)],
    ok.

test_mixed_bitops(_Config) ->
    % Test that ctz/popcount work correctly mixed with other operations
    X = 16,
    4 = integer_trailing_zeroes(id(X)),
    Y = X * 2,
    5 = integer_trailing_zeroes(id(Y)),
    Z = integer_set_bits(id(Y)),
    1 = Z,
    % More complex expression
    A = 7,
    B = integer_set_bits(id(A)),
    3 = B,
    C = integer_trailing_zeroes(id(A)),
    0 = C,
    ok.

test_ctz_popcount_conditional_logic(_Config) ->
    % Test with conditional logic and pattern matching
    TestCtz = fun(N) ->
        case integer_trailing_zeroes(N) of
            0 -> odd;
            _ -> even
        end
    end,
    odd = TestCtz(1),
    even = TestCtz(2),
    even = TestCtz(4),
    TestPopcount = fun(N) ->
        PC = integer_set_bits(N),
        if PC =:= 1 -> single_bit;
           PC < 4 -> few_bits;
           true -> many_bits
        end
    end,
    single_bit = TestPopcount(1 bsl 50),
    few_bits = TestPopcount(7),
    many_bits = TestPopcount((1 bsl 64) - 1),
    ok.

test_width_relationships(_Config) ->
    % For non-negative integers the signed width is always one bit wider than
    % the unsigned width, to make room for the sign bit
    [begin
         UW = integer_unsigned_width(N),
         SW = integer_signed_width(N),
         SW = UW + 1
     end || N <- [0, 1, 2, 3, 7, 8, 255, 1 bsl 40, (1 bsl 64) - 1, 1 bsl 100]],

    % A power of two has a single set bit, so its unsigned width is exactly one
    % more than its number of trailing zeroes
    [begin
         1 = integer_set_bits(P),
         UW = integer_unsigned_width(P),
         UW = integer_trailing_zeroes(P) + 1
     end || P <- [1, 2, 4, 1 bsl 31, 1 bsl 64, 1 bsl 130]],

    % Negated powers of two are the only negative numbers whose signed width
    % equals the unsigned width of their magnitude
    [begin
         UW = integer_unsigned_width(P),
         UW = integer_signed_width(id(-P)),
         Wider = integer_signed_width(id(-P - 1)),
         Wider = UW + 1
     end || P <- [1, 2, 4, 128, 1 bsl 40, 1 bsl 100]],

    % An all-ones value of N bits needs N bits unsigned and N+1 bits signed,
    % and has N set bits
    [begin
         AllOnes = (1 bsl N) - 1,
         N = integer_set_bits(id(AllOnes)),
         N = integer_unsigned_width(id(AllOnes)),
         SW = integer_signed_width(id(AllOnes)),
         SW = N + 1
     end || N <- [1, 8, 56, 64, 100, 200]],
    ok.

test_width_conditional_logic(_Config) ->
    % Test with conditional logic and pattern matching
    Classify = fun(N) ->
        case integer_unsigned_width(N) of
            0 -> zero;
            W when W =< 8 -> byte;
            W when W =< 64 -> word;
            _ -> big
        end
    end,
    zero = Classify(0),
    byte = Classify(1),
    byte = Classify(255),
    word = Classify(256),
    word = Classify((1 bsl 64) - 1),
    big = Classify(1 bsl 64),

    % integer_signed_width/1 answers "does this fit in a signed field?"
    Fits = fun(N, Bits) -> integer_signed_width(N) =< Bits end,
    true = Fits(0, 1),
    true = Fits(127, 8),
    false = Fits(128, 8),
    true = Fits(-128, 8),
    false = Fits(-129, 8),
    true = Fits(-(1 bsl 100), 101),
    false = Fits(-(1 bsl 100) - 1, 101),
    ok.

id(X) ->
    X.

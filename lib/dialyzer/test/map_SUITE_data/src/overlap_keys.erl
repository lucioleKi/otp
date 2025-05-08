-module(overlap_keys).

-export([t1/1]).

-spec func_general_key_first(#{
    % More general key first
    atom() => binary(),
    maybe_bin => binary() | undefined
}) -> a | b.

func_general_key_first(M) ->
    #{ maybe_bin := MaybeBin } = M,
    case MaybeBin of
        undefined -> a;
        Bin when is_binary(Bin) -> b
    end.

-spec func_specific_key_first(#{
    % More specific key first
    maybe_bin => binary() | undefined,
    atom() => binary()
}) -> a | b.

func_specific_key_first(M) ->
    #{ maybe_bin := MaybeBin } = M,
    case MaybeBin of
        % No warning in this case!
        undefined -> a;
        Bin when is_binary(Bin) -> b
    end.

t1(N) ->
    case N of
        0 ->
            a = func_general_key_first(#{maybe_bin => undefined}),
            a = func_specific_key_first(#{maybe_bin => undefined});
        _ ->
            b = func_general_key_first(#{maybe_bin => <<"some bin"/utf8>>}),
            b = func_specific_key_first(#{maybe_bin => <<"some bin"/utf8>>})
    end.

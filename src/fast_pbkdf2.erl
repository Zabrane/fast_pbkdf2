-module(fast_pbkdf2).
-on_load(load/0).
-nifs([pbkdf2_block/5]).

%% Taken from unexported crypto:sha3().
-type sha3() :: sha3_224 | sha3_256 | sha3_384 | sha3_512.
-type sha_type() :: crypto:sha1() | crypto:sha2() | sha3().

-export([pbkdf2/4, pbkdf2/5]).

%%% @doc
%%% This function calculates the pbkdf2 algorithm where dkLen is simply assumed to be that
%%% of the underlying hash function, a sane default.
-spec pbkdf2(sha_type(), binary(), binary(), non_neg_integer()) -> binary() | {error, atom()}.
pbkdf2(Hash, Password, Salt, IterationCount) ->
    pbkdf2_block(Hash, Password, Salt, IterationCount, 1).

%%% @doc
%%% This function allows to customise the desired dkLen parameter for pbkdf2.
-spec pbkdf2(sha_type(), binary(), binary(), non_neg_integer(), non_neg_integer()) ->
    binary() | {error, atom()}.
pbkdf2(Hash, Password, Salt, IterationCount, DkLen) ->
    pbkdf2(Hash, Password, Salt, IterationCount, DkLen, 1, [], 0).

%%%===================================================================
%%% Helper function
%%%===================================================================
pbkdf2(_Hash, _Password, _Salt, _IterationCount, DkLen, _BlockIndex, Acc, Len) when Len >= DkLen ->
    Bin = iolist_to_binary(lists:reverse(Acc)),
    binary:part(Bin, 0, DkLen);
pbkdf2(Hash, Password, Salt, IterationCount, DkLen, BlockIndex, Acc, Len) ->
    case pbkdf2_block(Hash, Password, Salt, IterationCount, BlockIndex) of
        {error, Reason} -> {error, Reason};
        Block ->
            pbkdf2(Hash, Password, Salt, IterationCount, DkLen, BlockIndex + 1,
                   [Block | Acc],
                   byte_size(Block) + Len)
    end.

%%%===================================================================
%%% NIF
%%%===================================================================
-spec pbkdf2_block(sha_type(), binary(), binary(), non_neg_integer(), non_neg_integer()) ->
    binary() | {error, atom()}.
pbkdf2_block(_Hash, _Password, _Salt, _IterationCount, _BlockSize) ->
    erlang:nif_error(not_loaded).

-spec load() -> any().
load() ->
    code:ensure_loaded(crypto),
    PrivDir = case code:priv_dir(?MODULE) of
                  {error, _} ->
                      EbinDir = filename:dirname(code:which(?MODULE)),
                      AppPath = filename:dirname(EbinDir),
                      filename:join(AppPath, "priv");
                  Path ->
                      Path
              end,
    erlang:load_nif(filename:join(PrivDir, ?MODULE_STRING), none).

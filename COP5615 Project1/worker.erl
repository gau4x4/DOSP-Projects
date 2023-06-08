-module(worker).
-export([run/1, askForString/3]).

run(Address) ->
    {getK, Address} ! {self()},
    receive
        {K, ClientID} ->
            register(talkserver, spawn(worker, askForString, [K, ClientID, Address])),
            talkserver ! {K, ClientID}
    end.

askForString(K, ClientID, Address) ->
    receive
        {List} ->
            mining_handler(K, ClientID, List, Address),
            askForString(K, ClientID, Address);
        {K, ClientID} ->
            {string_gen, Address} ! {self()},
            askForString(K, ClientID, Address)
    end.
mining_handler(K, ClientID, [], _Address) ->
    talkserver ! {K, ClientID};
mining_handler(K, ClientID, [Head | Tail], Address) ->
    Code = Head,

    HashCode = master:encode_sha(Code),
    KSubStr = string:substr(HashCode, 1, K),
    DuplicateZero = lists:concat(lists:duplicate(K, "0")),
    if
        KSubStr == DuplicateZero ->
            {print, Address} ! {ClientID, Code, HashCode},
            mining_handler(K, ClientID, Tail, Address);
        true ->
            mining_handler(K, ClientID, Tail, Address)
    end.

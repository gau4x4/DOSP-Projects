-module(master).
-export([
    run/1,
    print_stacktrace/0,
    connect_with_client/2,
    string_generator/0,
    encode_sha/1,
    generate_sha/1
]).

generate_sha(String) ->
    <<Integer:256>> = crypto:hash(sha256, String),
    Integer.
encode_sha(String) ->
    HexStr = string:right(integer_to_list(generate_sha(String), 16), 64, $0),
    string:to_lower(HexStr).

run(K) ->
    register(print, spawn(master, print_stacktrace, [])),
    register(getK, spawn(master, connect_with_client, [K, 0])),
    register(string_gen, spawn(master, string_generator, [])),
    mining_handler(print, K).

connect_with_client(K, ID) ->
    receive
        {From} ->
            From ! {K, ID + 1},
            connect_with_client(K, ID + 1)
    end.
string_generator() ->
    receive
        {From} ->
            % generate number of string
            List = generate_string(100, []),
            From ! {List},
            string_generator()
    end.

generate_string(Count, List) when Count > 0 ->
    Code = randomizer(),
    generate_string(Count - 1, List ++ [Code]);
generate_string(0, List) ->
    List.

randomizer() ->
    Random_Str = string:concat(
        "aayushsr",
        base64:encode_to_string(crypto:strong_rand_bytes(9))
    ),
    Random_Str.

mining_handler(print, K) ->
    Code = randomizer(),
    HashCode = master:encode_sha(Code),
    KSubStr = string:substr(HashCode, 1, K),
    DuplicateZero = lists:concat(lists:duplicate(K, "0")),
    if
        KSubStr == DuplicateZero ->
            try
                print ! {Code, HashCode},
                mining_handler(print, K)
            catch
                error:badarg -> exit(self(), kill)
            end;
        true ->
            mining_handler(print, K)
    end.

print_stacktrace() ->
    receive
        {Code, HashCode} ->
            io:format("Code: ~s\n", [Code]),
            io:format("SHA Hash: ~s\n", [HashCode]),
            {_, CPU_time} = statistics(runtime),
            {_, Run_time} = statistics(wall_clock),

            io:format("CPU time: ~p seconds\n", [CPU_time / 1000]),
            io:format("Real time: ~p seconds\n", [Run_time / 1000]),
            io:format("Ratio of CPU Time/Run Time: ~p \n", [CPU_time / Run_time]),
            exit(self(), kill)
    end.

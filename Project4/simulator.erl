-module(simulator).
-export([simulatorRunner/0]).

% Main Handler Runner for Client Simulating Tweeters.
simulatorRunner() ->
    io:fwrite("Tweeter Simulator Running\n\n"),

    {ok, [Cli_Count]} = io:fread("Total No of Client to Simulate: ", "~s\n"),
    {ok, [Max_Subs]} = io:fread(
        "Max Client Limit:", "~s\n"
    ),
    {ok, [Dict_MaxClient]} = io:fread(
        "\nClient Disconnection APR!:",
        "~s\n"
    ),

    C_Count = list_to_integer(Cli_Count),
    M_Subs = list_to_integer(Max_Subs),
    D_Client = list_to_integer(Dict_MaxClient),
    C_ToDict = D_Client * (0.01) * C_Count,
    io:format("Clients To Disconnect:\n", C_ToDict),

    Main_Table = ets:new(messages, [ordered_set, named_table, public]),
    clientListnerHandler(1, C_Count, M_Subs, Main_Table),

    ST = erlang:system_time(millisecond),

    ET = erlang:system_time(millisecond),
    io:format("Convergence Time: ~p ms\n", [ET - ST]).

% Handler Func for Client Generation
clientListnerHandler(Counter, Client_Count, MaxSubs, MainDB) ->
    U_Name = Counter,
    Tweet_Count = round(floor(MaxSubs / Counter)),
    Subs_Count = round(floor(MaxSubs / (Client_Count - Counter + 1))) - 1,

    PID = spawn(client, test, [U_Name, Tweet_Count, Subs_Count, false]),

    ets:insert(MainDB, {U_Name, PID}),
    if
        Counter == Client_Count ->
            ok;
        true ->
            clientListnerHandler(Counter + 1, Client_Count, MaxSubs, MainDB)
    end.
% Client Convergence Status Handler Func
clientStatusHandler(Clients) ->
    Active_Clients = [{C, CPID} || {C, CPID} <- Clients, is_process_alive(CPID) == true],
    if
        Active_Clients == [] ->
            io:format("Client Convergence Successful\n");
        true ->
            clientStatusHandler(Active_Clients)
    end.

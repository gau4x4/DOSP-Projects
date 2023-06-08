-module(twitter).
-import(maps, []).
-export([start/0]).
% Main Twitter Runner To Run All Functionalities
start() ->
    io:fwrite("\nWelcome to The DOSP Twitter Clone \n\n"),
    DB = ets:new(messages, [ordered_set, named_table, public]),
    Locale = ets:new(clients, [ordered_set, named_table, public]),
    Client_Arr = [],
    Map = maps:new(),
    {ok, LSID1} = gen_tcp:listen(1204, [
        binary, {keepalive, true}, {reuseaddr, true}, {active, false}
    ]),
    connectionHandler(LSID1, DB, Locale).
% ============================================================================HElper Methods
% Helper func to print Data Map Such as Tweet or anything
printerHelper(Map) ->
    List1 = maps:to_list(Map),
    io:format("~s~n", [stringHelperHandler(List1)]).

% Handler func overloading for String Operations of Tweet and retweet, HashTag
stringHelperHandler(L) ->
    stringHelperHandler(L, []).
% Handler func overloading for String Operations of Tweet and retweet, HashTag

stringHelperHandler([], S) ->
    lists:flatten([
        "[",
        string:join(lists:reverse(S), ","),
        "]"
    ]);
% Handler func overloading for String Operations of Tweet and retweet, HashTag

stringHelperHandler([{S1, S2} | R], S) ->
    S = ["{\"x\":\"", S1, "\", \"y\":\"", S2, "\"}"],
    stringHelperHandler(R, [S | S]).
% Handler func overloading for String Operations of Tweet and retweet, HashTag
% +================================================================ Ends Here
% Main Functionality Implementation for Tweeters
% The Handler Func for Data Request Handling: To Process All functionality from the Main Runner Func

receiveDirectMessageHandler(SID, DB, Bs, Locale) ->
    io:fwrite("Data Packet Received\n"),
    case gen_tcp:recv(SID, 0) of
        {ok, Data1} ->
            Data = re:split(Data1, ","),
            CmdType = binary_to_list(lists:nth(1, Data)),

            io:format("\nReceived Packet: ~p\n\n ", [Data]),
            io:format("\nPacket Type: ~p\n\n ", [CmdType]),

            if
                CmdType == "register" ->
                    U_Name = binary_to_list(lists:nth(2, Data)),
                    PID = binary_to_list(lists:nth(3, Data)),
                    io:format("\nPID:~p\n", [PID]),
                    io:format("\nSocket:~p\n", [SID]),
                    io:format("Type: ~p\n", [CmdType]),
                    io:format("\n~p wants to register an account\n", [U_Name]),

                    U_Name_Looked = ets:lookup(DB, U_Name),
                    io:format("The Username Found is: ~p\n", [U_Name_Looked]),
                    io:format("Connecting to websocket...\n\n"),

                    if
                        U_Name_Looked == [] ->
                            io:format("Connecting Successful\n\n"),

                            ets:insert(DB, {U_Name, [{"followers", []}, {"tweets", []}]}),
                            ets:insert(Locale, {U_Name, SID}),
                            U_Name_List = ets:lookup(DB, U_Name),
                            io:format("Found Uname As:~p", [lists:nth(1, U_Name_List)]),
                            ok = gen_tcp:send(SID, "User has been registered\n\n"),
                            io:fwrite("Processing Cleared Path to Entry\n\n");
                        true ->
                            ok = gen_tcp:send(
                                SID,
                                "A User with Similar details already exists in our Database, Please try with another Username"
                            ),

                            io:fwrite("Sorry!! A User already exists with this Username\n\n"),
                            io:format("Closing Connecting from websocket...\n\n")
                    end,
                    receiveDirectMessageHandler(SID, DB, [U_Name], Locale);
                CmdType == "tweet" ->
                    U_Name = binary_to_list(lists:nth(2, Data)),
                    Tweet = binary_to_list(lists:nth(3, Data)),
                    io:format("Connecting to websocket...\n\n"),

                    io:format("\n ~p Tweet Sent: ~p", [U_Name, Tweet]),

                    Val = ets:lookup(DB, U_Name),
                    io:format("Tweet Found: ~p\n", [Val]),
                    Val3 = lists:nth(1, Val),
                    Val2 = element(2, Val3),
                    Val1 = maps:from_list(Val2),
                    {ok, CurrentFollowers} = maps:find("followers", Val1),
                    {ok, CurrentTweets} = maps:find("tweets", Val1),

                    NewTweets = CurrentTweets ++ [Tweet],
                    io:format("~p~n", [NewTweets]),

                    ets:insert(
                        DB, {U_Name, [{"followers", CurrentFollowers}, {"tweets", NewTweets}]}
                    ),

                    Output_After_Tweet = ets:lookup(DB, U_Name),
                    io:format("\nNew Timeline: ~p\n", [Output_After_Tweet]),

                    directMessageHandler(
                        SID, Locale, Tweet, CurrentFollowers, U_Name
                    ),
                    io:format("Closing Connecting from websocket...\n\n"),

                    receiveDirectMessageHandler(SID, DB, [U_Name], Locale);
                CmdType == "retweet" ->
                    Ret_U_Name = binary_to_list(lists:nth(2, Data)),
                    U_Name = binary_to_list(lists:nth(3, Data)),
                    Subs_User = string:strip(Ret_U_Name, right, $\n),
                    io:format("Subscribed User: ~p\n", [Subs_User]),
                    Tweet = binary_to_list(lists:nth(4, Data)),
                    Out = ets:lookup(DB, Subs_User),
                    if
                        Out == [] ->
                            io:format("Connecting to websocket...\n\n"),

                            io:fwrite("User Not Found!\n");
                        true ->
                            Out1 = ets:lookup(DB, U_Name),
                            Val3 = lists:nth(1, Out1),
                            Val2 = element(2, Val3),
                            Val1 = maps:from_list(Val2),
                            Val_3 = lists:nth(1, Out),
                            Val_2 = element(2, Val_3),
                            Val_1 = maps:from_list(Val_2),
                            {ok, C_Follower} = maps:find("followers", Val1),
                            {ok, Tweets} = maps:find("tweets", Val_1),
                            io:format("Reposting Tweet As: ~p\n", [Tweet]),
                            CheckTweet = lists:member(Tweet, Tweets),
                            if
                                CheckTweet == true ->
                                    NewTweet = string:concat(
                                        string:concat(string:concat("re:", Subs_User), "->"), Tweet
                                    ),
                                    directMessageHandler(
                                        SID,
                                        Locale,
                                        NewTweet,
                                        C_Follower,
                                        U_Name
                                    );
                                true ->
                                    io:fwrite("Tweet Not Found!\n"),
                                    io:format("Closing Connecting from websocket...\n\n")
                            end
                    end,
                    io:format("Connecting to websocket...\n\n"),

                    io:format("\n ~p Retweeting!", [U_Name]),
                    receiveDirectMessageHandler(SID, DB, [U_Name], Locale);
                CmdType == "subscribe" ->
                    U_Name = binary_to_list(lists:nth(2, Data)),
                    Subs_U_Name = binary_to_list(lists:nth(3, Data)),
                    Subs_User = string:strip(Subs_U_Name, right, $\n),

                    Output1 = ets:lookup(DB, Subs_User),

                    if
                        Output1 == [] ->
                            io:format("Connecting to websocket...\n\n"),

                            io:fwrite("User Not Found!\n");
                        true ->
                            Val = ets:lookup(DB, Subs_User),
                            Val3 = lists:nth(1, Val),
                            Val2 = element(2, Val3),

                            Val1 = maps:from_list(Val2),
                            {ok, C_Follower} = maps:find("followers", Val1),
                            {ok, Tweets} = maps:find("tweets", Val1),

                            NewFollowers = C_Follower ++ [U_Name],
                            io:format("~p~n", [NewFollowers]),

                            ets:insert(
                                DB,
                                {Subs_User, [{"followers", NewFollowers}, {"tweets", Tweets}]}
                            ),

                            Output2 = ets:lookup(DB, Subs_User),
                            io:format("\nSubscription Successful: ~p\n", [Output2]),

                            ok = gen_tcp:send(SID, "Subscribed!"),
                            io:format("Closing Connecting from websocket...\n\n"),

                            receiveDirectMessageHandler(
                                SID, DB, [U_Name], Locale
                            )
                    end,
                    io:format("\n ~p -Subscribed- ~p\n", [U_Name, Subs_User]),

                    ok = gen_tcp:send(SID, "Subscribed!"),
                    receiveDirectMessageHandler(SID, DB, [U_Name], Locale);
                CmdType == "query" ->
                    Option = binary_to_list(lists:nth(3, Data)),
                    U_Name = binary_to_list(lists:nth(2, Data)),
                    io:format("Query: The current username is -> ~p\n", [U_Name]),
                    if
                        Option == "1" ->
                            io:format("Connecting to websocket...\n\n"),

                            io:fwrite("My mentions!\n");
                        Option == "2" ->
                            io:fwrite("Hashtag Search\n"),
                            Hashtag = binary_to_list(lists:nth(4, Data)),
                            io:format("Hashtag: ~p\n", [Hashtag]);
                        true ->
                            io:fwrite("Subscribed User Search\n"),
                            io:format("Connecting to websocket...\n\n"),

                            Sub_UserName = ets:first(DB),
                            Sub_User = string:strip(Sub_UserName, right, $\n),
                            io:format("Sub_UserName: ~p\n", [Sub_User]),
                            Val = ets:lookup(DB, Sub_User),
                            Val3 = lists:nth(1, Val),
                            Val2 = element(2, Val3),
                            Val1 = maps:from_list(Val2),
                            {ok, CurrentTweets} = maps:find("tweets", Val1),
                            io:format("\n ~p : ", [Sub_User]),
                            io:format("~p~n", [CurrentTweets]),
                            tweetTableLookup(DB, Sub_User, U_Name)
                    end,
                    io:format("\nThe User ~p is Searching...", [U_Name]),
                    io:format("Closing Connecting from websocket...\n\n"),

                    receiveDirectMessageHandler(SID, DB, [U_Name], Locale);
                true ->
                    io:fwrite("\n Default Menu")
            end;
        {error, closed} ->
            {ok, list_to_binary(Bs)};
        {error, Reason} ->
            io:fwrite("Waiting for connection..."),
            io:format("Connecting to websocket...\n\n"),

            io:fwrite(Reason)
    end.
% Handler Func for searching tweets from the table in (Helper Method for Retweet and Tweet Send)
tweetLookup(Keyword, Data, Sym) ->
    Search = string:concat(Keyword, Sym),
    io:format("Enter Anything to Search: ~p\n", [Search]),
    [Row_To_Check | _] = Data,
    res1 = lists:nth(2, Row_To_Check),
    res2 = element(2, res1),
    res3 = maps:from_list(res2),
    {ok, _} = maps:find("tweets", res3),
    io:fwrite("Tweet Lookup in Progress\n"),
    io:format("Connected to websocket...\n\n"),

    tweetLookup(Keyword, Data, Sym).

% Handler Func for handling Tweet Search from the entire Db Instead of looking for once a user per action

tweetTableLookup(DB, Key, U_Name) ->
    Row_Key = ets:next(DB, Key),
    Val = ets:lookup(DB, Row_Key),
    Val3 = lists:nth(1, Val),
    Val2 = element(2, Val3),
    Val1 = maps:from_list(Val2),
    {ok, Followers} = maps:find("followers", Val1),
    IsMember = lists:member(U_Name, Followers),
    if
        IsMember == true ->
            {ok, Tweets} = maps:find("tweets", Val1),
            io:format("\n ~p : ", [Row_Key]),
            io:format("~p~n", [Tweets]),
            tweetTableLookup(DB, Row_Key, U_Name);
        true ->
            io:fwrite("End of Tweet Line\n")
    end,
    io:fwrite("Lookup in Progress...\n").

connectionSeamHandler(SID) ->
    io:fwrite("Connection Pending..\n"),
    receive
        {tcp, SID, D} ->
            io:fwrite("...."),
            io:fwrite("\n ~p \n", [D]),
            if
                D == <<"register_account">> ->
                    io:fwrite("Impending Registration"),
                    ok = gen_tcp:send(SID, "username"),
                    io:fwrite("Registration Successful\n");
                true ->
                    io:fwrite("Welcome")
            end,
            connectionSeamHandler(SID);
        {tcp_closed, SID} ->
            io:fwrite("Server Connection in Progress"),
            io:format("Connecting to websocket...\n\n"),

            closed
    end.
% Handler func overloading for String Operations of Tweet and retweet, HashTag

% Handler To Process COnnection Request
connectionHandler(LSID, DB, Locale) ->
    {ok, SID} = gen_tcp:accept(LSID),
    ok = gen_tcp:send(SID, " "),
    spawn(fun() -> connectionHandler(LSID, DB, Locale) end),
    receiveDirectMessageHandler(SID, DB, [], Locale).

% Handler func for Tweet and Retweet Process
directMessageHandler(SID, Locale, Tweet, Subs, U_Name) ->
    if
        Subs == [] ->
            io:fwrite("0 Followers\n");
        true ->
            [CID | Sect_Dict] = Subs,
            io:format("-> ~p\n", [CID]),
            io:format("-> ~p~n", [Sect_Dict]),
            CSID = ets:lookup(Locale, CID),
            Val3 = lists:nth(1, CSID),
            C_SID = element(2, Val3),
            io:format("-> ~p~n", [C_SID]),

            ok = gen_tcp:send(C_SID, ["Tweet Received\n", U_Name, ":", Tweet]),
            ok = gen_tcp:send(SID, "Tweet Successful"),

            directMessageHandler(SID, Locale, Tweet, Sect_Dict, U_Name)
    end,
    io:fwrite("Tweet is Processing\n"),
    io:format("Closing Connecting from websocket...\n\n").

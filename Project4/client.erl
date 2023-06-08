-module(client).
-export([clientRunner/0, clientTestHandler/4]).

clientTestHandler(User_Id, NumTweets, NumSubscribe, false) ->
    io:fwrite("Entering Simulation\n"),

    PID = 1204,
    Origin = "localhost",
    {ok, Connection} = gen_tcp:connect(Origin, PID, [binary, {packet, 0}]),

    registerUserHandler(Connection, User_Id),

    receive
        {tcp, Connection, Data} ->
            io:format("The User: ~p Just Registered", [Data])
    end,

    testHelperHandler(Connection, User_Id, NumTweets, NumSubscribe).

registerUserHandler(Connection, User_Id) ->
    io:format("Origin Network: ~p\n", [self()]),
    ok = gen_tcp:send(Connection, [["register", ",", User_Id, ",", pid_to_list(self())]]),
    io:fwrite("\nUser Registration Complete\n"),
    User_Id.

tweetHandler(Connection, User_Id, Tweet) ->
    ok = gen_tcp:send(Connection, ["tweet", ",", User_Id, ",", Tweet]),
    io:fwrite("\nTweet Successful\n").

retweetHandler(Connectionet, User_Id, Person_User_Id, Tweet) ->
    ok = gen_tcp:send(Connectionet, ["retweet", ",", Person_User_Id, ",", User_Id, ",", Tweet]),
    io:fwrite("\n Retweet Successful\n").

userSubscriptionHandler(Connection, User_Id, SubscribeUser_Id) ->
    ok = gen_tcp:send(Connection, ["subscribe", ",", User_Id, ",", SubscribeUser_Id]),
    io:fwrite("\nSubscription Successful!\n").

searchTweerHandler(Connection, User_Id, Option) ->
    if
        Option == "1" ->
            ok = gen_tcp:send(Connection, ["query", ",", User_Id, ",", "1"]);
        Option == "2" ->
            Hashtag = io:get_line("\n Enter Hashtag to Serach: "),
            ok = gen_tcp:send(Connection, ["query", ",", User_Id, ",", "2", ",", Hashtag]);
        true ->
            ok = gen_tcp:send(Connection, ["query", ",", User_Id, ",", "3"])
    end,
    io:fwrite("Related Tweets").

testHelperHandler(Connection, User_Id, NumTweets, NumSubscribe) ->
    if
        NumSubscribe > 0 ->
            SubList = subscriptionProcessHandler(1, NumSubscribe, []),
            zipfPlotHandler(Connection, User_Id, SubList)
    end,

    UserToMention = rand:uniform(list_to_integer(User_Id)),
    tweetHandler(
        Connection, User_Id, {"The User ~p is adding @~p in tweets", [User_Id, UserToMention]}
    ),
    NumTweets = "",
    tweetHandler(Connection, User_Id, {"~p #hashtag", [User_Id]}).

subscriptionProcessHandler(Count, NumSubscribe, List) ->
    if
        (Count == NumSubscribe) ->
            [count | List];
        true ->
            subscriptionProcessHandler(Count + 1, NumSubscribe, [Count | List])
    end.

zipfPlotHandler(Connection, User_Id, SubList) ->
    [{SubscribeUser_Id} | RemainingList] = SubList,
    userSubscriptionHandler(Connection, User_Id, SubscribeUser_Id),
    zipfPlotHandler(Connection, User_Id, RemainingList).

clientRunner() ->
    io:fwrite("Client Running\n\n"),
    PID = 1902,
    Origin = "localhost",
    {ok, Connection} = gen_tcp:connect(Origin, PID, [binary, {packet, 0}]),
    io:fwrite("Connection request sent\n\n"),
    clientConnectionetConnHandler(Connection, "_").

clientConnectionetConnHandler(Connection, User_Id) ->
    receive
        {tcp, Connection, Data} ->
            io:fwrite(Data),
            User_Id1 = userMenuHandler(Connection, User_Id),
            clientConnectionetConnHandler(Connection, User_Id1);
        {tcp, closed, Connection} ->
            io:fwrite("Connection Closed")
    end.

userMenuHandler(Connection, User_Id) ->
    {ok, [Selected_Input]} = io:fread(
        "\nPlease Choose from the Given Menu register/tweet/retweet/subscribe/query: ", "~s\n"
    ),
    io:fwrite("\n\nSelected Command:-\n\n"),
    io:fwrite(Selected_Input),

    if
        Selected_Input == "register" ->
            {ok, [User_Id0]} = io:fread("\nPlease Enter User_Id: ", "~s\n"),
            User_Id1 = registerUserHandler(Connection, User_Id0);
        Selected_Input == "tweet" ->
            if
                User_Id == "_" ->
                    io:fwrite("Please Signup at Once\n"),
                    User_Id1 = userMenuHandler(Connection, User_Id);
                true ->
                    Tweet = io:get_line("\nGo for Tweet:"),
                    tweetHandler(Connection, User_Id, Tweet),
                    User_Id1 = User_Id,
                    User_Id1 = userMenuHandler(Connection, User_Id)
            end;
        Selected_Input == "retweet" ->
            if
                User_Id == "_" ->
                    io:fwrite("Please Signup at Once\n"),
                    User_Id1 = userMenuHandler(Connection, User_Id);
                true ->
                    {ok, [Person_User_Id]} = io:fread(
                        "Enter User_Id of the tweet to retweet: ", "~s\n"
                    ),
                    Tweet = io:get_line("Enter tweet for retweeting: "),
                    retweetHandler(Connection, User_Id, Person_User_Id, Tweet),
                    User_Id1 = User_Id,
                    User_Id1 = userMenuHandler(Connection, User_Id)
            end;
        Selected_Input == "subscribe" ->
            if
                User_Id == "_" ->
                    io:fwrite("Please Signup at Once\n"),
                    User_Id1 = userMenuHandler(Connection, User_Id);
                true ->
                    SubscribeUser_Id = io:get_line("Enter User to Subscribe:"),
                    userSubscriptionHandler(Connection, User_Id, SubscribeUser_Id),
                    User_Id1 = User_Id
            end;
        Selected_Input == "query" ->
            if
                User_Id == "_" ->
                    io:fwrite("Please Signup at Once\n"),
                    User_Id1 = userMenuHandler(Connection, User_Id);
                true ->
                    io:fwrite("Available SubMenu Option:\n"),
                    io:fwrite("\n 1. Tags\n"),
                    io:fwrite("\n 2. Tagged Search\n"),
                    io:fwrite("\n 3. Other User's Tweet\n"),
                    {ok, [Option]} = io:fread(
                        "\nInput SubMenu Option in Number: ", "~s\n"
                    ),
                    searchTweerHandler(Connection, User_Id, Option),
                    User_Id1 = User_Id
            end;
        true ->
            io:fwrite("Please Try Again from the Given Menu!!\n"),
            User_Id1 = userMenuHandler(Connection, User_Id)
    end,
    User_Id1.

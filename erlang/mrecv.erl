-module(mrecv).
-export([start/0, start_linked/0, start_forsup/0, getdict/0, getval/1]).
-export([init/0]).

% Spawn the process.
start() ->
	spawn(?MODULE, init, []).

% Spawn the process linked
start_linked() ->
	spawn_link(?MODULE, init, []).

% Spawn in an OTP/supervisor compliant way
start_forsup() ->
	{ok, start_linked()}.

% Initialize the multicast group and start the loop
init() ->
	register(mrecv, self()),
	{ok, GAddr}=inet:getaddr("225.0.0.37", inet),
	{ok, LAddr}=inet:getaddr("0.0.0.0", inet),
	{ok, Port} = gen_udp:open(6789, [{add_membership,{GAddr,LAddr}}]),
	loop(Port, dict:new()).

% Look for messages via multicast and keep a dict of the current values.
% Also, look for requests from other processes that want current temperature
% inforamtion.
loop(Port, Dict) ->
	receive
		% A UDP message
		{udp, Port, Raddr, Rport, S} ->
			% io:format("~p\n", [lists:sublist(S, (length(S)-1))]),
			Vals = string:tokens(S, "\t"),
			Key  = lists:nth(2, Vals),
			Val  = list_to_float(lists:nth(3, Vals)),
			loop(Port, dict:update(Key, fun(_) -> Val end, Val, Dict));
		% A lookup message for a specific serial number
		{lookup, From, SN} ->
			From ! dict:fetch(SN, Dict),
			loop(Port, Dict);
		% Just get the whole dict (useful for debugging)
		{getdict, From} ->
			From ! Dict,
			loop(Port, Dict);
		% Anything else
		Unhandled ->
			error_logger:error_msg("mrecv: Unhandled message:  ~p\n",
				[Unhandled]),
			loop(Port, Dict)
		% If I don't get a message from anything in 3 minutes, something's
		% wrong.  I should see a message at least once a minute when things are
		% working properly.
		after 180000 ->
			Reason = "Been too long since I've heard from a thermometer.",
			error_logger:error_msg("mrecv: Exiting:  ~p\n", [Reason]),
			exit(Reason)
	end.

% Get the dict from the mrecv
getdict() ->
	mrecv ! {getdict, self()},
	receive
		Rv -> Rv
	end.

% Get the current reading for the specific serial number
getval(SN) ->
	mrecv ! {lookup, self(), SN},
	receive
		Rv -> Rv
	end.

%% Based on code from 
%%   Erlang Programming
%%   Francecso Cesarini and Simon Thompson
%%   O'Reilly, 2008
%%   http://oreilly.com/catalog/9780596518189/
%%   http://www.erlangprogramming.org/
%%   (c) Francesco Cesarini and Simon Thompson

-module(f4).
-export([start_server/1,allocate/0,deallocate/1,stop/0]).
-export([init/1]).
-export([client/2, handle_allocate_response/3]).
-export([supervisor_init/0, test/0]).

test() ->
    spawn(f4, supervisor_init, []),
    timer:sleep(1000),  %Make sure server has started before allowing clients to send requests.
    _Client1 = spawn(f4, client, [1, 5000]),  %Arguments: [Id, Sleep]
    _Client2 = spawn(f4, client, [2, 3000]),  %Arguments: [Id, Sleep]
    testing.    

%========== SUPERVISOR =========

supervisor_init() ->
    io:format("supervisor_init: (~w)~n", [self()]),
    Server = start_server(self() ),
    io:format("supervisor_init: initial server started (~w)~n", [Server]),
   
    process_flag(trap_exit, true),
    supervisor(Server).

supervisor(Server) ->
    receive
        {'EXIT', Server, Reason} ->  %Server is bound!
            io:format("supervisor: 'EXIT' from: (~w), reason: ~w~n", [Server, Reason]),
            NewServer = start_server(self() ),
            io:format("supervisor: restarted server (~w)~n", [NewServer]),
            supervisor(NewServer);
        _Other ->
            supervisor(Server)
    end.

%========== CLIENT ============

client(Id, Sleep) ->
    handle_allocate_response(allocate(), Id, Sleep).

handle_allocate_response({ok, Freq}, Id, Sleep) ->
    io:format("client~w (~w) got frequency: ~w~n", 
              [Id, self(), Freq]),

    timer:sleep(Sleep),
    deallocate(Freq),  %Always succeeds.

    io:format("client~w (~w) deallocated frequency: ~w~n",
              [Id, self(), Freq]),

    client(Id, Sleep);
handle_allocate_response({error, no_frequency}, Id, Sleep) ->
    io:format("client~w (~w): no frequencies available~n",
              [Id, self()]),

    timer:sleep(500),  %Wait for a short time before trying again.
    client(Id, Sleep).


%=========== SERVER ===========

start_server(Supervisor) ->
    Server = spawn_link(f4, server_init, [Supervisor]),
    register(f4, Server),
    Server.

%----------

server_init(Supervisor) ->
  process_flag(trap_exit, true),    
  Frequencies = {get_frequencies(), []},
  loop(Frequencies, Supervisor).

% Hard Coded
get_frequencies() -> [10,11,12,13,14,15].

%% The Main Loop

loop(Frequencies, Supervisor) ->
  receive
    {request, Pid, allocate} ->
      {NewFrequencies, Reply} = allocate(Frequencies, Pid),
      Pid ! {reply, Reply},
      loop(NewFrequencies, Supervisor);
    {request, Pid , {deallocate, Freq}} ->
      NewFrequencies = deallocate(Frequencies, Freq),
      Pid ! {reply, ok},
      loop(NewFrequencies, Supervisor);
    {request, Pid, stop} ->
      Pid ! {reply, stopped};

    {'EXIT', Supervisor, _Reason} ->  %'EXIT' from supervisor
      io:format("server (~w) exiting: got exit signal from: ~w~n", [self(), Supervisor]),
      exit(shutdown);  %Kill server and clients that have been allocated frequencies.
    {'EXIT', Pid, _Reason} ->  %'EXIT' from client              
      NewFrequencies = exited(Frequencies, Pid), 
      loop(NewFrequencies, Supervisor)
  end.

%% ========= NO CHANGES BELOW HERE =============

%% Functional interface

allocate() -> 
    f4 ! {request, self(), allocate},
    receive 
	    {reply, Reply} -> Reply
    end.

deallocate(Freq) -> 
    f4 ! {request, self(), {deallocate, Freq}},
    receive 
	    {reply, Reply} -> Reply
    end.

stop() -> 
    f4 ! {request, self(), stop},
    receive 
	    {reply, Reply} -> Reply
    end.


%% The Internal Help Functions used to allocate and
%% deallocate frequencies.

allocate({[], Allocated}, _Pid) ->
  {{[], Allocated}, {error, no_frequency}};
allocate({[Freq|Free], Allocated}, Pid) ->
  link(Pid),                                               %%% ADDED
  {{Free, [{Freq, Pid}|Allocated]}, {ok, Freq}}.

deallocate({Free, Allocated}, Freq) ->
  {value,{Freq,Pid}} = lists:keysearch(Freq,1,Allocated),  %%% ADDED
  unlink(Pid),                                             %%% ADDED
  NewAllocated=lists:keydelete(Freq, 1, Allocated),
  {[Freq|Free],  NewAllocated}.

exited({Free, Allocated}, Pid) ->                %%% FUNCTION ADDED
    case lists:keysearch(Pid,2,Allocated) of
      {value,{Freq,Pid}} ->
        NewAllocated = lists:keydelete(Freq,1,Allocated),
        {[Freq|Free],NewAllocated}; 
      false ->
        {Free,Allocated} 
    end.


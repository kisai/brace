-module(jxat_receive).

-export([given/3, 'when'/3, then/3]).
-include_lib("eunit/include/eunit.hrl").

given([a,module,that,has,a,'receive',clause], _State, _) ->
   Source = <<"(ns jxat-receive-test
                    (require erlang))
                (defmacro foo-timeout () 300)

                (defn+ receive-test1 ()
                      (receive
                        ({:x foo}
                            foo)))

                (defn+ receive-test2 ()
                      (receive
                        (after (foo-timeout) 123)
                        ({:x foo}
                            foo)))

                (defn+ do-test (pid val)
                   (erlang/send pid {:x val}))">>,

    {ok, Source}.

'when'([joxa,is,called,on,this,module], Source, _) ->
    Result = 'joxa-compiler':forms(Source, []),
    {ok, Result}.

then([a,beam,binary,is,produced], Ctx, _) ->
    ?assertMatch(true, is_binary('joxa-cmp-ctx':'get-context'(result, Ctx))),
    ?assertMatch(false, 'joxa-compiler':'has-errors?'(Ctx)),
    {ok, Ctx};
then([the,described,function,can,be,called,'and',works,correctly], State, _) ->
    Pid = erlang:spawn_link(fun () ->
                                    ?assertMatch('got-it',
                                                 'jxat-receive-test':'receive-test1'())
                            end),

    erlang:send(Pid, {x, 'got-it'}),

    Id = erlang:make_ref(),
    Self = erlang:self(),
    erlang:spawn_link(fun () ->
                              Self ! {done, Id, 'jxat-receive-test':'receive-test2'()}

                      end),
    receive
        {done, Id, Value} ->
            ?assertMatch(123, Value)
    after 1000 ->
            ?assertMatch(fail, right_now)
    end,

    {ok, State}.

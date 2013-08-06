-module(extender).
-export([parse_transform/2]).
-record(extend, {
        exports     = [],
        required    = [],
        new_exports = [],

        attributes  = [],
        body        = []
    }).

parse_transform(Forms, _Options) ->
    Extend = scan_forms(Forms),
    Res = extend(Extend),
    io:format("~n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~n~p~n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~n", [Res]),
    Res.

scan_forms(Forms) ->
    scan_forms(Forms, #extend{}).

scan_forms([], Extend) ->
    Extend;
scan_forms([Form|Forms], Extend) ->
    Extend1 = scan_form(Form, Extend),
    scan_forms(Forms, Extend1).

scan_form(Attr = {attribute, _N, extends, Module}, Extend = #extend{required = Req, attributes = Attrs}) ->
    NewReq = [{Module, Details} || Details <- Module:module_info(exports), Details /= {module_info, 0}, Details /= {module_info, 1} ],
    Extend#extend{attributes = [Attr|Attrs], required = Req ++ NewReq};
scan_form(Attr = {attribute, _N, export, Exports}, Extend = #extend{exports = Curr, attributes = Attrs}) ->
    Extend#extend{exports = Curr ++ Exports, attributes = [Attr|Attrs]};
scan_form(Attr = {attribute, _N, _F, _V}, Extend = #extend{attributes = Attrs}) ->
    Extend#extend{attributes = [Attr|Attrs]};
scan_form(Body, Extend = #extend{body = Bodies}) ->
    Extend#extend{body = [Body|Bodies]}.

extend(Extend = #extend{body = Bodies}) ->
    finish(do_extend(Extend)).

do_extend(Extend = #extend{required = []}) ->
    Extend;
do_extend(Extend = #extend{exports = Exports, required = [{Module, {Function, Arity}}|Required], new_exports = NewExports, body = Body}) ->
    Extend1 = Extend#extend{required = Required},
    case lists:member({Function, Arity}, Exports) of
        true ->
            do_extend(Extend1);
        false ->
            Vars = [ {var, 0, list_to_atom("Arg" ++ integer_to_list(N))} || N <- lists:seq(1, Arity) ],
            NewForm = {function, 0, Function, Arity, [
                    {clause, 0, Vars, [], [
                            {call, 0, {remote, 0, {atom, 0, Module}, {atom, 0, Function}}, Vars}
                        ]}
                ]},
            Extend2 = Extend1#extend{
                exports = [{Function, Arity}|Exports], 
                new_exports = [{Function, Arity}|NewExports],
                body = [NewForm|Body]
            },
            do_extend(Extend2)
    end.

finish(Extend = #extend{new_exports = [], attributes = Attr, body = Body}) ->
    lists:reverse(Attr) ++ lists:reverse(Body);
finish(Extend = #extend{new_exports = NewExports, attributes = Attrs}) ->
    NewAttr = {attribute, 0, export, NewExports},
    Extend2 = Extend#extend{new_exports = [], attributes = [NewAttr|Attrs]},
    finish(Extend2).

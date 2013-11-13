% sudo ../dist/yaws/bin/yaws -i

%% a small shoppingcart example which tries to show
%% a variety of tricks and tacticts to display a
%% shoppingcart style page with server side state.

-module(forums).
-author('pythonesque@gmail.com').

-compile(export_all).
% -include("../../include/yaws_api.hrl").
-include("../../../../lib/yaws/include/yaws_api.hrl").
-include_lib("kernel/include/inet.hrl").
% -include_lib("../../../../lib/yaws/kernel/include/inet.hrl").

% -module(shopcart).
% -author('klacke@hyber.org').

% -compile(export_all).
% -include("../../include/yaws_api.hrl").
% -include_lib("kernel/include/inet.hrl").


% %% this is the opaque structure we pass to the
% %% yaws cookie session server

% -record(post, {id,
%                parent_id}).

-include_lib("stdlib/include/qlc.hrl").
-include("forums.hrl").

% -record(post, {id = 0,
%                parent_id = 0}).

% -record(ancestor_post, {id = 0,
%                         ancestor_id = 0}).

% -record(counter, {key,
%                   value = 0}).

start() ->
  mnesia:start(),
  init_db().

init_db() ->
    % N1 = node(),
    % io:format("Node ~p~n", [N1]),
    mnesia:create_table(post,
                        [{index, [parent_id]},
                         {type, set},
                         % {disc_copies, [N1]},
                         {attributes, record_info(fields, post)}]),
    % io:format("Ret ~p~n", [Ret]),
    mnesia:create_table(ancestor_post,
                        [{index, [ancestor_id]},
                         {type, bag},
                         % {disc_copies, [N1]},
                         {attributes, record_info(fields, ancestor_post)}]),
    mnesia:create_table(counter,
                        [{type, set},
                        % {disc_copies, [N1]},
                         {attributes, record_info(fields, counter)}]),
    Fun = fun() -> Post = #post{id = 0, parent_id = 0},
                   mnesia:write(Post)
          end,
    mnesia:transaction(Fun).

destroy_db() ->
  mnesia:wait_for_tables([post,counter,ancestor_post], 60000),
  mnesia:delete_table(post),
  mnesia:delete_table(counter),
  mnesia:delete_table(ancestor_post).

-record(sess, {

}).

%% this function extracts the session from the cookie
check_cookie(A) ->
    H = A#arg.headers,
    case yaws_api:find_cookie_val("ssid", H#headers.cookie) of
        Val when Val /= [] ->
            case yaws_api:cookieval_to_opaque(Val) of
                {ok, Sess} ->
                    {ok, Sess, Val};
                {error, {has_session, Sess}} ->
                    {ok, Sess};
                Else ->
                    Else
            end;
        [] ->
            {error, nocookie}
    end.

% %% this function extracts the session from the cookie
% check_cookie(A) ->
%     H = A#arg.headers,
%     case yaws_api:find_cookie_val("ssid", H#headers.cookie) of
%         Val when Val /= [] ->
%             case yaws_api:cookieval_to_opaque(Val) of
%                 {ok, Sess} ->
%                     {ok, Sess, Val};
%                 {error, {has_session, Sess}} ->
%                     {ok, Sess};
%                 Else ->
%                     Else
%             end;
%         [] ->
%             {error, nocookie}
%     end.


% %% this function is calle first in all out yaws files,
% %% it will autologin users that are not logged in
% top(A) ->
%     case check_cookie(A) of
%         {ok, _Session, _Cookie} ->
%             ok;
%         {error, _Reason} ->
%             login(A)
%     end.
%% this function is calle first in all out yaws files,
%% it will autologin users that are not logged in
top(A) ->
  case check_cookie(A) of
    {ok, _Session, _Cookie} ->
        ok;
    {error, _Reason} ->
        login(A)
  end.


%% generate a css head  the title of the page set dynamically
css_head(PageTitle) ->
    Z =
    [<<"<!DOCTYPE html>
<html>
<head>
<title>">>,
  PageTitle,
  <<"</title>
</head>
<body>">>
    ],
    {html, Z}.
%     [<<"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">
% <html>

% <head>
%  <meta name=\"keywords\" content=\"Nortel Extranet VPN\">
%  <title>">>,
%      PageTitle,
%      <<"</title>
%  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">
%  <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">
% </head>

% <body bgcolor=\"linen\">

% ">>
%     ],
%     {html, Z}.



% %% the little status field in the upper left corner
% head_status(User) ->
%     {ehtml,
%      {table, [],
%       {tr, [],
%        [{td, [{width, "30%"}],
%          {table, [ {border, "1"}, {bgcolor, beige},{bordercolor, black}],
%           [{tr, [], {td, [], pb("User: ~s", [User])}}
%           ]}
%         },
%         {td, [{align, right}], {img, [{src, "junk.jpg"}
%                                      ]}}
%        ]
%       }
%      }
%     }.


% %% bold paragraph according to style.css
% pb(Fmt, Args) ->
%     {p, [{class, pb}], io_lib:format(Fmt, Args)}.


% %% toprow of buttons to push
% toprow() ->
%     {ehtml,
%      {table, [{cellspacing, "4"},
%               {bgcolor, tan},
%               {width, "100%"}
%               ],
%       [
%        {tr, [],
%         [{td, [], {a, [{href, "buy.yaws"}] , {p, [{class, toprow}], "Buy"}}},
%          {td, [], {a, [{href, "logout.yaws"}], {p, [{class, toprow}], "Logout"}}},
%          {td, [], {a, [{href, "source.html"}], {p, [{class, toprow}], "The Source"}}},
%          {td, [{width, "70%"}], ""}
%         ]}
%       ]
%      }
%     }.



%% kinda hackish since we us ehtml
bot() ->
    {html, "</body>\n</html>\n"}.



% %% This function displays the login page
login(A) ->
    CSS = css_head("Forums"),
    % Head = head_status("Not lgged in"),
    % Top = toprow(),
    Login =
        {ehtml,
         [{h2, [], "Forum login"},
          {form, [{method, get},
                  {action, "loginpost.yaws"}],
           [
            % {p, [], "Username"},
            % {input, [{name, user},
            %          {type, text},
            %          {value, "Joe Junk shopper"},
            %          {size, "48"}]},


            % {p, [], "Password"},
            % {input, [{name, password},
            %          {type, text},
            %          {value, "xyz123"},
            %          {size, "48"}]},

            {input, [{type, submit},
                     {value, "Login"}]},

            {input, [{name, url},
                     {type, hidden},
                     {value, xpath((A#arg.req)#http_request.path, A)}]}
           ]
           }
         ]},
    % [CSS, Head, Top, Login, bot(), break].
    [CSS, Login, bot(), break].

% %% This function displays the login page
% login(A) ->
%     CSS = css_head("Shopcart"),
%     Head = head_status("Not lgged in"),
%     Top = toprow(),
%     Login =
%         {ehtml,
%          [{h2, [], "Shopcart login"},
%           {form, [{method, get},
%                   {action, "loginpost.yaws"}],
%            [
%             {p, [], "Username"},
%             {input, [{name, user},
%                      {type, text},
%                      {value, "Joe Junk shopper"},
%                      {size, "48"}]},


%             {p, [], "Password"},
%             {input, [{name, password},
%                      {type, text},
%                      {value, "xyz123"},
%                      {size, "48"}]},

%             {input, [{type, submit},
%                      {value, "Login"}]},

%             {input, [{name, url},
%                      {type, hidden},
%                      {value, xpath((A#arg.req)#http_request.path, A)}]}
%            ]
%            }
%          ]},
%     [CSS, Head, Top, Login, bot(), break].




logout(A) ->
    {ok, _Sess, Cookie} = check_cookie(A),
    yaws_api:delete_cookie_session(Cookie),
    {ehtml, {h3, [], "Yo, "}}.




% %% This is the function that gets invoked when the
% %% user has attempted to login
% %% The trick used here is to pass the original URL in a hidden
% %% field into this function, if the login is successful, we redirect
% %% to the original URL.

% loginpost(A) ->
%     case {yaws_api:queryvar(A, "user"),
%           yaws_api:queryvar(A, "url"),
%           yaws_api:queryvar(A, "password")} of

%         {{ok, User},
%          {ok, Url},
%          {ok, Pwd}} ->

%             %% here's the place to validate the user
%             %% we allow all users,
%             io:format("User ~p logged in ~n", [User]),
%             Sess = #sess{user = User,
%                          passwd = Pwd},
%             Cookie = yaws_api:new_cookie_session(Sess),
%             [yaws_api:redirect(Url),
%              yaws_api:setcookie("ssid",Cookie)];
%         _ ->
%             login(A)
%     end.

%% This is the function that gets invoked when the
%% user has attempted to login
%% The trick used here is to pass the original URL in a hidden
%% field into this function, if the login is successful, we redirect
%% to the original URL.

loginpost(A) ->
    % case {yaws_api:queryvar(A, "user"),
    %       yaws_api:queryvar(A, "url"),
    %       yaws_api:queryvar(A, "password")} of

    %     {{ok, User},
    %      {ok, Url},
    %      {ok, Pwd}} ->
    case yaws_api:queryvar(A, "url") of
        {ok, Url} ->

            %% here's the place to validate the user
            %% we allow all users,
            % io:format("User ~p logged in ~n", [User]),
            % Sess = #sess{user = User,
                         % passwd = Pwd},
            Sess = #sess{},
            Cookie = yaws_api:new_cookie_session(Sess),
            [yaws_api:redirect(Url),
             yaws_api:setcookie("ssid",Cookie)];
        _ ->
            login(A)
    end.

xpath({abs_path, P}, _A) ->
    P.

%% this is the function that gets the form when the user
%% hits "update Cart"

formupdate(A) ->
    {ok, Sess, Cookie} = check_cookie(A),
    % _J = junk(),
    % Items = Sess#sess.items,
    L = yaws_api:parse_post(A),
    % I2 = handle_l(L, Items),
    io:format("~p~n", L),
    handle_l(L),
    Sess2 = Sess#sess{},
    yaws_api:replace_cookie_session(Cookie, Sess2),
    {redirect, "index.yaws"}.  %% force browser to reload
% reply(A) ->

% %% this is the function that gets the form when the user
% %% hits "update Cart"

% formupdate(A) ->
%     {ok, Sess, Cookie} = check_cookie(A),
%     _J = junk(),
%     Items = Sess#sess.items,
%     L = yaws_api:parse_post(A),
%     I2 = handle_l(L, Items),
%     Sess2 = Sess#sess{items = I2},
%     yaws_api:replace_cookie_session(Cookie, Sess2),
%     {redirect, "index.yaws"}.  %% force browser to reload
% reply(A) ->
  

new_post(ParentId) ->
  Fun = fun() ->
    case mnesia:read(post, ParentId) of % make sure parent exists
      [] ->
        mnesia:abort({badparent, ParentId}); % invalid parent
      _ ->
        NextIndex = mnesia:dirty_update_counter(counter, post, 1),
        Post = #post{id = NextIndex, parent_id = ParentId},
        mnesia:write(Post),
        AddAncestor = fun(AncestorId, _) ->
          Ancestor = #ancestor_post{id = NextIndex, ancestor_id = AncestorId},
          mnesia:write(Ancestor)
        end,
        foldu_post(AddAncestor, ok, ParentId),
        {ok,NextIndex}
    end
  end,
  mnesia:transaction(Fun).

% foldd_post(Fun, Acc, ParentId) ->
%   case 
%     mnesia:dirty_index_read(post, ParentId, #post.parent_id) of
%     [] -> Acc; % leaf[]
%     L ->
%       Fun2 = fun(Id, Acc2) ->
%               case Id#post.id of
%                 0 -> Acc2;
%                 Pid -> foldd_post(Fun, Fun(Id, Acc2), Pid)
%               end
%             end,
%       lists:foldl(Fun2, Acc, L)
%   end.
foldd_post(Fun, Acc, AncestorId) ->
  L = mnesia:dirty_index_read(ancestor_post, AncestorId, #ancestor_post.ancestor_id),
  Fun2 = fun(Id, Acc2) -> Fun(Id#ancestor_post.id, Acc2) end,
  lists:foldl(Fun2, Acc, L).

% foldu_post(Fun, Acc, Id) ->
%   case Id of
%     0 -> Fun(0, Acc); % root
%     % 0 -> Acc; % root
%     _ ->
%       [Parent] = mnesia:dirty_read(post, Id),
%       foldu_post(Fun, Fun(Id, Acc), Parent#post.parent_id)
%   end.
foldu_post(Fun, Acc, Id) ->
  case Id of
    % 0 -> Fun(0, Acc); % root
    0 -> Acc; % root
    _ ->
      L = mnesia:dirty_read(ancestor_post, Id),
      Fun2 = fun(PId, Acc2) -> Fun(PId#ancestor_post.ancestor_id, Acc2) end,
      lists:foldl(Fun2, Fun(Id, Acc), L)
  end.

handle_l([]) -> ok;
handle_l([{"id", Num} | Tail]) ->
  case catch list_to_integer(Num) of
    Int when is_integer(Int) ->
      new_post(Int);
    _ -> handle_l(Tail)
  end;
handle_l([H|T]) -> handle_l(T).

% handle_l([], Items) ->
%     Items;
% handle_l([{Str, Num} | Tail], Items) ->
%     case catch list_to_integer(Num) of
%         Int when is_integer(Int) ->
%             handle_l(Tail, [{Str, Int} | lists:keydelete(Str,1, Items)]);
%         _ ->
%             handle_l(Tail, Items)
%     end.


% ip(A) ->
%     S = A#arg.clisock,
%     case inet:peername(S) of
%         {ok, {Ip, _Port}} ->
%             case inet:gethostbyaddr(Ip) of
%                 {ok, HE} ->
%                     io_lib:format("~s/~s", [fmtip(Ip), HE#hostent.h_name]);
%                 _Err ->
%                     io_lib:format("~s", [fmtip(Ip)])
%             end;
%         _ ->
%             []
%     end.

% fmtip({A,B,C,D}) ->
%     io_lib:format("~w.~w.~w.~w", [A,B,C,D]).


% %% generate the final "you have bought page ... "
% buy(A) ->
%     {ok, Sess, _Cookie} = check_cookie(A),
%     Css = css_head("Shopcart"),
%     Head = head_status(Sess#sess.user),
%     Top = toprow(),
%     BROWS = b_rows(Sess#sess.items),
%     Res =
%         if
%             length (BROWS) > 0 ->
%                 {ehtml,
%                  [{h4, [], "Congratulations, you have bought"},
%                   {table, [],BROWS},
%                   {hr},
%                   {p , [{class, toprow}],
%                    io_lib:format(
%                      "Items are at this very moment being shipped to the"
%                      " residens of the computer with IP: ~s~n", [ip(A)])}
%                  ]
%                 };
%             true ->
%                 {ehtml,
%                  [{h4, [], "Congratulations, you have bought nothing"}]}
%         end,


%     [Css, Head, Top, Res, bot()].


% b_rows(Items) ->
%     J = junk(),
%     Desc = {tr,[],
%             [
%              {th, [], pb("Description",[])},
%              {th, [], pb("Quantity",[])},
%              {th, [], pb("Sum ",[])}]},

%     [Desc | b_rows(Items, J, 0, [])].

% b_rows([{Desc, Num}|Tail], Junk, Ack, TRS) when Num >  0 ->
%     {value, {_, Price}} = lists:keysearch(Desc, 1, Junk),
%     A = Num * Price,
%     TR = {tr, [],
%           [{td, [], Desc},
%            {td, [], io_lib:format("~w", [Num])},
%            {td, [], io_lib:format("~w", [A])}
%           ]},
%     b_rows(Tail, Junk, A+Ack, [TR|TRS]);

% b_rows([{_Desc, Num}|Tail], Junk, Ack, TRS) when Num ==  0 ->
%      b_rows(Tail, Junk, Ack, TRS);

% b_rows([], _, Ack, TRS) when Ack > 0 ->
%     Tax = round(0.27 * Ack),
%     Empty = {td, [], []},
%     TaxRow = {tr, [],
%               [
%                {td, [],  pb("Swedish VAT tax 27% ",[])},
%                Empty,
%                {td, [], pb("~w", [Tax])}
%               ]},
%     Total = {tr, [],
%               [
%                {td, [],  pb("Total ",[])},
%                Empty,
%                {td, [], pb("~w", [Ack + Tax])}
%               ]},

%     lists:reverse([Total, TaxRow | TRS]);
% b_rows(_, _,_,_) ->
%     [].



%% this is the main function which displays
%% the shopcart .....
%% the entire shopcart is one big form which gets posted
%% when the user updates the shopcart
% index(A) ->
%  {ehtml, [{html, [], []}]}.
index(A) ->
    {ok, Sess, _Cookie} = check_cookie(A),
%     % io:format("Inside index: ~p~n", [Sess#sess.items]),
    % io:format("Foo"),
    Css = css_head("Forums"),
    % Head = head_status(Sess#sess.user),
%     % Top = toprow(),
    Forum =
        {ehtml,
          {form,
           [{name, form},
            {method, post},
            {action, "forum_form.yaws"}],
           [
            {p, [],
             foldd_post(fun display_post/2, [], 1)},

            {input, [{type, submit}, {value, "Reply"}]}
           ]
          }
         },
%     % Cart =
%     %     {ehtml,
%     %      {form,
%     %       [{name, form},
%     %        {method,post},
%     %        {action, "shopcart_form.yaws"}],
%     %       [
%     %        {table, [{bgcolor, linen}, {border, "2"}],
%     %         rows(Sess#sess.items)},

%     %        {input, [{type, submit}, {value, "Update Cart"}]}
%     %       ]
%     %      }
%     %     },

%     % [Css, Head, Top, Cart, bot()].
    [Css, Forum, bot()].

% %% this is the main function which displays
% %% the shopcart .....
% %% the entire shopcart is one big form which gets posted
% %% when the user updates the shopcart
% index(A) ->
%     {ok, Sess, _Cookie} = check_cookie(A),
%     io:format("Inside index: ~p~n", [Sess#sess.items]),
%     Css = css_head("Shopcart"),
%     Head = head_status(Sess#sess.user),
%     Top = toprow(),
%     Cart =
%         {ehtml,
%          {form,
%           [{name, form},
%            {method,post},
%            {action, "shopcart_form.yaws"}],
%           [
%            {table, [{bgcolor, linen}, {border, "2"}],
%             rows(Sess#sess.items)},

%            {input, [{type, submit}, {value, "Update Cart"}]}
%           ]
%          }
%         },

%     [Css, Head, Top, Cart, bot()].


% %% this function gets a list of
% %% {JunkString, Num} and displays the current shopcart

% rows(Items) ->
%     Junk = junk(),
%     First = {tr, [],
%              [{th, [], pb("Num Items", [])},
%               {th, [], pb("Item description", [])},
%               {th, [], pb("Price SEK ",[])}
%              ]},

%     L = lists:map(
%           fun({Desc, Price}) ->
%                   {tr, [],
%                     [{td, [],
%                       {input, [{type, text},
%                                {width, "4"},
%                                {value, jval(Desc, Items)},
%                                {name, Desc}]}},
%                      {td, [], {p, [], Desc}},
%                      {td, [], pb("~w ", [Price])}
%                     ]}
%           end, Junk),

%     Total = total(Items, Junk, 0),
%     Tax = round(0.27 * Total),
%     T = [{tr, [],
%           [{td, [], pb("Sum accumulated",[])},
%            {td, [{colspan, "2"}], pb("~w SEK", [Total])}
%           ]
%          },
%          {tr, [],
%           [
%            {td, [], pb("Swedish VAT tax 27 % :-)",[])},
%            {td, [{colspan, "2"}], pb("~w SEK", [Tax])}
%           ]
%          },

%          {tr, [],
%           [
%            {td, [], pb("Total",[])},
%            {td, [{colspan, "2"}], pb("~w SEK", [Total  + Tax])}
%           ]
%          }
%         ],

%     _Rows = [First | L] ++ T.





% %% The Items are picked up by the
% %% formupdate function and set accordingly in the opaque state
% %% this function recalculates the sum total

% total([{Str, Num} | Tail], Junk, Ack) ->
%     {value, {Str, Price}} = lists:keysearch(Str, 1, Junk),
%     total(Tail, Junk, (Num * Price) + Ack);
% total([], _,Ack) ->
%     Ack.


% %% We need to set the value in each input field
% jval(Str, Items) ->
%     case lists:keysearch(Str, 1, Items) of
%         {value, {_, Num}} when is_integer(Num) ->
%             integer_to_list(Num);
%         false ->
%             "0"
%     end.


% %% the store database :-)
% %% {Description, Price} tuples
% junk() ->
%     [{"Toothbrush in rainbow colours", 18},
%      {"Twinset of extra soft towels", 66},
%      {"Hangover pill - guaranteed to work", 88},
%      {"Worlk-out kit that fits under your bed", 1900},
%      {"100 pack of headache pills", 7},
%      {"Free subscription to MS update packs", 999},
%      {"Toilet cleaner", 1111},
%      {"Body lotion 4 litres", 888},
%      {"Yello, a lifetime supply", 99}].


display_post(Post, Ehtml) ->
  [
    % {tr, [],
    %  [{td, [], ['Post']}]}
    {input, [{type,radio},{name,id},{value,Post}]}
   | Ehtml].
<%inherit file="base.mako"/>
<%namespace name="nav" file="nav.mako" />
<%
import datetime
%>
<%block name="navigation">
${nav.nav('servers')}
</%block>

<%block name="title">
% if server:
Server Information
% endif
</%block>

<%block name="css">
    ${parent.css()}
</%block>

<%block name="js">
  ${parent.js()}
<script>
function loadLivePlayers() {
  var url = "${request.registry.settings.get('qlstat.feeder_webapi_url', '')}" || "http://" + location.hostname + ":8081";
  url = url.replace(/\/$/, "") + "/api/server/${server.ip_addr}:${server.port}/players";

  $.getJSON(url, function(data) {
    if (!data.ok)
      return;
    data.players.sort(function(a,b) {
      var c = [5,3,1,2,4][a.team+1] - [5,3,1,2,4][b.team+1]; // red, blue, free, spec, unknown
      if (c != 0) return c;
      return (b.rating||0) - (a.rating||0)
    });
    var $table=$("#livePlayers tbody");
    var rows = $table.children();

    if (rows.length > Math.max(10, data.players.length))
      rows.slice(Math.max(data.players.length, 10)).remove();
    for (var i=rows.length; i<data.players.length; i++)
      $table.append("<tr><td></td><td style='overflow-x:hidden;white-space:nowrap'>&nbsp;</td><td></td></tr>");
    rows=$table.children();

    for (var i=0, c=data.players.length; i<c; i++) {
      var player = data.players[i];
      var cells = $(rows[i]).children();
      $(cells[0]).text(i<c ? ["Play", "Red", "Blue", "Spec" ][player.team] : "")
      if (i<c)
        $(cells[1]).html($("<a href='/player/" + player.steamid + "'></a>").append(htmlColors(player.name)));
      else
        $(cells[1]).html("&nbsp;");
      $(cells[2]).text(i<c ? player.rating : "").attr("title", "\xb1 " + player.rd).css("cursor", "help");
    }
    for (; i<10; i++) {
      var cells = $(rows[i]).children();
      $(cells[0]).html("");
      $(cells[1]).html("&nbsp;");
      $(cells[2]).html("");
    }

    $map = $("#mapname");
    $map.text(data.serverinfo.map);
    $map.attr("href", "/map/" + encodeURIComponent(data.serverinfo.map));
  });
}

// set fixed height to 10 rows so scrollbar appears if necessary
$("#livePlayersDiv").css("height", $("#topPlayersTable").height() + "px");

loadLivePlayers();
</script>
</%block>

% if server is None:
<h2>Sorry, that server wasn't found!</h2>

% else:
<div class="row">
  <div class="col-sm-12">
    <h2>${server.name}</h2>
    <p style="display:inline-block">
      IP Address: 
      % if server.port is not None:
      ${server.ip_addr}:${server.port}
      % else:
      ${server.ip_addr}
      % endif      
      <br />Added <span class="abstime" data-epoch="${server.epoch()}" title="${server.create_dt.strftime('%a, %d %b %Y %H:%M:%S UTC')}">${server.fuzzy_date()}</span>
      <br />Location: 
            % if server.country is not None:
            <img src="/static/images/flags/${(server.country or "").lower()}.png" width="16" height="16" class="flag"> ${server.location}
            % else:
              unknown
            % endif
    </p>
    <p style="display:inline-block;vertical-align:top;margin-left:30px">
      Map: <a id="mapname" href=""></a>
      <br /><a class="btn btn-primary btn-small" style="vertical-align:top; margin-top: 10px" href="steam://connect/${server.ip_addr}:${server.port}" title="Connect to game server">Join Server</a>
    </p>
  </div>
</div>


<div class="row">

  <div class="col-sm-4">
    <h3>Now Playing <span style="color:red;font-size:large">&#x25cf;</span></h3>
    <div id="livePlayersDiv" style="overflow-y:auto">
      <table class="table table-hover table-condensed" id="livePlayers" style="table-layout:fixed;margin-bottom:0">
        <thead>
          <tr>
            <th style="width:50px;">Team</th>
            <th>Nick</th>
            <th style="width:55px;">Glicko</th>
          </tr>
        </thead>
        <tbody>
          % for i in range(0, 10):
          <tr>
            <td></td>
            <td style="overflow-x:hidden;white-space:nowrap">&nbsp;</td>
            <td></td>
          </tr>
          % endfor
        </tbody>
      </table>
    </div>
  </div> <!-- /span4 -->

  <div class="col-sm-4">
    <h3>Most Active Players</h3>
    <table class="table table-hover table-condensed">
      <thead>
        <tr>
          <th style="width:40px;">#</th>
          <th>Nick</th>
          <th style="width:90px;">Play Time</th>
        </tr>
      </thead>
      <tbody>
        <% i = 1 %>
        % for (player_id, nick, alivetime) in top_players:
        <tr>
          <td>${i}</td>
          % if player_id != '-':
          <td><a href="${request.route_url('player_info', id=player_id)}" title="Go to the player info page for this player">${nick|n}</a></td>
          % else:
          <td>${nick}</td>
          % endif
          <td>${None if not type(alivetime) is datetime.timedelta else round(alivetime.total_seconds()/3600,1)}h</td>
        </tr>
        <% i = i+1 %>
        % endfor
      </tbody>
    </table>
  </div> <!-- /span4 -->

  <div class="col-sm-4">
    <h3>Most Active Maps</h3>
    <table class="table table-hover table-condensed">
      <thead>
        <tr>
          <th style="width:40px;">#</th>
          <th>Map</th>
          <th style="width:120px;"># Games</th>
        </tr>
      </thead>
      <tbody>
        <% i = 1 %>
        % for (map_id, name, count) in top_maps:
        <tr>
          <td>${i}</td>
          % if map_id != '-':
          <td><a href="${request.route_url('map_info', id=map_id)}" title="Go to the map info page for ${name}">${name}</a></td>
          % else:
          <td>${name}</td>
          % endif
          <td>${count}</td>
        </tr>
        <% i = i+1 %>
        % endfor
      </tbody>
    </table>
  </div> <!-- /span4 -->

</div>

<div class="row">
  <div class="col-sm-12">
    <p class="note">*Most active stats are from the past 7 days</p>
  </div>
</div>


% if len(recent_games) > 0:
<div class="row">
  <div class="col-sm-12">
    <h3>
      Most Recent Games</h2>
      <table class="table table-hover table-condensed">
        <thead>
          <tr>
            <th></th>
            <th>Type</th>
            <th>Map</th>
            <th>Time</th>
            <th>Winner</th>
            <th>Score</td>
          </tr>
        </thead>
        <tbody>
          % for rg in recent_games:
          <tr>
            <td class="tdcenter"><a class="btn btn-primary btn-small" href="${request.route_url('game_info', id=rg.game_id)}" title="View detailed information about this game">View</a></td>
            <td><img src="/static/images/icons/24x24/${rg.game_type_cd}.png" width="24" height="24" alt="${rg.game_type_cd}" title="${rg.game_type_descr}"> ${rg.game_type_cd}</td>
            <td><a href="${request.route_url('map_info', id=rg.map_id)}" title="Go to the map detail page for this map">${rg.map_name}</a></td>
            <td><span class="abstime" data-epoch="${rg.epoch}" title="${rg.start_dt.strftime('%a, %d %b %Y %H:%M:%S UTC')}">${rg.fuzzy_date}</span></td>
            <td class="nostretch">
              % if rg.player_id > 2:
              <a href="${request.route_url('player_info', id=rg.player_id)}" title="Go to the player info page for this player">${rg.nick_html_colors|n}</a>
              % else:
              ${rg.nick_html_colors|n}
              % endif
            </td>
            <td>
              % if rg.score1 is not None:
              ${rg.score1}:${rg.score2}
              % endif
            </td>
          </tr>
          % endfor
        </tbody>
      </table>
      <p><a href="${request.route_url('game_index', _query={'server_id':server.server_id})}">More...</a></p>
  </div>
</div>
% endif


% endif

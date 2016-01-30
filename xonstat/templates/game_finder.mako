<%inherit file="base.mako"/>
<%namespace name="nav" file="nav.mako" />
<%namespace file="navlinks.mako" import="navlinks" />

<%block name="navigation">
${nav.nav('games')}
</%block>

<%block name="css">
    ${parent.css()}
</%block>

<%block name="title">
Game Index
</%block>

##### ROW OF GAME TYPE ICONS #####
<div class="row">
  <div class="col-sm-12 tabbable">
    <ul class="nav nav-tabs">
      % for gt, url in game_type_links:
      <li
        % if game_type_cd == gt or (game_type_cd is None and gt == 'overall'):
        class="active"
        % endif
      >
        <a href="${url}" alt="${gt}" title="Show only ${gt} games" data-toggle="none">
          <img src="/static/images/icons/24x24/${gt}.png" width="24" height="24"><br />
          ${gt} <br />
        </a>
      </li>
      % endfor
    </ul>
    <br />
  </div>
</div>

##### RECENT GAMES TABLE #####
<div class="row">
  <div class="col-sm-12">
    % if len(recent_games) > 0:
    <table class="table table-hover table-condensed">
      <thead>
        <tr>
          <th></th>
          <th>Type</th>
          <th>Loc</th>
          <th>Server</th>
          <th>Map</th>
          <th>Time</th>
          <th>Winner</th>
          <th>Score</th>
          <th>Rated</th>
        </tr>
      </thead>
      <tbody>
      % for rg in recent_games:
        <tr>
          <td class="tdcenter"><a class="btn btn-primary btn-small" href="${request.route_url('game_info', id=rg.game_id)}" title="View detailed information about this game">view</a></td>
          <td><img src="/static/images/icons/24x24/${rg.game_type_cd}.png" width="24" height="24" alt = "${rg.game_type_cd}" title="${rg.game_type_descr}"> ${rg.game_type_cd}</td>
          <td>
            % if rg.country is not None:
            <img src="/static/images/flags/${rg.country.lower()}.png" width="24" height="24" class="flag"> ${rg.country}
            % endif
          </td>
          <td><a href="${request.route_url('server_info', id=rg.server_id)}" title="Go to the detail page for this server">${rg.server_name}</a></td>
          <td><a href="${request.route_url('map_info', id=rg.map_id)}" title="Go to the map detail page for this map">${rg.map_name}</a></td>
          <td><span class="abstime" data-epoch="${rg.epoch}">${rg.start_dt.strftime('%Y-%m-%d   %H:%M:%S')}</span></td>
          <td>
            % if rg.player_id > 2:
            <a href="${request.route_url('player_info', id=rg.player_id)}" title="Go to the player info page for this player">${rg.nick_html_colors|n}</a></td>
            % else:
            ${rg.nick_html_colors|n}</td>
            % endif
          <td>
            % if rg.score1 is not None:
            ${rg.score1 if rg.score1 is not None else "DNF"}:${rg.score2 if rg.score2 is not None else "DNF"}
            % endif
          </td>
          <td class="tdcenter">
            %if rg.g2_status == 0:
            TBD
            %elif rg.g2_status == 1:
            A
            %elif rg.g2_status == 8:
            B
            %else:
            <i class="glyphicon glyphicon-minus"></i>
            %endif
          </td>
        </tr>
        % endfor
        </tbody>
    </table>
    % else:
    <h2>No more games to show!</h2>
    % endif
  </div> <!-- /span12 -->
</div> <!-- /row -->

% if len(recent_games) == 20:
<div class="row">
  <div class="col-sm-12 text-center">
    <ul class="pagination">
      <li>
        <a  href="${request.route_url('game_index', _query=query)}" name="Next Page">Next <i class="glyphicon glyphicon-arrow-right"></i></a>
      </li>
    </ul>
  </div>
</div>
% endif

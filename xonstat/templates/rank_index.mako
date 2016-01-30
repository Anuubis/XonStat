<%inherit file="base.mako"/>
<%namespace name="nav" file="nav.mako" />
<%namespace file="navlinks.mako" import="navlinks" />
<%namespace file="filter.mako" import="*" />

<%block name="navigation">
${nav.nav("leaderboard")}
${filter_bar(show_all=False, game_types=["ca", "ctf", "duel", "ffa", "ft", "tdm" ])}
</%block>

<%block name="title">
% if game_type_cd == 'ffa':
Free For All Rank Index
% elif game_type_cd == 'duel':
Duel Rank Index
% elif game_type_cd == 'ca':
Clan Arena Rank Index
% elif game_type_cd == 'tdm':
Team Deathmatch Rank Index
% elif game_type_cd == 'ctf':
Capture The Flag Rank Index
% endif
</%block>

<%block name="js">
${parent.js()}
${filter_js()}

<script>
  $("#filterBar li").click(function() {
    window.location = "/ranks/" + (getCookie("gametype") || "duel") + "/" + (parseInt(getCookie("region")) || "1");
  });
</script>
</%block>

<div class="row">
  <div class="col-sm-8 col-sm-offset-2 col-lg-6 col-lg-offset-3">
    % if not region:
      &nbsp;
    % elif not ranks:
    <h2>Sorry, no ranks yet</h2>
    
    % else:

    <table id="rank-index-table" class="table table-hover table-condensed">
      <thead>
        <tr>
          <th style="width:40px;">Rank</th>
          <th style="width:420px;">Nick</th>
          <th style="width:170px;" title="estimated rating &plusmn; uncertainty">Glicko</th>
          <th style="width:90px;" title="Number games included in the rating">Games</th>
        </tr>
      </thead>
      <tbody>
        <% i = 1 %>
        % for rank in ranks:
        <tr>
          <td>${rank.rank}</td>
          <td class="nostretch" style="max-width:420px;"><a href="${request.route_url("player_info", id=rank.player_id)}" title="Go to this player's info page">${rank.nick_html_colors()|n}</a></td>
          <td>${int(round(rank.g2_r))} &plusmn; ${int(round(rank.g2_rd))}</td>
          <td>${rank.g2_games}</td>
        </tr>
        <% i += 1 %>
        % endfor
      </tbody>
    </table>
  </div> <!-- /span6 -->
</div> <!-- /row -->

<!-- navigation links -->
${navlinks("rank_index", ranks.page, ranks.last_page, game_type_cd=game_type_cd, region=region)}
% endif

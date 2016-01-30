<%def name="filter_bar(show_all=True, game_types=None)">
<%
import xonstat.views.helpers
if not game_types:
  game_types = xonstat.views.helpers.games_q()
%>

<div id="filterBar">
  <ul id="region">
    <li data-region="0" ${"" if show_all else "style='display:none'"|n}>All</li>
    <li data-region="1">EU</li>
    <li data-region="5">NA</li>
    <li data-region="6">SA</li>
    <li data-region="4">AU</li>
    <li data-region="3">AS</li>
    <li data-region="2">AF</li>
  </ul>
  <ul id="gametype">
    <li data-gametype="overall" ${"" if show_all else "style='display:none'"|n}>All</li>
    %for gt in game_types:
    <li data-gametype="${gt}"><!--<img src="/static/images/icons/24x24/${gt}.png" alt=""> -->${gt.upper() if not ("e" in gt) else gt[0].upper() + gt[1:]}</li>
    %endfor
  </ul>
</div>
</%def>

<%def name="filter_js()">
<script type="text/javascript">
// filter nav bar
$("#filterBar li[data-region='" + (getCookie("region") || "0") + "']").addClass("selected");
$("#filterBar li[data-gametype='" + (getCookie("gametype") || "overall") + "']").addClass("selected");
$("#filterBar #region li").click(function() {
  $("#filterBar #region li").removeClass("selected");
  $(this).addClass("selected");
  var region = $(this).data("region");
  if (region == "0") region = "";
  setCookie("region", region);
})
$("#filterBar #gametype li").click(function() {
  $("#filterBar #gametype li").removeClass("selected");
  $(this).addClass("selected");
  var gt = $(this).data("gametype");
  if (gt == "overall") gt = "";
  setCookie("gametype", gt);
})
</script>
</%def>

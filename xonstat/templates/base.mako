<%namespace name="nav" file="nav.mako"/>

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>QLStats: Player Statistics for Quake Live</title>
    <meta name="description" content="">
    <meta name="author" content="">

    <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
    <link href='https://fonts.googleapis.com/css?family=Open+Sans&subset=latin,greek,cyrillic-ext,latin-ext,cyrillic' rel='stylesheet' type='text/css'>
    <link rel="shortcut icon" href="/static/favicon.ico?v=2">

    <%block name="css">
    <!--<link href="/static/css/bootstrap.min.css" rel="stylesheet">-->
    <link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">

    <link href="/static/css/app.min.css" rel="stylesheet">
    </%block>

    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
      ga('create', 'UA-71098578-1', 'auto');
      ga('send', 'pageview');

      function setCookie(name, value) {
        if (value === null || value === undefined)
          value = "";
        document.cookie = name + "=" + value + "; expires=Tue, 1 Jan 2030 12:00:00 UTC; path=/";
      }
      function getCookie(name) {
        var match = document.cookie.match(new RegExp(name + "=([^;]*)"));
        return match ? match[1] : null;
      }
      if (!document.cookie.match(/region=\d/))
        setCookie("region", "0");
      if (!document.cookie.match(/gametype=[a-z]*/))
        setCookie("gametype", "");
      if (!document.cookie.match(/weapons=[a-z]*/))
        setCookie("weapons", "mg,lg,rg,hmg");
    </script>
  </head>

  <body>
    <%block name="navigation">
    ${nav.nav("leaderboard")}
    </%block>

    <div class="container-fluid" style="margin-left:15px;margin-right:15px;">
      <%block name="hero_unit">
      </%block>

      <div class="row">
        <div class="col-sm-12" id="xonborder">
          <div id="title"><%block name="title"></%block></div>
          ${self.body()}
        </div>
      </div>

      <%block name="footer">
      <div class="row shadowtext" id="pageFooter">
        <div class="col-sm-10 col-sm-offset-1">
          <p class="text-center">
            QLStats was created by PredatH0r as a Quake Live modification of <a href="http://stats.xonotic.org" target="_blank">XonStat</a>,
            the <a href="http://www.xonotic.org" target="_blank">Xonotic</a> stats tracking system created by Antibody.

            <br>Both are licensed under GPLv2 and available on Github: <a href="https://github.com/PredatH0r/xonstat" title="Go to the project page" target="_blank">QLStats</a>,
            <a href="https://github.com/antzucaro/XonStat" title="Go to the project page" target="_blank">XonStat</a>
            <br>Geo-IP information provided by <a href="http://www.freegeoip.net">freegeoip.net</a> | Flag images provided by <a href="http://www.icondrawer.com/flag-icons.php">icondrawer.com</a>
          </p>
        </div>
      </div>
      </%block>

    </div>

    <%block name="js">
    <script type='text/javascript' src='//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js'></script>
    <!--<script type='text/javascript' src='/static/js/bootstrap.min.js'></script>-->
    <script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
    <script>
      var entityMap = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': '&quot;', "'": '&#39;', "/": '&#x2F;' };
      function escapeHtml(string) { return String(string).replace(/[&<>"'\/]/g, function (s) { return entityMap[s]; }); }
      function htmlColors(text) {
        text = escapeHtml(text);
        return "<span class='ql7'>" + text.replace(/\^[0-7]/g, function(match) { return "</span><span class='ql" + match[1] + "'>"; }) + "</span>";
      }

    </script>
    </%block>

    <script type="text/javascript">
      // RELATIVE TIME CONVERSION
      $('.abstime').each(function(i,e){
        var $e = $(e);
        var epoch = $e.attr('data-epoch');
        var d = new Date(0);
        d.setUTCSeconds(epoch);
        var dt = d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).toString().substr(-2) + "-" + ("0" + d.getDate()).substr(-2);
        var tm = ("0" + d.getHours()).toString().substr(-2) + ":" + ("0" + d.getMinutes()).toString().substr(-2) + ":" + ("0" + d.getSeconds()).toString().substr(-2);
        $e.attr("title", $e.text());
        $e.text(dt + "   " + tm);
      });
    </script>

  </body>
</html>

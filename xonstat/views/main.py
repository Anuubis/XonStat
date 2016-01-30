import logging
import sqlalchemy as sa
import sqlalchemy.sql.functions as func
import sqlalchemy.sql.expression as expr
from beaker.cache import cache_regions, cache_region
from collections import namedtuple
from datetime import datetime, timedelta
from pyramid.response import Response
from xonstat.models import *
from xonstat.util import *
from xonstat.views.helpers import RecentGame, recent_games_q
from webhelpers.paginate import Page


log = logging.getLogger(__name__)


# these slow running queries are no longer used in qlstats
@cache_region('hourly_term')
def get_summary_stats(cutoff_days=None):
    """
    Gets the following aggregate statistics about the past cutoff_days days:
        - the number of active players
        - the number of games per game type
    If cutoff_days is None, the above stats are calculated for all time.

    This information is then summarized into a string which is passed
    directly to the template.
    """
    return ""
    try:
        if cutoff_days is not None:
            # only games played during this range are considered
            right_now = datetime.now()
            cutoff_dt = right_now - timedelta(days=cutoff_days)

            games = DBSession.query(Game.game_type_cd, func.count()).\
                filter(expr.between(Game.create_dt, cutoff_dt, right_now)).\
                group_by(Game.game_type_cd).\
                order_by(expr.desc(func.count())).all()

            active_players = DBSession.query(func.count(sa.distinct(PlayerGameStat.player_id))).\
                filter(PlayerGameStat.player_id > 2).\
                filter(expr.between(PlayerGameStat.create_dt, cutoff_dt, right_now)).\
                one()[0]
        else:
            games = DBSession.query(Game.game_type_cd, func.count()).\
                group_by(Game.game_type_cd).\
                order_by(expr.desc(func.count())).all()

            active_players = DBSession.query(func.count(sa.distinct(PlayerGameStat.player_id))).\
                filter(PlayerGameStat.player_id > 2).\
                one()[0]

        total_games = 0
        for total in games:
            total_games += total[1]

        i = 1
        other_games = 0
        for total in games:
            if i > 5:
                other_games += total[1]
            i += 1

        # don't send anything if we don't have any activity
        if total_games == 0:
            stat_line = None
        else:
        # This is ugly because we're doing template-like stuff within the
        # view code. The alternative isn't any better, though: we would
        # have to assemble the string inside the template by using a Python
        # code block. For now I'll leave it like this since it is the lesser
        # of two evils IMO.
        # Also we need to hard-code the URL structure in here to allow caching,
        # which also sucks.
            in_paren = "; ".join(["{:2,d} {}".format(
                g[1],
                "<a href='/games?type={0}'>{0}</a>".format(g[0])
            ) for g in games[:5]])

            if len(games) > 5:
                in_paren += "; {:2,d} other".format(other_games)

            stat_line = "{:2,d} active players and {:2,d} games ({})".format(
                active_players,
                total_games,
                in_paren
            )

    except Exception as e:
        stat_line = None

    return stat_line


def top_players_by_time_q(cutoff_days):
    """
    Query for the top players by the amount of time played during a date range.

    Games older than cutoff_days days old are ignored.
    """

    # only games played during this range are considered
    right_now = datetime.utcnow()
    cutoff_dt = right_now - timedelta(days=cutoff_days)

    top_players_q = DBSession.query(Player.player_id, Player.nick,
            func.sum(PlayerGameStat.alivetime)).\
            filter(Player.player_id == PlayerGameStat.player_id).\
            filter(Player.player_id > 2).\
            filter(expr.between(PlayerGameStat.create_dt, cutoff_dt, right_now)).\
            order_by(expr.desc(func.sum(PlayerGameStat.alivetime))).\
            group_by(Player.nick).\
            group_by(Player.player_id)

    return top_players_q


@cache_region('hourly_term')
def get_top_players_by_time(cutoff_days):
    """
    The top players by the amount of time played during a date range.

    Games older than cutoff_days days old are ignored.
    """
    # how many to retrieve
    count = 10

    # only games played during this range are considered
    right_now = datetime.utcnow()
    cutoff_dt = right_now - timedelta(days=cutoff_days)

    top_players_q = top_players_by_time_q(cutoff_days)

    top_players = top_players_q.limit(count).all()

    top_players = [(player_id, html_colors(nick), score) \
            for (player_id, nick, score) in top_players]

    return top_players


def top_servers_by_players_q(cutoff_days, region = None, game_type_cd = None):
    """
    Query to get the top servers by the amount of players active
    during a date range.

    Games older than cutoff_days days old are ignored.
    """
    # only games played during this range are considered
    right_now = datetime.utcnow()
    cutoff_dt = right_now - timedelta(days=cutoff_days)

    top_servers_q = DBSession.query(Server.server_id, Server.name,
        func.count(), Server.country, Server.location).\
        filter(Game.server_id==Server.server_id).\
        filter(expr.between(Game.create_dt, cutoff_dt, right_now)).\
        order_by(expr.desc(func.count(Game.game_id))).\
        group_by(Server.server_id).\
        group_by(Server.name)
    if region and region != "" and region != "0":
      top_servers_q = top_servers_q.filter(Server.region == region)
    if game_type_cd and game_type_cd != "":
      top_servers_q = top_servers_q.filter(Game.game_type_cd == game_type_cd)
    return top_servers_q


@cache_region('hourly_term')
def get_top_servers_by_players(cutoff_days, region = None, game_type_cd = None):
    """
    The top servers by the amount of players active during a date range.

    Games older than cutoff_days days old are ignored.
    """
    # how many to retrieve
    count = 10
    top_servers = top_servers_by_players_q(cutoff_days, region, game_type_cd).limit(count).all()
    return top_servers


def top_maps_by_times_played_q(cutoff_days, region = None, game_type_cd = None):
    """
    Query to retrieve the top maps by the amount of times it was played
    during a date range.

    Games older than cutoff_days days old are ignored.
    """
    # only games played during this range are considered
    right_now = datetime.utcnow()
    cutoff_dt = right_now - timedelta(days=cutoff_days)

    top_maps_q = DBSession.query(Game.map_id, Map.name,
            func.count()).\
            filter(Map.map_id==Game.map_id).\
            filter(expr.between(Game.create_dt, cutoff_dt, right_now)).\
            order_by(expr.desc(func.count())).\
            group_by(Game.map_id).\
            group_by(Map.name)

    if region and region != "" and region != "0":
      top_maps_q = top_maps_q.filter(Server.region==region).filter(Server.server_id==Game.server_id)
    if game_type_cd and game_type_cd != "":
      top_maps_q = top_maps_q.filter(Game.game_type_cd == game_type_cd)    

    return top_maps_q


@cache_region('hourly_term')
def get_top_maps_by_times_played(cutoff_days, region = None, game_type_cd = None):
    """
    The top maps by the amount of times it was played during a date range.

    Games older than cutoff_days days old are ignored.
    """
    count = 10
    top_maps = top_maps_by_times_played_q(cutoff_days, region, game_type_cd).limit(count).all()
    return top_maps

@cache_region('seconds_term')
def get_recent_games(limit):
    return recent_games_q().limit(limit).all()




def main_index(request):
    # recent games played in descending order
    recent_games = [RecentGame(row) for row in get_recent_games(20)]
    return {'recent_games':recent_games}


def recent_games_json(request):
    recent_games = [RecentGame(row) for row in get_recent_games(20)]
    return {'recent_games':recent_games}
  

def top_players_by_time(request):
    return {'top_players': []}
    current_page = request.params.get('page', 1)
    cutoff_days = int(request.registry.settings.get('xonstat.leaderboard_lifetime', 30))
    top_players_q = top_players_by_time_q(cutoff_days)
    top_players = Page(top_players_q, current_page, items_per_page=25, url=page_url)
    top_players.items = [(player_id, html_colors(nick), score) for (player_id, nick, score) in top_players.items]
    return {'top_players':top_players}


def top_servers_json(request):
    region = request.params.get("region") or request.cookies.get("region")
    game_type_cd = request.params.get("gametype") or request.cookies.get("gametype")
    leaderboard_lifetime = int(request.registry.settings.get('xonstat.leaderboard_lifetime', 30))
    top_servers = get_top_servers_by_players(leaderboard_lifetime, region, game_type_cd)
    return { "region": region, "gametype": game_type_cd, "servers": top_servers }

def top_servers_by_players(request):
    current_page = request.params.get('page', 1)
    cutoff_days = int(request.registry.settings.get('xonstat.leaderboard_lifetime', 30))
    region = request.params.get("region") or request.cookies.get("region")
    game_type_cd = request.params.get("gametype") or request.cookies.get("gametype")
    top_servers_q = top_servers_by_players_q(cutoff_days, region, game_type_cd)
    top_servers = Page(top_servers_q, current_page, items_per_page=25, url=page_url)
    return {'top_servers':top_servers}


def top_maps_json(request):
    region = request.params.get("region") or request.cookies.get("region")
    game_type_cd = request.params.get("gametype") or request.cookies.get("gametype")
    leaderboard_lifetime = int(request.registry.settings.get('xonstat.leaderboard_lifetime', 30))
    return { "region": region, "gametype": game_type_cd, "maps": [] }
    top_maps = get_top_maps_by_times_played(leaderboard_lifetime, region, game_type_cd)
    return { "region": region, "gametype": game_type_cd, "maps": top_maps }

def top_maps_by_times_played(request):
    current_page = request.params.get('page', 1)
    cutoff_days = int(request.registry.settings.get('xonstat.leaderboard_lifetime', 30))
    region = request.params.get("region") or request.cookies.get("region")
    game_type_cd = request.params.get("gametype") or request.cookies.get("gametype")
    return { "region": region, "gametype": game_type_cd, 'top_maps':[]}
    top_maps_q = top_maps_by_times_played_q(cutoff_days, region, game_type_cd)
    top_maps = Page(top_maps_q, current_page, items_per_page=25, url=page_url)
    return { "region": region, "gametype": game_type_cd, 'top_maps':top_maps}

def news_index(request):
    return {}
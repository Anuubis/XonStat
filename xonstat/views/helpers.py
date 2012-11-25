import logging
import sqlalchemy.sql.expression as expr
from datetime import datetime
from xonstat.models import *
from xonstat.util import *

log = logging.getLogger(__name__)

class RecentGame(object):
    '''
    This is a helper class to facilitate showing recent games
    data within mako. The idea is to take the results of a query
    and transform it into class members easily accessible later.
    It is like a namedtuple but a little easier to form.

    The constructor takes a query row that has been fetched, and
    it requires the following columns to be present in the row:

        game_id, game_type_cd, winner, create_dt, server_id, server_name,
        map_id, map_name, player_id, nick, rank, team

    The following columns are optional:

        elo_delta

    This class is meant to be used in conjunction with recent_games_q,
    which will return rows matching this specification.
    '''
    def __init__(self, row):
        self.game_id = row.game_id
        self.game_type_cd = row.game_type_cd
        self.winner = row.winner
        self.create_dt = row.create_dt
        self.fuzzy_date = pretty_date(row.create_dt)
        self.epoch = timegm(row.create_dt.timetuple())
        self.server_id = row.server_id
        self.server_name = row.server_name
        self.map_id = row.map_id
        self.map_name = row.map_name
        self.player_id = row.player_id
        self.nick = row.nick
        self.nick_html_colors = html_colors(row.nick)
        self.rank = row.rank
        self.team = row.team

        try:
            self.elo_delta = row.elo_delta
        except:
            self.elo_delta = None


def recent_games_q(server_id=None, map_id=None, player_id=None, cutoff=None):
    '''
    Returns a SQLA query of recent game data. Parameters filter
    the results returned if they are provided. If not, it is
    assumed that results from all servers and maps is desired.

    The cutoff parameter provides a way to limit how far back to
    look when querying. Only games that happened on or after the
    cutoff (which is a datetime object) will be returned.
    '''
    recent_games_q = DBSession.query(Game.game_id, Game.game_type_cd,
            Game.winner, Game.create_dt, Server.server_id,
            Server.name.label('server_name'), Map.map_id,
            Map.name.label('map_name'), PlayerGameStat.player_id,
            PlayerGameStat.nick, PlayerGameStat.rank, PlayerGameStat.team,
            PlayerGameStat.elo_delta).\
            filter(Game.server_id==Server.server_id).\
            filter(Game.map_id==Map.map_id).\
            filter(Game.game_id==PlayerGameStat.game_id).\
            order_by(expr.desc(Game.create_dt))

    # the various filters provided get tacked on to the query
    if server_id is not None:
        recent_games_q = recent_games_q.\
            filter(Server.server_id==server_id)

    if map_id is not None:
        recent_games_q = recent_games_q.\
            filter(Map.map_id==map_id)

    if player_id is not None:
        recent_games_q = recent_games_q.\
            filter(PlayerGameStat.player_id==player_id)
    else:
        recent_games_q = recent_games_q.\
            filter(PlayerGameStat.rank==1)

    if cutoff is not None:
        right_now = datetime.utcnow()
        recent_games_q = recent_games_q.\
            filter(expr.between(Game.create_dt, cutoff, right_now))

    return recent_games_q
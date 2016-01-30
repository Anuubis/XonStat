import logging
import sqlalchemy.sql.expression as expr
from datetime import datetime
from sqlalchemy.orm import aliased
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

        game_id, game_type_cd, game_type_descr, winner, start_dt,
        server_id, server_name, map_id, map_name, player_id, nick,
        rank, team

    The following columns are optional:

        elo_delta

    This class is meant to be used in conjunction with recent_games_q,
    which will return rows matching this specification.
    '''
    def __init__(self, row):
        self.game_id = row.game_id
        self.game_type_cd = row.game_type_cd
        self.game_type_descr = row.game_type_descr
        self.winner = row.winner
        self.start_dt = row.start_dt
        self.fuzzy_date = pretty_date(row.start_dt)
        self.epoch = timegm(row.start_dt.timetuple())
        self.server_id = row.server_id
        self.server_name = row.server_name
        self.map_id = row.map_id
        self.map_name = row.map_name
        self.player_id = row.player_id
        self.nick = row.nick
        self.nick_html_colors = html_colors(row.nick)
        self.rank = row.rank
        self.team = row.team
        self.g2_status = row.g2_status
        self.g2_old_r = row.g2_old_r
        self.g2_old_rd = row.g2_old_rd

        try:
            self.elo_delta = row.elo_delta
        except:
            self.elo_delta = None

        try:
            self.g2_delta_r = row.g2_delta_r
            self.g2_delta_rd = row.g2_delta_rd
        except:
            self.g2_delta_r = None
            self.g2_delta_rd = None

        try:
            self.score1 = row.score1
            self.score2 = row.score2
        except:
            self.score1 = None
            self.score2 = None

        try:
            self.country = row.country;
            self.location = row.location;
        except:
            self.country = None
            self.location = None

    def __json__(self, request):
        return self._asdict()

    def _asdict(self):
        return {
            "game_id": self.game_id,
            "game_type_cd": self.game_type_cd,
            "game_type_descr": self.game_type_descr,
            "winner": self.winner,
            "start_dt": self.start_dt,
            "fuzzy_dt": self.fuzzy_date,
            "epoch": self.epoch,
            "server_id": self.server_id,
            "server_name": self.server_name,
            "map_id": self.map_id,
            "map_name": self.map_name,
            "player_id": self.player_id,
            "nick": self.nick,
            "nick_html_colors": self.nick_html_colors,
            "rank": self.rank,
            "team": self.team,
            "g2_delta_r": int(round(self.g2_delta_r,0)) if self.g2_delta_r else None,
            "g2_delta_rd": int(round(self.g2_delta_rd, 0)) if self.g2_delta_rd else None,
            "g2_status": self.g2_status,
            "g2_old_r":int(round(self.g2_old_r, 0)) if self.g2_old_r else None,
            "g2_old_rd":int(round(self.g2_old_rd, 0)) if self.g2_old_rd else None
            }

    def __repr__(self):
        return "<RecentGame(id=%s, gametype=%s, server=%s, map=%s)>" % (self.game_id, self.game_type_cd, self.server_name, self.map_name)

def games_q():
    result = DBSession.query(GameType.game_type_cd).\
            filter(GameType.active_ind==True).\
          order_by(expr.asc(GameType.game_type_cd)).\
      all();
    return [row[0] for row in result];

def recent_games_q(server_id=None, map_id=None, player_id=None,
        game_type_cd=None, cutoff=None, force_player_id=False,
        start_game_id=None, end_game_id=None):
    '''
    Returns a SQLA query of recent game data. Parameters filter
    the results returned if they are provided. If not, it is
    assumed that results from all servers and maps is desired.

    The cutoff parameter provides a way to limit how far back to
    look when querying. Only games that happened on or after the
    cutoff (which is a datetime object) will be returned.
    '''
    pgstat_alias = aliased(PlayerGameStat, name='pgstat_alias')

    recent_games_q = DBSession.query(Game.game_id, GameType.game_type_cd,
            Game.winner, Game.start_dt, GameType.descr.label('game_type_descr'),
            Game.score1, Game.score2, Game.g2_status,
            Server.server_id, Server.name.label('server_name'), Server.country, Server.location,
            Map.map_id, Map.name.label('map_name'), 
            PlayerGameStat.player_id, PlayerGameStat.nick, PlayerGameStat.rank, PlayerGameStat.team,           
            PlayerGameStat.g2_old_r, PlayerGameStat.g2_old_rd, PlayerGameStat.g2_delta_r, PlayerGameStat.g2_delta_rd).\
            filter(Game.server_id==Server.server_id).\
            filter(Game.map_id==Map.map_id).\
            filter(Game.game_id==PlayerGameStat.game_id).\
            filter(Game.game_type_cd==GameType.game_type_cd).\
            order_by(expr.desc(Game.create_dt))

    # the various filters provided get tacked on to the query
    if server_id is not None:
        recent_games_q = recent_games_q.\
            filter(Server.server_id==server_id)

    if map_id is not None:
        recent_games_q = recent_games_q.\
            filter(Map.map_id==map_id)

    # Note: force_player_id makes the pgstat row returned be from the
    # specified player_id. Otherwise it will just look for a game
    # *having* that player_id, but returning the #1 player's pgstat row
    if player_id is not None:
        if force_player_id:
            recent_games_q = recent_games_q.\
                filter(PlayerGameStat.player_id==player_id).\
                filter(Game.players.contains([player_id]))
        else:
            recent_games_q = recent_games_q.\
                filter(PlayerGameStat.scoreboardpos==1).\
                filter(Game.game_id==pgstat_alias.game_id).\
                filter(Game.players.contains([player_id])).\
                filter(pgstat_alias.player_id==player_id)
    else:
        recent_games_q = recent_games_q.\
            filter(PlayerGameStat.scoreboardpos==1)

    if game_type_cd is not None:
        recent_games_q = recent_games_q.\
            filter(Game.game_type_cd==game_type_cd.lower())

    if cutoff is not None:
        right_now = datetime.utcnow()
        recent_games_q = recent_games_q.\
            filter(expr.between(Game.create_dt, cutoff, right_now)).\
            filter(expr.between(PlayerGameState.create_dt, cutoff, right_now))

    if start_game_id is not None:
        recent_games_q = recent_games_q.filter(Game.game_id <= start_game_id)

    if end_game_id is not None:
        recent_games_q = recent_games_q.filter(Game.game_id >= end_game_id)

    return recent_games_q

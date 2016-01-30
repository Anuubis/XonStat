begin;
    -- save the history
    insert into player_ranks_history
    select * from player_ranks;

    -- get rid of the existing ranks and refresh them using
    -- the latest elo information for each game type
    delete from player_ranks;

    insert into player_ranks(player_id, nick, region, game_type_cd, elo, g2_r, g2_rd, g2_games, rank)
    select p.player_id, p.nick, p.region, pe.game_type_cd, elo, g2_r, g2_rd, g2_games, rank() 
    over (partition by p.region, pe.game_type_cd order by pe.g2_r desc)
    from players p, player_elos pe
    where p.player_id = pe.player_id
    and p.active_ind = True
    and pe.active_ind = True
    and pe.g2_games >= 10;
end;

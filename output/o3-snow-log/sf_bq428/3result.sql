/* 1)  Identify every (player, game, team_market) combo in 2010-2018 seasons
       where the player scored ≥15 points in period 2.                       */
WITH p2_thr AS (  
    SELECT
        "team_market",
        "player_id"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "season" BETWEEN 2010 AND 2018
      AND "period" = 2
      AND "shot_made" = TRUE
    GROUP BY "team_market", "player_id", "game_id"
    HAVING SUM("points_scored") >= 15
),

/* 2)  Count how many distinct players reached that mark for each market
       and keep the top-5 markets.                                          */
top_markets AS (      
    SELECT
        "team_market",
        COUNT(DISTINCT "player_id") AS "num_distinct_players"
    FROM p2_thr
    GROUP BY "team_market"
    ORDER BY "num_distinct_players" DESC NULLS LAST
    LIMIT 5
)

/* 3)  Return full NCAA-tournament game details (2010-2018 seasons) for
       those five markets, tagging whether the market’s team won or lost.   */
SELECT
    ht."season",
    ht."round",
    ht."game_date",
    
    /* which of the two sides is the target market in this row? */
    CASE 
        WHEN ht."win_market" IN (SELECT "team_market" FROM top_markets) 
             THEN ht."win_market"
        ELSE ht."lose_market"
    END                                            AS "team_market",
    
    CASE 
        WHEN ht."win_market" IN (SELECT "team_market" FROM top_markets) 
             THEN ht."win_name"
        ELSE ht."lose_name"
    END                                            AS "team_name",
    
    /* win / loss from the perspective of the target market */
    CASE 
        WHEN ht."win_market" IN (SELECT "team_market" FROM top_markets) 
             THEN 'win'
        ELSE 'loss'
    END                                            AS "result",
    
    /* full game details from historical-tournament table */
    ht."win_seed",
    ht."win_market",
    ht."win_name",
    ht."win_pts",
    ht."lose_seed",
    ht."lose_market",
    ht."lose_name",
    ht."lose_pts"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES ht
JOIN top_markets tm
  ON ht."win_market" = tm."team_market"
   OR ht."lose_market" = tm."team_market"
WHERE ht."season" BETWEEN 2010 AND 2018
ORDER BY "team_market", ht."season", ht."game_date";
/* 1)  Find every player who scored 15-plus points in the 2nd period of any game
      between the 2010 and 2018 seasons                                              */
WITH players_15p_p2 AS (
    SELECT
        "team_id",
        "player_id"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "season" BETWEEN 2010 AND 2018
      AND "period" = 2
      AND "points_scored" IS NOT NULL
    GROUP BY "team_id", "player_id"
    HAVING SUM("points_scored") >= 15
),

/* 2)  Count the number of DISTINCT such players for every team market
      and keep the TOP-5 markets                                                   */
top5_markets AS (
    SELECT
        t."market",
        COUNT(DISTINCT p."player_id")      AS "distinct_players"
    FROM players_15p_p2            p
    JOIN NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_TEAMS  t
           ON t."id" = p."team_id"
    GROUP BY t."market"
    ORDER BY "distinct_players" DESC NULLS LAST
    LIMIT 5
),

/* 3)  Pull every NCAA historical-tournament game (2010-2018) in which
      a TOP-5 market team participated                                            */
tournament_games AS (
    SELECT *
    FROM  NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" BETWEEN 2010 AND 2018
      AND (   "win_market"  IN (SELECT "market" FROM top5_markets)
           OR "lose_market" IN (SELECT "market" FROM top5_markets) )
)

/* 4)  Return the requested game details                                           */
SELECT
    "season",
    "round",
    "game_date",
    "day",
    "win_market",
    "win_name",
    "win_alias",
    "win_seed",
    "win_pts",
    "lose_market",
    "lose_name",
    "lose_alias",
    "lose_seed",
    "lose_pts",
    "num_ot"
FROM   tournament_games
ORDER  BY "season" DESC NULLS LAST,
          "game_date" DESC NULLS LAST,
          "win_market";
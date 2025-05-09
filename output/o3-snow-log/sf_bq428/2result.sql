/*  -----------------------------------------------------------
    1)  Identify every player who scored ≥15 points in the 2nd
        period of a game played between 2010-2018.
    2)  Count how many distinct such players each team market
        had and keep the TOP-5 markets.
    3)  Return every NCAA historical-tournament game (2010-2018)
        in which any of those TOP-5 markets participated,
        showing full winner / loser details.
    ----------------------------------------------------------- */
WITH player_p2 AS (     -- total 2nd-period points for every player-game
    SELECT
        "team_market",
        "player_id",
        SUM("points_scored") AS "p2_pts"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "season" BETWEEN 2010 AND 2018
      AND "period" = 2
      AND "points_scored" IS NOT NULL
    GROUP BY "team_market", "player_id"
),
qualified_players AS (  -- players who hit the 15-point threshold
    SELECT
        "team_market",
        "player_id"
    FROM player_p2
    WHERE "p2_pts" >= 15
),
top5_markets AS (       -- top-5 team markets by count of those players
    SELECT
        "team_market"
    FROM qualified_players
    GROUP BY "team_market"
    ORDER BY COUNT(DISTINCT "player_id") DESC
    LIMIT 5
)
SELECT
    h."season",
    h."round",
    h."game_date",
    h."win_market"  AS "winner_market",
    h."win_name"    AS "winner_name",
    h."win_seed"    AS "winner_seed",
    h."win_pts"     AS "winner_points",
    h."lose_market" AS "loser_market",
    h."lose_name"   AS "loser_name",
    h."lose_seed"   AS "loser_seed",
    h."lose_pts"    AS "loser_points"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES h
WHERE h."season" BETWEEN 2010 AND 2018
  AND (
        h."win_market"  IN (SELECT "team_market" FROM top5_markets)
     OR h."lose_market" IN (SELECT "team_market" FROM top5_markets)
      )
ORDER BY
    h."season",
    h."game_date";
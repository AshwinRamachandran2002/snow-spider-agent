/* ------------------------------------------------------------
   1) Identify each (team_market, player_id, game) combination
      where the player scored ≥15 points in the 2nd period of a
      game played between 2010-2018.

   2) Keep one record per (team_market, player_id) who satisfied
      that condition in at least one game.

   3) Count the number of distinct such players per team_market,
      sort by that count, and keep the TOP 5 markets.

   4) Return every NCAA-tournament game (2010-2018) in which any
      of those top-five markets appeared, showing core details of
      the matchup.
---------------------------------------------------------------- */
WITH player_game_period2 AS (
    SELECT
        "team_market",
        "player_id",
        "game_id",
        SUM("points_scored") AS "period2_pts"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "period" = 2
      AND "points_scored" IS NOT NULL
      AND "season" BETWEEN 2010 AND 2018
    GROUP BY
        "team_market",
        "player_id",
        "game_id"
),
scorers_15 AS (          -- players who hit 15+ points in period-2 of a game
    SELECT DISTINCT
        "team_market",
        "player_id"
    FROM player_game_period2
    WHERE "period2_pts" >= 15
),
top5_markets AS (        -- five markets with the most distinct such players
    SELECT
        "team_market"
    FROM scorers_15
    GROUP BY "team_market"
    ORDER BY COUNT(DISTINCT "player_id") DESC NULLS LAST
    LIMIT 5
)

SELECT
    htg."season",
    htg."round",
    htg."game_date",
    htg."win_market",
    htg."win_name",
    htg."win_seed",
    htg."win_pts",
    htg."lose_market",
    htg."lose_name",
    htg."lose_seed",
    htg."lose_pts"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES htg
WHERE htg."season" BETWEEN 2010 AND 2018
  AND (
        htg."win_market"  IN (SELECT "team_market" FROM top5_markets)
     OR htg."lose_market" IN (SELECT "team_market" FROM top5_markets)
      )
ORDER BY
    htg."season",
    htg."game_date";
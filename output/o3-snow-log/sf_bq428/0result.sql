/* 1) Identify every player who scored ≥15 points in the 2nd period (2010-2018)
   2) Count those distinct players per team and keep the five highest totals
   3) Pull every NCAA-tournament game (2010-2018) in which any of those
      five teams appeared, showing key game details                       */

WITH period2_15 AS (   -- players with at least 15 points in period-2
    SELECT
        "team_id",
        "player_id"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR"
    WHERE "season" BETWEEN 2010 AND 2018
      AND "period" = 2
    GROUP BY "team_id", "player_id"
    HAVING SUM("points_scored") >= 15
),
top5 AS (              -- five teams with the most such scorers
    SELECT
        "team_id"
    FROM (
        SELECT
            "team_id",
            COUNT(DISTINCT "player_id") AS "num_players_15plus"
        FROM period2_15
        GROUP BY "team_id"
        ORDER BY "num_players_15plus" DESC NULLS LAST
        LIMIT 5
    )
)
SELECT
    h."season",
    h."game_date",
    h."round",
    h."win_market",
    h."win_name",
    h."lose_market",
    h."lose_name",
    h."win_pts",
    h."lose_pts"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TOURNAMENT_GAMES" h
JOIN top5 t
  ON h."win_team_id" = t."team_id"
   OR h."lose_team_id" = t."team_id"
WHERE h."season" BETWEEN 2010 AND 2018
ORDER BY h."season", h."game_date", h."round";
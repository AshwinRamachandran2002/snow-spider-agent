/* 1) Find, for seasons 2010-2018, every (team,player,game) combination
      where the player scored ≥15 points in the 2nd period               */
WITH second_period_15 AS (
    SELECT
        "team_id",
        "player_id",
        "game_id"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "season" BETWEEN 2010 AND 2018
      AND "period" = 2
    GROUP BY
        "team_id",
        "player_id",
        "game_id"
    HAVING
        SUM(COALESCE("points_scored",0)) >= 15
),

/* 2) Count distinct qualifying players per team, keep the top-5 teams   */
top5_teams AS (
    SELECT
        "team_id"
    FROM second_period_15
    GROUP BY
        "team_id"
    ORDER BY
        COUNT(DISTINCT "player_id") DESC NULLS LAST
    LIMIT 5
)

/* 3) Pull every NCAA tournament game (2010-2018) that involved
      at least one of those top-5 teams                                   */
SELECT
    h."season",
    h."game_date",
    h."round",
    h."win_market",
    h."win_name",
    h."win_seed",
    h."lose_market",
    h."lose_name",
    h."lose_seed",
    h."win_pts",
    h."lose_pts"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES AS h
WHERE h."season" BETWEEN 2010 AND 2018
  AND (
        h."win_team_id"  IN (SELECT "team_id" FROM top5_teams)
     OR h."lose_team_id" IN (SELECT "team_id" FROM top5_teams)
  )
ORDER BY
    h."season",
    h."game_date",
    h."round",
    h."win_market";
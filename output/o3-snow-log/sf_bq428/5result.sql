/* ---------------------------------------------------------------------------
   1)  Identify every (game, player) combo that produced ≥15 points
       in the 2nd period during seasons 2010-2018 (regular-season + post-season).
   2)  Count how many DISTINCT players met that mark for each team market
       and keep the TOP-5 such markets.
   3)  List every NCAA-tournament game (2010-2018) in which any of those
       five markets participated, indicating whether the market won or lost
       and showing key details about the game and its opponent.
--------------------------------------------------------------------------- */
WITH second_period_totals AS (                 -- step 1
    SELECT
        "game_id",
        "player_id",
        "team_market",
        SUM("points_scored") AS "second_period_pts"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE "season" BETWEEN 2010 AND 2018
      AND "period" = 2
      AND "points_scored" IS NOT NULL
    GROUP BY
        "game_id",
        "player_id",
        "team_market"
),
big_period_scorers AS (
    SELECT DISTINCT
        "player_id",
        "team_market"
    FROM second_period_totals
    WHERE "second_period_pts" >= 15
),
top5_markets AS (                              -- step 2
    SELECT
        "team_market"
    FROM big_period_scorers
    GROUP BY "team_market"
    ORDER BY COUNT(DISTINCT "player_id") DESC NULLS LAST
    LIMIT 5
)
SELECT                                           -- step 3
    h."season",
    h."round",
    h."game_date",
    CASE
        WHEN h."win_market" = t."team_market" THEN 'WIN'
        ELSE 'LOSS'
    END                             AS "result",
    CASE
        WHEN h."win_market" = t."team_market" THEN h."win_seed"
        ELSE h."lose_seed"
    END                             AS "team_seed",
    t."team_market"                 AS "team_market",
    CASE
        WHEN h."win_market" = t."team_market" THEN h."win_name"
        ELSE h."lose_name"
    END                             AS "team_name",
    CASE
        WHEN h."win_market" = t."team_market" THEN h."lose_market"
        ELSE h."win_market"
    END                             AS "opp_market",
    CASE
        WHEN h."win_market" = t."team_market" THEN h."lose_name"
        ELSE h."win_name"
    END                             AS "opp_name",
    h."win_pts",
    h."lose_pts"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TOURNAMENT_GAMES h
JOIN top5_markets t
  ON  h."win_market"  = t."team_market"
  OR  h."lose_market" = t."team_market"
WHERE h."season" BETWEEN 2010 AND 2018
ORDER BY
    h."season",
    h."game_date",
    t."team_market";
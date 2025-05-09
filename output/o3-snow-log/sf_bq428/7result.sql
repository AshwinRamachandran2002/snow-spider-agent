/*  ---------------------------------------------------------------
    1. Identify every player who scored ≥15 points in the 2nd period
       of ANY game between the 2010-2018 seasons.
    2. Count those DISTINCT players by their school “market” and
       keep the TOP-5 markets.
    3. Return every NCAA-tournament game (2010-2018) in which at
       least one of those TOP-5 markets appeared, flagging whether
       that market won or lost the game.
    --------------------------------------------------------------- */
WITH scoring_players AS (          -- players hitting the 15-point 2nd-period mark
    SELECT DISTINCT
           "player_id",
           "team_id"
    FROM (
        SELECT
               "game_id",
               "player_id",
               "team_id",
               SUM("points_scored") AS "second_period_pts"
        FROM "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_PBP_SR"
        WHERE "season" BETWEEN 2010 AND 2018
          AND "period" = 2
          AND "points_scored" IS NOT NULL
        GROUP BY "game_id", "player_id", "team_id"
        HAVING SUM("points_scored") >= 15
    )
),
top_markets AS (                   -- TOP-5 markets by # of such players
    SELECT
        t."market"
    FROM scoring_players  p
    JOIN "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_TEAMS" t
      ON p."team_id" = t."id"
    GROUP BY t."market"
    ORDER BY COUNT(DISTINCT p."player_id") DESC NULLS LAST
    LIMIT 5
),
tournament_games AS (              -- all tournament games involving those markets
    SELECT
        h.*,
        CASE
            WHEN h."win_market" IN (SELECT "market" FROM top_markets)
                 THEN 'win'
            ELSE 'loss'
        END                                             AS "market_result",
        CASE
            WHEN h."win_market" IN (SELECT "market" FROM top_markets)
                 THEN h."win_market"
            ELSE h."lose_market"
        END                                             AS "top_market"
    FROM "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_HISTORICAL_TOURNAMENT_GAMES" h
    WHERE h."season" BETWEEN 2010 AND 2018
      AND (   h."win_market"  IN (SELECT "market" FROM top_markets)
           OR h."lose_market" IN (SELECT "market" FROM top_markets) )
)
SELECT
    "season",
    "game_date",
    "round",
    "top_market",            -- one of the 5 markets derived above
    "market_result",         -- whether that market won or lost this game
    "win_market",
    "win_name",
    "win_seed",
    "win_pts",
    "lose_market",
    "lose_name",
    "lose_seed",
    "lose_pts"
FROM tournament_games
ORDER BY "season", "game_date", "round";
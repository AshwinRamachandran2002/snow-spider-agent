/*  Chronological list of every scoring play in the
    2014-season game where the home-team Wildcats faced the
    visiting Fighting Irish, showing game clock,
    running scores for both sides, the team that scored,
    and a brief description of the play. */

WITH target_game AS (          -- locate the single game that fits the description
    SELECT DISTINCT
           "game_id",
           "home_market"  AS "wildcats_market",      -- e.g. Kentucky
           "away_market"  AS "irish_market"          -- e.g. Notre Dame
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE  "season"     = 2014
      AND  "home_name"  ILIKE '%wildcats%'
      AND  "away_name"  ILIKE '%fighting irish%'
),

scoring_events AS (            -- keep only rows where someone actually scored
    SELECT  p."game_id",
            p."period",
            p."game_clock",
            p."elapsed_time_sec",
            p."team_market",
            p."points_scored",
            p."event_description",
            g."wildcats_market",
            g."irish_market"
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR p
    JOIN   target_game g
           ON p."game_id" = g."game_id"
    WHERE  p."points_scored" > 0
)

SELECT
       s."period",
       s."game_clock",
       /* running total for the Wildcats (home team) */
       SUM( CASE WHEN s."team_market" = s."wildcats_market"
                 THEN s."points_scored" ELSE 0 END )
           OVER (ORDER BY s."period", s."elapsed_time_sec"
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS "wildcats_score",
       /* running total for the Fighting Irish (away team) */
       SUM( CASE WHEN s."team_market" = s."irish_market"
                 THEN s."points_scored" ELSE 0 END )
           OVER (ORDER BY s."period", s."elapsed_time_sec"
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS "fighting_irish_score",
       s."team_market"      AS "scoring_team",
       s."event_description"
FROM   scoring_events s
ORDER BY s."period",
         s."elapsed_time_sec";
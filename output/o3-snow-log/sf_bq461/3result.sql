/* -----------------------------------------------------------
   Chronological list of every scoring play for the 2014-season
   game in which the home team was the Wildcats (Kentucky) and
   the away team was the Fighting Irish (Notre Dame).
   For each play we show the game clock, running totals for
   both teams, the team that just scored, and the play description.
--------------------------------------------------------------*/
WITH target_game AS (          -- locate the single Kentucky-Notre Dame game
    SELECT DISTINCT
           "game_id",
           "home_market"  AS "wildcats_market",      --  = 'Kentucky'
           "away_market"  AS "irish_market"          --  = 'Notre Dame'
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR"
    WHERE  "season" = 2014
      AND  "home_name" = 'Wildcats'
      AND  "away_name" = 'Fighting Irish'
),
scoring_plays AS (             -- all plays that scored points
    SELECT
        p."game_id",
        p."period",
        p."game_clock",
        p."elapsed_time_sec",
        p."team_market",
        p."team_name",
        p."points_scored",
        p."event_description",
        tg."wildcats_market",
        tg."irish_market"
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR" p
    JOIN   target_game tg
           ON p."game_id" = tg."game_id"
    WHERE  p."points_scored" IS NOT NULL
      AND  p."points_scored" > 0
)
SELECT
    "period",
    "game_clock",
    /* running totals for each side */
    SUM(CASE WHEN "team_market" = "wildcats_market" THEN "points_scored" ELSE 0 END)
        OVER (ORDER BY "elapsed_time_sec")        AS "wildcats_score",
    SUM(CASE WHEN "team_market" = "irish_market"   THEN "points_scored" ELSE 0 END)
        OVER (ORDER BY "elapsed_time_sec")        AS "fighting_irish_score",
    "team_market"    AS "scoring_team_market",
    "team_name"      AS "scoring_team_name",
    "event_description"
FROM   scoring_plays
ORDER BY "elapsed_time_sec";
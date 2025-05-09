/*  Chronological summary of every scoring play in the
    2014-season game where the Wildcats were home and the
    Fighting Irish were away.  For each play we show the
    game clock, running team totals, scoring team, and a
    brief description of the event.                             */

WITH chosen_game AS (          -- locate the unique game
    SELECT DISTINCT
           "game_id",
           "home_alias"  AS wildcats_alias,
           "away_alias"  AS irish_alias
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR
    WHERE  "season"         = 2014
      AND  "home_name"      ILIKE '%Wildcats%'
      AND  "away_name"      ILIKE '%Fighting Irish%'
),

plays AS (                     -- scoring plays only
    SELECT  p.* ,
            g.wildcats_alias ,
            g.irish_alias
    FROM    chosen_game g
    JOIN    NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_PBP_SR p
           ON p."game_id" = g."game_id"
    WHERE   p."points_scored" IS NOT NULL
)

SELECT
       "period",
       "game_clock",
       "team_market"   AS "scoring_team_market",
       "team_name"     AS "scoring_team_name",
       "points_scored",
       /* running totals for each team */
       SUM(CASE WHEN "team_alias" = wildcats_alias THEN "points_scored" ELSE 0 END)
           OVER (ORDER BY "elapsed_time_sec")    AS "wildcats_total",
       SUM(CASE WHEN "team_alias" = irish_alias   THEN "points_scored" ELSE 0 END)
           OVER (ORDER BY "elapsed_time_sec")    AS "fighting_irish_total",
       "event_description"
FROM   plays
ORDER  BY "elapsed_time_sec" ASC;
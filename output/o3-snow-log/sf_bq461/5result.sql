/* 1) Identify the 2014-season game where the home team’s nickname is “Wildcats”
      and the away team’s nickname/market refers to the Notre Dame “Fighting Irish”. */
WITH target_game AS (
    SELECT DISTINCT
           g."game_id",
           g."h_market"  AS wildcats_market,
           g."h_name"    AS wildcats_name,
           g."a_market"  AS irish_market,
           g."a_name"    AS irish_name
    FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_GAMES_SR" g
    WHERE  g."season" = 2014
      AND  g."h_name" ILIKE '%Wildcats%'
      AND (g."a_name" ILIKE '%Fighting%Irish%'
           OR g."a_market" ILIKE '%Notre%Dame%')
)

/* 2) Pull every scoring play for that game and compute running totals for
      both teams in chronological order. */
SELECT
       p."period",
       p."game_clock",
       /* cumulative points for each side, ordered by game time */
       SUM(CASE
               WHEN p."team_market" = tg.wildcats_market
                AND p."team_name"   = tg.wildcats_name
               THEN p."points_scored" ELSE 0
           END)
           OVER (ORDER BY p."elapsed_time_sec")          AS wildcats_total,
       SUM(CASE
               WHEN p."team_market" = tg.irish_market
                AND p."team_name"   = tg.irish_name
               THEN p."points_scored" ELSE 0
           END)
           OVER (ORDER BY p."elapsed_time_sec")          AS irish_total,
       /* team that scored on this play */
       p."team_market"                                    AS scoring_team_market,
       p."team_name"                                      AS scoring_team_name,
       /* points on this play & play description */
       p."points_scored",
       p."event_description"
FROM   NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_PBP_SR"  p
JOIN   target_game tg
       ON p."game_id" = tg."game_id"
WHERE  p."points_scored" IS NOT NULL          -- keep only scoring events
ORDER  BY p."elapsed_time_sec";               -- chronological order
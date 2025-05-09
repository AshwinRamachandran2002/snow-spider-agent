-- Chronological list of every scoring play in the 2014 game
-- with the Wildcats at home and the Fighting Irish away
WITH target_game AS (
  SELECT DISTINCT
         game_id,
         home_market  AS wildcats_market,   -- "Kentucky"
         away_market  AS irish_market       -- "Notre Dame"
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE  season = 2014
    AND  LOWER(home_name) = 'wildcats'
    AND  LOWER(away_name) = 'fighting irish'
)

SELECT
  CONCAT('P', p.period, ' ', p.game_clock)                                  AS period_clock,
  SUM(CASE WHEN p.team_market = tg.wildcats_market THEN p.points_scored END)
      OVER (ORDER BY p.elapsed_time_sec
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)              AS wildcats_total,
  SUM(CASE WHEN p.team_market = tg.irish_market   THEN p.points_scored END)
      OVER (ORDER BY p.elapsed_time_sec
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)              AS fighting_irish_total,
  p.team_market                                                             AS team_that_scored,
  p.event_description
FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
JOIN   target_game tg
  ON   p.game_id = tg.game_id
WHERE  p.points_scored IS NOT NULL
  AND  p.points_scored > 0
ORDER  BY p.elapsed_time_sec;
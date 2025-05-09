-- Chronological scoring summary for the 2014 season game
--   Home : Wildcats (Kentucky)
--   Away : Fighting Irish (Notre Dame)

WITH chosen_game AS (
  SELECT DISTINCT
         game_id,
         home_market  AS wildcats_market,        -- "Kentucky"
         away_market  AS fighting_irish_market   -- "Notre Dame"
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE  season = 2014
    AND  LOWER(home_name)  = 'wildcats'
    AND  LOWER(away_name)  = 'fighting irish'
  LIMIT  1
),
scoring_plays AS (
  SELECT
    pbp.elapsed_time_sec,
    pbp.game_clock,
    pbp.team_market,
    pbp.points_scored,
    pbp.event_description
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` pbp
  JOIN   chosen_game g
    ON   pbp.game_id = g.game_id
  WHERE  pbp.points_scored > 0               -- keep only scoring events
),
running_totals AS (
  SELECT
    sp.*,
    SUM(CASE WHEN sp.team_market = (SELECT wildcats_market FROM chosen_game)
             THEN sp.points_scored ELSE 0 END)
        OVER (ORDER BY sp.elapsed_time_sec)
        AS wildcats_score,
    SUM(CASE WHEN sp.team_market = (SELECT fighting_irish_market FROM chosen_game)
             THEN sp.points_scored ELSE 0 END)
        OVER (ORDER BY sp.elapsed_time_sec)
        AS fighting_irish_score
  FROM scoring_plays sp
)

SELECT
  game_clock,
  wildcats_score,
  fighting_irish_score,
  team_market  AS scoring_team,
  event_description
FROM running_totals
ORDER BY elapsed_time_sec;
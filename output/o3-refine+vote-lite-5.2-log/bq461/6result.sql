-- chronological scoring summary, 2014 season
WITH game AS (
  -- identify the single 2014 game with home = Wildcats, away = Fighting Irish
  SELECT DISTINCT
         game_id,
         home_id,          -- Wildcats team id (home)
         away_id           -- Fighting Irish team id (away)
  FROM  `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE season = 2014
    AND LOWER(home_name) = 'wildcats'
    AND LOWER(away_name) = 'fighting irish'
),
scoring_events AS (
  -- keep only plays that added points
  SELECT
         p.game_clock,
         p.elapsed_time_sec,
         p.timestamp,
         p.team_id,
         p.points_scored,
         p.event_description,
         g.home_id,
         g.away_id
  FROM  `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
  JOIN  game g
  ON    p.game_id = g.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0
),
running_totals AS (
  SELECT
         game_clock,
         elapsed_time_sec,
         timestamp,
         event_description,
         -- who scored on this play
         CASE
           WHEN team_id = home_id THEN 'Wildcats'
           ELSE 'Fighting Irish'
         END                                                   AS scoring_team,
         -- running score for each side
         SUM(CASE WHEN team_id = home_id THEN points_scored ELSE 0 END)
           OVER (ORDER BY elapsed_time_sec, timestamp)         AS wildcats_score,
         SUM(CASE WHEN team_id = away_id THEN points_scored ELSE 0 END)
           OVER (ORDER BY elapsed_time_sec, timestamp)         AS fighting_irish_score
  FROM   scoring_events
)
SELECT
       game_clock,
       wildcats_score,
       fighting_irish_score,
       scoring_team,
       event_description
FROM   running_totals
ORDER BY elapsed_time_sec, timestamp;
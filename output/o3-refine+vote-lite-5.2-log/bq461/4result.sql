-- Chronological list of every scoring play in the 2014 season game
-- where the home team’s nickname is “Wildcats” and the away team’s
-- nickname is “Fighting Irish”.
WITH chosen_game AS (
  SELECT DISTINCT
         game_id,
         home_market,         -- e.g. “Kentucky”
         away_market          -- e.g. “Notre Dame”
  FROM   `bigquery-public-data.ncaa_basketball.mbb_pbp_sr`
  WHERE  season     = 2014
    AND  home_name  = 'Wildcats'
    AND  away_name  = 'Fighting Irish'
),
scoring_plays AS (
  SELECT
      p.game_id,
      p.period,
      p.elapsed_time_sec,
      p.game_clock,
      COALESCE(p.team_market, p.team_name)             AS scoring_team,
      p.points_scored,
      p.event_description,
      cg.home_market,
      cg.away_market,
      p.event_id                                       -- tie‑breaker for ordering
  FROM  `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` p
  JOIN  chosen_game cg
    ON  p.game_id = cg.game_id
  WHERE p.points_scored IS NOT NULL
    AND p.points_scored > 0                           -- keep only scoring events
)
SELECT
    game_clock,
    wildcats_score     AS wildcats_cum_pts,
    fighting_irish_score AS fighting_irish_cum_pts,
    scoring_team,
    event_description
FROM (
    SELECT
        *,
        SUM(CASE WHEN scoring_team = home_market THEN points_scored ELSE 0 END)
            OVER (PARTITION BY game_id
                  ORDER BY period, elapsed_time_sec, event_id)  AS wildcats_score,
        SUM(CASE WHEN scoring_team = away_market THEN points_scored ELSE 0 END)
            OVER (PARTITION BY game_id
                  ORDER BY period, elapsed_time_sec, event_id)  AS fighting_irish_score
    FROM scoring_plays
)
ORDER BY period, elapsed_time_sec, event_id;
WITH target_game AS (
  SELECT
    game_id,
    h_market AS wildcats_market,
    a_market AS fighting_irish_market
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season = 2014
    AND LOWER(h_name)  = 'wildcats'
    AND LOWER(a_name)  = 'fighting irish'
),
plays AS (
  SELECT
    p.elapsed_time_sec,
    p.game_clock,
    p.event_id,
    p.team_market,
    p.points_scored,
    p.event_description,
    g.wildcats_market,
    g.fighting_irish_market
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  JOIN target_game g
    ON p.game_id = g.game_id
  WHERE p.points_scored > 0
),
running_totals AS (
  SELECT
    game_clock,
    elapsed_time_sec,
    event_id,
    CASE
      WHEN team_market = wildcats_market        THEN 'Wildcats'
      WHEN team_market = fighting_irish_market  THEN 'Fighting Irish'
    END AS scoring_team,
    event_description AS description,
    SUM(CASE WHEN team_market = wildcats_market        THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec, event_id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS wildcats_score,
    SUM(CASE WHEN team_market = fighting_irish_market  THEN points_scored ELSE 0 END)
        OVER (ORDER BY elapsed_time_sec, event_id
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS fighting_irish_score
  FROM plays
)
SELECT
  game_clock,
  ROUND(wildcats_score, 4)       AS wildcats_score,
  ROUND(fighting_irish_score, 4) AS fighting_irish_score,
  scoring_team,
  description
FROM running_totals
ORDER BY elapsed_time_sec, event_id;
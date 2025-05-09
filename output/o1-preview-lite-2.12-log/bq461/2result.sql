WITH game_info AS (
  SELECT
    game_id,
    h_id AS home_team_id,
    h_market AS home_team_market,
    a_id AS away_team_id,
    a_market AS away_team_market
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE game_id = '95cda731-b593-42cd-8573-621a3d1369dc'
), scoring_plays AS (
  SELECT
    p.period,
    p.game_clock,
    p.elapsed_time_sec,
    p.team_id,
    p.team_market,
    p.points_scored,
    p.event_description,
    gi.home_team_id,
    gi.home_team_market,
    gi.away_team_id,
    gi.away_team_market,
    SUM(CASE WHEN p.team_id = gi.home_team_id THEN p.points_scored ELSE 0 END) OVER (ORDER BY p.elapsed_time_sec) AS home_team_score_so_far,
    SUM(CASE WHEN p.team_id = gi.away_team_id THEN p.points_scored ELSE 0 END) OVER (ORDER BY p.elapsed_time_sec) AS away_team_score_so_far
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` AS p
  CROSS JOIN game_info AS gi
  WHERE p.game_id = gi.game_id
    AND p.points_scored > 0
)

SELECT
  period,
  game_clock,
  CONCAT(
    CAST(home_team_score_so_far AS STRING), ' (', home_team_market, ') - ',
    CAST(away_team_score_so_far AS STRING), ' (', away_team_market, ')'
  ) AS team_scores,
  team_market AS scoring_team,
  event_description
FROM scoring_plays
ORDER BY elapsed_time_sec;
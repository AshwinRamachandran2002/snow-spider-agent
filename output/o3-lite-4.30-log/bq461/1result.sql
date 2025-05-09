WITH game AS (
  SELECT game_id
  FROM `bigquery-public-data.ncaa_basketball.mbb_games_sr`
  WHERE season = 2014
    AND LOWER(h_name)  = 'wildcats'
    AND LOWER(a_name)  = 'fighting irish'
  LIMIT 1
),
scoring AS (
  SELECT
    pbp.elapsed_time_sec,
    pbp.game_clock,
    pbp.event_description,
    CASE 
      WHEN LOWER(pbp.team_name) = 'wildcats'        THEN 'Wildcats'
      WHEN LOWER(pbp.team_name) = 'fighting irish'  THEN 'Fighting Irish'
      ELSE pbp.team_name
    END                                                        AS scoring_team,
    CASE WHEN LOWER(pbp.team_name) = 'wildcats'        THEN pbp.points_scored ELSE 0 END AS pts_wildcats,
    CASE WHEN LOWER(pbp.team_name) = 'fighting irish'  THEN pbp.points_scored ELSE 0 END AS pts_irish
  FROM `bigquery-public-data.ncaa_basketball.mbb_pbp_sr` pbp
  JOIN game
    ON pbp.game_id = game.game_id
  WHERE pbp.points_scored > 0
)
SELECT
  game_clock,
  ROUND(SUM(pts_wildcats) OVER (ORDER BY elapsed_time_sec), 4)  AS wildcats_score,
  ROUND(SUM(pts_irish)   OVER (ORDER BY elapsed_time_sec), 4)  AS fighting_irish_score,
  scoring_team,
  event_description AS description
FROM scoring
ORDER BY elapsed_time_sec;
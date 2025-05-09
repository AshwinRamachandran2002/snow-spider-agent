WITH game_data AS (
  SELECT
    season,
    'win' AS label,
    win_seed AS seed,
    win_school_ncaa AS school_ncaa,
    lose_seed AS opponent_seed,
    lose_school_ncaa AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season BETWEEN 2014 AND 2018

  UNION ALL

  SELECT
    season,
    'loss' AS label,
    lose_seed AS seed,
    lose_school_ncaa AS school_ncaa,
    win_seed AS opponent_seed,
    win_school_ncaa AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season BETWEEN 2014 AND 2018
)

SELECT
  gd.season,
  gd.label,
  gd.seed,
  gd.school_ncaa,
  gd.opponent_seed,
  gd.opponent_school_ncaa,
  CAST(fe_team.pace_rank AS INT64) AS pace_rank,
  ROUND(fe_team.poss_40min, 4) AS poss_40min,
  ROUND(fe_team.pace_rating, 4) AS pace_rating,
  CAST(fe_team.efficiency_rank AS INT64) AS efficiency_rank,
  ROUND(fe_team.pts_100poss, 4) AS pts_100poss,
  ROUND(fe_team.efficiency_rating, 4) AS efficiency_rating,
  CAST(fe_opp.pace_rank AS INT64) AS opp_pace_rank,
  ROUND(fe_opp.poss_40min, 4) AS opp_poss_40min,
  ROUND(fe_opp.pace_rating, 4) AS opp_pace_rating,
  CAST(fe_opp.efficiency_rank AS INT64) AS opp_efficiency_rank,
  ROUND(fe_opp.pts_100poss, 4) AS opp_pts_100poss,
  ROUND(fe_opp.efficiency_rating, 4) AS opp_efficiency_rating,
  CAST(fe_opp.pace_rank - fe_team.pace_rank AS INT64) AS pace_rank_diff,
  ROUND(fe_opp.poss_40min - fe_team.poss_40min, 4) AS pace_stat_diff,
  ROUND(fe_opp.pace_rating - fe_team.pace_rating, 4) AS pace_rating_diff,
  CAST(fe_opp.efficiency_rank - fe_team.efficiency_rank AS INT64) AS eff_rank_diff,
  ROUND(fe_opp.pts_100poss - fe_team.pts_100poss, 4) AS eff_stat_diff,
  ROUND(fe_opp.efficiency_rating - fe_team.efficiency_rating, 4) AS eff_rating_diff
FROM game_data gd
LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe_team
  ON fe_team.season = gd.season AND LOWER(fe_team.team) = LOWER(gd.school_ncaa)
LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe_opp
  ON fe_opp.season = gd.season AND LOWER(fe_opp.team) = LOWER(gd.opponent_school_ncaa)
WHERE gd.season BETWEEN 2014 AND 2018
ORDER BY gd.season, gd.school_ncaa, gd.opponent_school_ncaa;
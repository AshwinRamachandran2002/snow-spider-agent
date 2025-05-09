WITH games AS (
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
  g.season,
  g.label,
  g.seed,
  g.school_ncaa,
  g.opponent_seed,
  g.opponent_school_ncaa,
  tm.pace_rank,
  tm.poss_40min,
  tm.pace_rating,
  tm.efficiency_rank,
  tm.pts_100poss,
  tm.efficiency_rating,
  om.pace_rank AS opp_pace_rank,
  om.poss_40min AS opp_poss_40min,
  om.pace_rating AS opp_pace_rating,
  om.efficiency_rank AS opp_efficiency_rank,
  om.pts_100poss AS opp_pts_100poss,
  om.efficiency_rating AS opp_efficiency_rating,
  SAFE_CAST(om.pace_rank AS INT64) - SAFE_CAST(tm.pace_rank AS INT64) AS pace_rank_diff,
  om.poss_40min - tm.poss_40min AS pace_stat_diff,
  om.pace_rating - tm.pace_rating AS pace_rating_diff,
  SAFE_CAST(om.efficiency_rank AS INT64) - SAFE_CAST(tm.efficiency_rank AS INT64) AS eff_rank_diff,
  om.pts_100poss - tm.pts_100poss AS eff_stat_diff,
  om.efficiency_rating - tm.efficiency_rating AS eff_rating_diff
FROM games AS g
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS tm
  ON g.season = tm.season AND g.school_ncaa = tm.team
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS om
  ON g.season = om.season AND g.opponent_school_ncaa = om.team
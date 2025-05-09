-- =====================================================================
--  Dataset: NCAA men’s tournament results 2014‑present enriched with
--           pace & efficiency metrics for every team and its opponent
-- =====================================================================
WITH
/* ------------- 1.  Historical tournament games (2014‑2017) ---------- */
hist AS (
  SELECT
      season,
      'win'                                           AS label,
      win_seed                                        AS seed,
      win_school_ncaa                                 AS school_ncaa,
      lose_seed                                       AS opponent_seed,
      lose_school_ncaa                                AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
  
  UNION ALL
  
  SELECT
      season,
      'loss'                                          AS label,
      lose_seed                                       AS seed,
      lose_school_ncaa                                AS school_ncaa,
      win_seed                                        AS opponent_seed,
      win_school_ncaa                                 AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

/* ------------- 2.  2018 tournament games ----------------------------- */
r2018 AS (
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
),

/* ------------- 3.  Combined tournament set --------------------------- */
tourney AS (
  SELECT * FROM hist
  UNION ALL
  SELECT * FROM r2018
),

/* ------------- 4.  Pace / efficiency metrics ------------------------- */
metrics AS (
  SELECT
      season,
      team                             AS school_ncaa,
      poss_40min,
      pace_rating,
      pace_rank,
      pts_100poss,
      efficiency_rating,
      efficiency_rank
  FROM `data-to-insights.ncaa.feature_engineering`
)

/* ------------- 5.  Final enriched dataset --------------------------- */
SELECT
    g.season,
    g.label,
    g.seed,
    g.school_ncaa,
    
    m.pace_rank,
    m.poss_40min,
    m.pace_rating,
    m.efficiency_rank,
    m.pts_100poss,
    m.efficiency_rating,
    
    g.opponent_seed,
    g.opponent_school_ncaa,
    
    om.pace_rank            AS opp_pace_rank,
    om.poss_40min           AS opp_poss_40min,
    om.pace_rating          AS opp_pace_rating,
    om.efficiency_rank      AS opp_efficiency_rank,
    om.pts_100poss          AS opp_pts_100poss,
    om.efficiency_rating    AS opp_efficiency_rating,
    
    -- ------------------ Metric differences (opp – team) ---------------
    (om.pace_rank         - m.pace_rank        )   AS pace_rank_diff,
    (om.poss_40min        - m.poss_40min       )   AS pace_stat_diff,
    (om.pace_rating       - m.pace_rating      )   AS pace_rating_diff,
    (om.efficiency_rank   - m.efficiency_rank  )   AS eff_rank_diff,
    (om.pts_100poss       - m.pts_100poss      )   AS eff_stat_diff,
    (om.efficiency_rating - m.efficiency_rating)   AS eff_rating_diff
FROM tourney AS g
LEFT JOIN metrics  AS m  ON m.season = g.season AND m.school_ncaa = g.school_ncaa
LEFT JOIN metrics  AS om ON om.season = g.season AND om.school_ncaa = g.opponent_school_ncaa
ORDER BY g.season, g.school_ncaa, g.label;
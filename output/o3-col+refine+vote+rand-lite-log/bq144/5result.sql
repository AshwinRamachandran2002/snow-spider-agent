/* -------------------------------------------------------------
   NCAA MEN – Tournament results (2014-on) enriched with
   pace & efficiency metrics for each team and its opponent
   -------------------------------------------------------------
*/
WITH
/* 1.  Historical tournaments (2014-2017) – create both
       winner- and loser-centric rows and label them          */
hist AS (
  -- winner view
  SELECT
      season,
      win_seed              AS seed,
      win_school_ncaa       AS school_ncaa,
      lose_seed             AS opponent_seed,
      lose_school_ncaa      AS opponent_school_ncaa,
      'win'                 AS label
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  -- loser view
  SELECT
      season,
      lose_seed             AS seed,
      lose_school_ncaa      AS school_ncaa,
      win_seed              AS opponent_seed,
      win_school_ncaa       AS opponent_school_ncaa,
      'loss'                AS label
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

/* 2.  2018 tournament (already team-centric & labelled)       */
tr18 AS (
  SELECT
      season,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa,
      label
  FROM `data-to-insights.ncaa.2018_tournament_results`
)

/* 3.  Combine seasons 2014-2018, then attach metrics          */
SELECT
    d.season,
    d.label,
    d.seed,
    d.school_ncaa,
    d.opponent_seed,
    d.opponent_school_ncaa,

    /* ---- team metrics ---- */
    f_team.pace_rank           AS pace_rank,
    f_team.poss_40min          AS poss_40min,
    f_team.pace_rating         AS pace_rating,
    f_team.efficiency_rank     AS efficiency_rank,
    f_team.pts_100poss         AS pts_100poss,
    f_team.efficiency_rating   AS efficiency_rating,

    /* ---- opponent metrics ---- */
    f_opp.pace_rank            AS opp_pace_rank,
    f_opp.poss_40min           AS opp_poss_40min,
    f_opp.pace_rating          AS opp_pace_rating,
    f_opp.efficiency_rank      AS opp_efficiency_rank,
    f_opp.pts_100poss          AS opp_pts_100poss,
    f_opp.efficiency_rating    AS opp_efficiency_rating,

    /* ---- differences (opponent – team) ---- */
    (f_opp.pace_rank         - f_team.pace_rank)         AS pace_rank_diff,
    (f_opp.poss_40min        - f_team.poss_40min)        AS pace_stat_diff,
    (f_opp.pace_rating       - f_team.pace_rating)       AS pace_rating_diff,
    (f_opp.efficiency_rank   - f_team.efficiency_rank)   AS eff_rank_diff,
    (f_opp.pts_100poss       - f_team.pts_100poss)       AS eff_stat_diff,
    (f_opp.efficiency_rating - f_team.efficiency_rating) AS eff_rating_diff
FROM (
      SELECT * FROM hist
      UNION ALL
      SELECT * FROM tr18
) AS d
/* join in team metrics */
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS f_team
  ON f_team.season = d.season
 AND f_team.team   = d.school_ncaa
/* join in opponent metrics */
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS f_opp
  ON f_opp.season  = d.season
 AND f_opp.team    = d.opponent_school_ncaa
ORDER BY season, school_ncaa, opponent_school_ncaa
;
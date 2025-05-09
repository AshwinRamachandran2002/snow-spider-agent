/* -----------------------------------------------------------
   NCAA Men’s Tournament 2014-present
   – team-level outcomes with pace & efficiency metrics
   ----------------------------------------------------------- */

-- 1)  Long-format WIN / LOSS rows from historical tournament table
WITH hist_long AS (
  SELECT
      season,
      'win'                     AS label,
      win_seed                  AS seed,
      win_school_ncaa           AS school_ncaa,
      lose_seed                 AS opponent_seed,
      lose_school_ncaa          AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
      season,
      'loss'                    AS label,
      lose_seed                 AS seed,
      lose_school_ncaa          AS school_ncaa,
      win_seed                  AS opponent_seed,
      win_school_ncaa           AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

-- 2)  Attach pace / efficiency metrics (team & opponent) to the historical rows
hist_metrics AS (
  SELECT
      h.*,
      /*  team metrics  */
      fe_team.poss_40min        AS poss_40min,
      fe_team.pace_rating       AS pace_rating,
      fe_team.pace_rank         AS pace_rank,
      fe_team.pts_100poss       AS pts_100poss,
      fe_team.efficiency_rating AS efficiency_rating,
      fe_team.efficiency_rank   AS efficiency_rank,

      /*  opponent metrics  */
      fe_opp.poss_40min         AS opp_poss_40min,
      fe_opp.pace_rating        AS opp_pace_rating,
      fe_opp.pace_rank          AS opp_pace_rank,
      fe_opp.pts_100poss        AS opp_pts_100poss,
      fe_opp.efficiency_rating  AS opp_efficiency_rating,
      fe_opp.efficiency_rank    AS opp_efficiency_rank
  FROM hist_long h
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe_team
         ON fe_team.season = h.season
        AND fe_team.team   = h.school_ncaa
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe_opp
         ON fe_opp.season  = h.season
        AND fe_opp.team    = h.opponent_school_ncaa
),

-- 3)  2018 tournament results already in long format – add metrics the same way
res18 AS (
  SELECT
      r.season,
      r.label,
      r.seed                   AS seed,
      r.school_ncaa,
      r.opponent_seed          AS opponent_seed,
      r.opponent_school_ncaa,

      /*  team metrics  */
      fe_team.poss_40min        AS poss_40min,
      fe_team.pace_rating       AS pace_rating,
      fe_team.pace_rank         AS pace_rank,
      fe_team.pts_100poss       AS pts_100poss,
      fe_team.efficiency_rating AS efficiency_rating,
      fe_team.efficiency_rank   AS efficiency_rank,

      /*  opponent metrics  */
      fe_opp.poss_40min         AS opp_poss_40min,
      fe_opp.pace_rating        AS opp_pace_rating,
      fe_opp.pace_rank          AS opp_pace_rank,
      fe_opp.pts_100poss        AS opp_pts_100poss,
      fe_opp.efficiency_rating  AS opp_efficiency_rating,
      fe_opp.efficiency_rank    AS opp_efficiency_rank
  FROM `data-to-insights.ncaa.2018_tournament_results` r
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe_team
         ON fe_team.season = r.season
        AND fe_team.team   = r.school_ncaa
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` fe_opp
         ON fe_opp.season  = r.season
        AND fe_opp.team    = r.opponent_school_ncaa
),

-- 4)  Combine all seasons & create difference features
combined AS (
  SELECT * FROM hist_metrics
  UNION ALL
  SELECT * FROM res18
)

-- 5)  Final dataset with metric differences (opponent – team)
SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa,

    /*  team metrics  */
    poss_40min,
    pace_rating,
    pace_rank,
    pts_100poss,
    efficiency_rating,
    efficiency_rank,

    /*  opponent metrics  */
    opp_poss_40min,
    opp_pace_rating,
    opp_pace_rank,
    opp_pts_100poss,
    opp_efficiency_rating,
    opp_efficiency_rank,

    /*  differences:  opponent minus team  */
    opp_poss_40min        - poss_40min        AS poss_40min_diff,
    opp_pace_rating       - pace_rating       AS pace_rating_diff,
    opp_pace_rank         - pace_rank         AS pace_rank_diff,
    opp_pts_100poss       - pts_100poss       AS pts_100poss_diff,
    opp_efficiency_rating - efficiency_rating AS efficiency_rating_diff,
    opp_efficiency_rank   - efficiency_rank   AS efficiency_rank_diff
FROM combined
ORDER BY season DESC, school_ncaa, label;
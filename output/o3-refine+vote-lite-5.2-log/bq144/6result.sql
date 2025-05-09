/* -----------------------------------------------------------
   NCAA MEN’S TOURNAMENT – TEAM VS OPPONENT METRICS (2014‑present)
   -----------------------------------------------------------
   1.  Build one row per team–game outcome
       • Historical games (2014+) → split winner & loser
       • 2018 results table already contains both rows
   2.  Attach pace / efficiency metrics for the team
       and its opponent from feature_engineering
   3.  Calculate opponent‑minus‑team differentials
   ----------------------------------------------------------- */

WITH union_games AS (
  -- Historical tournament games (one row per TEAM)
  SELECT
      season,
      'win' AS label,
      win_seed      AS seed,
      win_school_ncaa       AS school_ncaa,
      lose_seed     AS opponent_seed,
      lose_school_ncaa      AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL
  SELECT
      season,
      'loss' AS label,
      lose_seed     AS seed,
      lose_school_ncaa      AS school_ncaa,
      win_seed      AS opponent_seed,
      win_school_ncaa       AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL
  -- 2018 tournament results (already per‑team rows)
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
),

add_metrics AS (
  SELECT
      g.*,

      /* -------------- TEAM METRICS -------------- */
      fe.pace_rank,
      fe.poss_40min,
      fe.pace_rating,
      fe.efficiency_rank,
      fe.pts_100poss,
      fe.efficiency_rating,

      /* -------------- OPPONENT METRICS -------------- */
      fe_opp.pace_rank             AS opp_pace_rank,
      fe_opp.poss_40min            AS opp_poss_40min,
      fe_opp.pace_rating           AS opp_pace_rating,
      fe_opp.efficiency_rank       AS opp_efficiency_rank,
      fe_opp.pts_100poss           AS opp_pts_100poss,
      fe_opp.efficiency_rating     AS opp_efficiency_rating,

      /* -------------- DIFFS (opp – team) -------------- */
      fe_opp.pace_rank         - fe.pace_rank         AS pace_rank_diff,
      fe_opp.poss_40min        - fe.poss_40min        AS poss_40min_diff,
      fe_opp.pace_rating       - fe.pace_rating       AS pace_rating_diff,
      fe_opp.efficiency_rank   - fe.efficiency_rank   AS efficiency_rank_diff,
      fe_opp.pts_100poss       - fe.pts_100poss       AS pts_100poss_diff,
      fe_opp.efficiency_rating - fe.efficiency_rating AS efficiency_rating_diff

  FROM   union_games g
  LEFT JOIN `data-to-insights.ncaa.feature_engineering`       AS fe
         ON fe.season = g.season
        AND fe.team   = g.school_ncaa
  LEFT JOIN `data-to-insights.ncaa.feature_engineering`       AS fe_opp
         ON fe_opp.season = g.season
        AND fe_opp.team   = g.opponent_school_ncaa
)

SELECT *
FROM   add_metrics
ORDER  BY season, school_ncaa, label DESC;
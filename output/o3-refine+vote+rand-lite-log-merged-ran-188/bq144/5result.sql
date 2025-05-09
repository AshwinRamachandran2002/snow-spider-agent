/* ----------------------------------------------------------
   NCAA MBB – Tournament games (2014‑present) enriched with
   pace & efficiency metrics for each team and its opponent
   ---------------------------------------------------------- */
WITH tournament_games AS (        -- 1.  team‑level results 2014‑18
  /* a) 2018 tournament – already team level (has win & loss rows) */
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
  WHERE season >= 2014

  UNION ALL

  /* b) Historical tournament games (2014‑17) – explode to team rows  */
  SELECT
      season,
      'win'  AS label,
      win_seed          AS seed,
      win_school_ncaa   AS school_ncaa,
      lose_seed         AS opponent_seed,
      lose_school_ncaa  AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL
  SELECT
      season,
      'loss' AS label,
      lose_seed         AS seed,
      lose_school_ncaa  AS school_ncaa,
      win_seed          AS opponent_seed,
      win_school_ncaa   AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

/* ----------------------------------------------------------
   2.  Feature‑engineering metrics (pace & efficiency)
   ---------------------------------------------------------- */
feat AS (
  SELECT
      season,
      team                                AS school_ncaa,
      pace_rank,
      poss_40min,
      pace_rating,
      efficiency_rank,
      pts_100poss,
      efficiency_rating
  FROM `data-to-insights.ncaa.feature_engineering`
)

/* ----------------------------------------------------------
   3.  Assemble final dataset
   ---------------------------------------------------------- */
SELECT
    g.season,
    g.label,
    g.seed,
    g.school_ncaa,
    g.opponent_seed,
    g.opponent_school_ncaa,

    /*  team metrics */
    f.pace_rank,
    f.poss_40min,
    f.pace_rating,
    f.efficiency_rank,
    f.pts_100poss,
    f.efficiency_rating,

    /*  opponent metrics  */
    ofe.pace_rank            AS opp_pace_rank,
    ofe.poss_40min           AS opp_poss_40min,
    ofe.pace_rating          AS opp_pace_rating,
    ofe.efficiency_rank      AS opp_efficiency_rank,
    ofe.pts_100poss          AS opp_pts_100poss,
    ofe.efficiency_rating    AS opp_efficiency_rating,

    /*  differences (opponent – team) */
    ofe.pace_rank         - f.pace_rank          AS pace_rank_diff,
    ofe.poss_40min        - f.poss_40min         AS pace_stat_diff,
    ofe.pace_rating       - f.pace_rating        AS pace_rating_diff,
    ofe.efficiency_rank   - f.efficiency_rank    AS eff_rank_diff,
    ofe.pts_100poss       - f.pts_100poss        AS eff_stat_diff,
    ofe.efficiency_rating - f.efficiency_rating  AS eff_rating_diff
FROM
    tournament_games  AS g
LEFT JOIN
    feat              AS f
ON  f.season = g.season
AND f.school_ncaa = g.school_ncaa
LEFT JOIN
    feat              AS ofe
ON  ofe.season = g.season
AND ofe.school_ncaa = g.opponent_school_ncaa
ORDER BY
    season,
    school_ncaa,
    label DESC;      -- handy ordering
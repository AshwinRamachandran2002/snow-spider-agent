-- =============================
--  Tournament Outcomes 2014‑2018
--  + Pace & Efficiency Metrics
-- =============================
WITH

/* -------- 1.  Historical tournament games (2014‑2017) ---------- */
hist AS (
  SELECT
      season,
      'win'  AS label,
      win_seed  AS seed,
      win_school_ncaa        AS school_ncaa,
      lose_seed AS opponent_seed,
      lose_school_ncaa       AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
      season,
      'loss' AS label,
      lose_seed AS seed,
      lose_school_ncaa       AS school_ncaa,
      win_seed  AS opponent_seed,
      win_school_ncaa        AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

/* -------- 2.  2018 tournament results (already split W/L) -------- */
tr2018 AS (
  SELECT
      season,
      label,
      seed,
      school_ncaa,
      opponent_seed,
      opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
  WHERE season = 2018
),

/* -------- 3.  Combine all seasons 2014‑2018 ---------------------- */
combined AS (
  SELECT * FROM hist
  UNION ALL
  SELECT * FROM tr2018
)

-- -------- 4.  Attach pace/efficiency metrics ---------------------
SELECT
    c.season,
    c.label,

    /* team (row perspective) */
    c.seed,
    c.school_ncaa,

    /* opponent */
    c.opponent_seed,
    c.opponent_school_ncaa,

    /* ---------- Team metrics ---------- */
    tm.pace_rank,
    tm.poss_40min,
    tm.pace_rating,
    tm.efficiency_rank,
    tm.pts_100poss,
    tm.efficiency_rating,

    /* ---------- Opponent metrics ---------- */
    opp.pace_rank           AS opp_pace_rank,
    opp.poss_40min          AS opp_poss_40min,
    opp.pace_rating         AS opp_pace_rating,
    opp.efficiency_rank     AS opp_efficiency_rank,
    opp.pts_100poss         AS opp_pts_100poss,
    opp.efficiency_rating   AS opp_efficiency_rating,

    /* ---------- Differences (opp – team) ---------- */
    (opp.pace_rank        - tm.pace_rank)        AS pace_rank_diff,
    (opp.poss_40min       - tm.poss_40min)       AS pace_stat_diff,
    (opp.pace_rating      - tm.pace_rating)      AS pace_rating_diff,
    (opp.efficiency_rank  - tm.efficiency_rank)  AS eff_rank_diff,
    (opp.pts_100poss      - tm.pts_100poss)      AS eff_stat_diff,
    (opp.efficiency_rating- tm.efficiency_rating)AS eff_rating_diff

FROM combined AS c
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS tm
       ON tm.season = c.season
      AND tm.team   = c.school_ncaa
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS opp
       ON opp.season = c.season
      AND opp.team   = c.opponent_school_ncaa
;
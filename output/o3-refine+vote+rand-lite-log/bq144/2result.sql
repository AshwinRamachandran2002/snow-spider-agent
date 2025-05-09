/* =======================================================================
   NCAA Men’s Tournament – Game Outcomes (2014‑present)  
   + Team & Opponent Pace / Efficiency Metrics & Their Differences
   ======================================================================= */
WITH game_outcomes AS (
  /* ---------- 1. Historical tournament games (2014‑present) ------------ */
  SELECT
    season,
    'win'  AS label,
    win_seed      AS seed,
    win_school_ncaa       AS school_ncaa,
    lose_seed     AS opponent_seed,
    lose_school_ncaa      AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
  
  UNION ALL
  SELECT
    season,
    'loss' AS label,
    lose_seed     AS seed,
    lose_school_ncaa      AS school_ncaa,
    win_seed      AS opponent_seed,
    win_school_ncaa       AS opponent_school_ncaa
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
  
  /* ----------------------- 2. 2018 results table ------------------------ */
  UNION ALL
  SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa
  FROM `data-to-insights.ncaa.2018_tournament_results`
  WHERE season >= 2014
),

/* -------- 3. Pace / efficiency metrics pulled once for each team -------- */
metrics AS (
  SELECT
    season,
    team AS school_ncaa,
    poss_40min,
    pace_rating,
    pace_rank,
    pts_100poss,
    efficiency_rating,
    efficiency_rank
  FROM `data-to-insights.ncaa.feature_engineering`
)

/* --------------------------- 4. Final set ------------------------------ */
SELECT
  g.season,
  g.label,
  g.seed,
  g.school_ncaa,
  g.opponent_seed,
  g.opponent_school_ncaa,

  /* ---------- team metrics ---------- */
  tm.pace_rank,
  tm.poss_40min,
  tm.pace_rating,
  tm.efficiency_rank,
  tm.pts_100poss,
  tm.efficiency_rating,

  /* -------- opponent metrics -------- */
  op.pace_rank           AS opp_pace_rank,
  op.poss_40min          AS opp_poss_40min,
  op.pace_rating         AS opp_pace_rating,
  op.efficiency_rank     AS opp_efficiency_rank,
  op.pts_100poss         AS opp_pts_100poss,
  op.efficiency_rating   AS opp_efficiency_rating,

  /* ------------- differences (opponent – team) -------------- */
  (op.pace_rank        - tm.pace_rank)        AS pace_rank_diff,
  (op.poss_40min       - tm.poss_40min)       AS pace_stat_diff,
  (op.pace_rating      - tm.pace_rating)      AS pace_rating_diff,
  (op.efficiency_rank  - tm.efficiency_rank)  AS eff_rank_diff,
  (op.pts_100poss      - tm.pts_100poss)      AS eff_stat_diff,
  (op.efficiency_rating- tm.efficiency_rating)AS eff_rating_diff
FROM game_outcomes           AS g
LEFT JOIN metrics            AS tm
       ON tm.season       = g.season
      AND tm.school_ncaa  = g.school_ncaa
LEFT JOIN metrics            AS op
       ON op.season       = g.season
      AND op.school_ncaa  = g.opponent_school_ncaa;
/* -----------------------------------------------------------
   NCAA MEN – Tournament games (2014-on) enriched with pace &
   efficiency metrics for both teams + team-vs-opponent diffs
   -----------------------------------------------------------
*/
WITH games_long AS (

  /* ---- 2014-17 historical tournament games reshaped to one
           row per team (label = win / loss)                  */
  SELECT
      season,
      'win'                       AS label,
      SAFE_CAST(win_seed  AS INT64)  AS seed,
      win_school_ncaa             AS school_ncaa,
      SAFE_CAST(lose_seed AS INT64) AS opponent_seed,
      lose_school_ncaa            AS opponent_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season BETWEEN 2014 AND 2017

  UNION ALL
  SELECT
      season,
      'loss',
      SAFE_CAST(lose_seed AS INT64),
      lose_school_ncaa,
      SAFE_CAST(win_seed  AS INT64),
      win_school_ncaa
  FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season BETWEEN 2014 AND 2017

  /* ---- 2018 results already in long format --------------- */
  UNION ALL
  SELECT
      season,
      label,
      SAFE_CAST(seed           AS INT64),
      school_ncaa,
      SAFE_CAST(opponent_seed  AS INT64),
      opponent_school_ncaa
  FROM  `data-to-insights.ncaa.2018_tournament_results`
)

SELECT
    g.season,
    g.label,                     -- win / loss
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

    /* ---------- opponent metrics ------ */
    op.pace_rank        AS opp_pace_rank,
    op.poss_40min       AS opp_poss_40min,
    op.pace_rating      AS opp_pace_rating,
    op.efficiency_rank  AS opp_efficiency_rank,
    op.pts_100poss      AS opp_pts_100poss,
    op.efficiency_rating AS opp_efficiency_rating,

    /* ---------- differences (opp – team) */
    (op.pace_rank        - tm.pace_rank)        AS pace_rank_diff,
    (op.poss_40min       - tm.poss_40min)       AS pace_stat_diff,
    (op.pace_rating      - tm.pace_rating)      AS pace_rating_diff,
    (op.efficiency_rank  - tm.efficiency_rank)  AS eff_rank_diff,
    (op.pts_100poss      - tm.pts_100poss)      AS eff_stat_diff,
    (op.efficiency_rating- tm.efficiency_rating)AS eff_rating_diff
FROM   games_long AS g
LEFT   JOIN `data-to-insights.ncaa.feature_engineering`  AS tm
       ON  tm.season = g.season
       AND tm.team   = g.school_ncaa
LEFT   JOIN `data-to-insights.ncaa.feature_engineering`  AS op
       ON  op.season = g.season
       AND op.team   = g.opponent_school_ncaa
ORDER  BY g.season, g.label DESC, g.school_ncaa
;
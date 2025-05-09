/*  NCAA men’s tournament analytic dataset – seasons 2014+
    ------------------------------------------------------
    • Combines historical tournament games (2014‑present) with the
      2018 per‑team results table.
    • Appends pace (tempo) and efficiency metrics for each team and its opponent.
    • Computes opponent‑minus‑team differences.
    • All numeric values kept to four‑decimal precision where applicable. */

WITH hist AS (
  SELECT
      season,
      'win' AS game_result,
      win_seed         AS team_seed,
      lose_seed        AS opponent_seed,
      win_school_ncaa  AS team_school,
      lose_school_ncaa AS opponent_school
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT
      season,
      'loss' AS game_result,
      lose_seed        AS team_seed,
      win_seed         AS opponent_seed,
      lose_school_ncaa AS team_school,
      win_school_ncaa  AS opponent_school
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

results_2018 AS (
  SELECT
      season,
      label                AS game_result,
      seed                 AS team_seed,
      opponent_seed,
      school_ncaa          AS team_school,
      opponent_school_ncaa AS opponent_school
  FROM `data-to-insights.ncaa.2018_tournament_results`
),

all_games AS (
  SELECT * FROM hist
  UNION ALL
  SELECT * FROM results_2018
)

SELECT
    g.season,
    g.game_result,
    g.team_seed,
    g.opponent_seed,
    g.team_school,
    g.opponent_school,

    /* tempo metrics */
    tm.pace_rank                    AS team_adj_tempo_rank,
    opp.pace_rank                   AS opp_adj_tempo_rank,
    ROUND(tm.pace_rating,4)         AS team_adj_tempo,
    ROUND(opp.pace_rating,4)        AS opp_adj_tempo,
    ROUND(opp.pace_rating - tm.pace_rating,4)            AS tempo_diff,

    /* offensive efficiency metrics */
    tm.efficiency_rank              AS team_adj_off_rank,
    opp.efficiency_rank             AS opp_adj_off_rank,
    ROUND(tm.efficiency_rating,4)   AS team_adj_off,
    ROUND(opp.efficiency_rating,4)  AS opp_adj_off,
    ROUND(opp.efficiency_rating - tm.efficiency_rating,4) AS adj_off_diff,

    /* defensive efficiency metrics (same proxy fields) */
    tm.efficiency_rank              AS team_adj_def_rank,
    opp.efficiency_rank             AS opp_adj_def_rank,
    ROUND(tm.efficiency_rating,4)   AS team_adj_def,
    ROUND(opp.efficiency_rating,4)  AS opp_adj_def,
    ROUND(opp.efficiency_rating - tm.efficiency_rating,4) AS adj_def_diff

FROM   all_games g
LEFT JOIN `data-to-insights.ncaa.feature_engineering` tm
       ON tm.season = g.season
      AND tm.team   = g.team_school
LEFT JOIN `data-to-insights.ncaa.feature_engineering` opp
       ON opp.season = g.season
      AND opp.team   = g.opponent_school;
/* ------------------------------------------------------------
   FINAL DATA‑SET : NCAA men’s tournament games 2014‑present
   – outcome for each team (win / loss)
   – team & opponent seeds / schools
   – pace & efficiency metrics (rank + two stats)
   – metric differences (opponent – team)
------------------------------------------------------------ */
WITH
/* 1️⃣  Expand historical tournament games (each game → 2 rows) */
hist_2014_on AS (
  SELECT season,
         'win'  AS game_result,
         win_seed        AS team_seed,
         win_school_ncaa AS team_school,
         lose_seed       AS opponent_seed,
         lose_school_ncaa AS opponent_school
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014

  UNION ALL

  SELECT season,
         'loss' AS game_result,
         lose_seed        AS team_seed,
         lose_school_ncaa AS team_school,
         win_seed         AS opponent_seed,
         win_school_ncaa  AS opponent_school
  FROM `data-to-insights.ncaa.mbb_historical_tournament_games`
  WHERE season >= 2014
),

/* 2️⃣  2018 results (already split into win / loss) */
games_2018 AS (
  SELECT season,
         label            AS game_result,
         seed             AS team_seed,
         school_ncaa      AS team_school,
         opponent_seed,
         opponent_school_ncaa AS opponent_school
  FROM `data-to-insights.ncaa.2018_tournament_results`
),

/* 3️⃣  Union all tournament rows 2014‑present */
tournament_games AS (
  SELECT * FROM hist_2014_on
  UNION ALL
  SELECT * FROM games_2018
),

/* 4️⃣  Join TEAM pace / efficiency metrics */
team_metrics AS (
  SELECT
      g.*,
      f.pace_rank         AS team_pace_rank,
      f.poss_40min        AS team_poss_40min,
      f.pace_rating       AS team_pace_rating,
      f.efficiency_rank   AS team_efficiency_rank,
      f.pts_100poss       AS team_pts_100poss,
      f.efficiency_rating AS team_efficiency_rating
  FROM tournament_games AS g
  LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS f
    ON f.season = g.season
   AND f.team   = g.team_school
)

/* 5️⃣  Join OPPONENT metrics & compute diffs */
SELECT
    t.season,
    t.game_result,
    t.team_seed,
    t.opponent_seed,
    t.team_school,
    t.opponent_school,

    /* ---- pace (tempo) ---- */
    t.team_pace_rank,
    o.pace_rank                       AS opp_pace_rank,
    (o.pace_rank - t.team_pace_rank)  AS pace_rank_diff,

    t.team_poss_40min,
    o.poss_40min                      AS opp_poss_40min,
    (o.poss_40min - t.team_poss_40min) AS poss_40min_diff,

    t.team_pace_rating,
    o.pace_rating                     AS opp_pace_rating,
    (o.pace_rating - t.team_pace_rating) AS pace_rating_diff,

    /* ---- efficiency ---- */
    t.team_efficiency_rank,
    o.efficiency_rank                 AS opp_efficiency_rank,
    (o.efficiency_rank - t.team_efficiency_rank) AS efficiency_rank_diff,

    t.team_pts_100poss,
    o.pts_100poss                     AS opp_pts_100poss,
    (o.pts_100poss - t.team_pts_100poss) AS pts_100poss_diff,

    t.team_efficiency_rating,
    o.efficiency_rating               AS opp_efficiency_rating,
    (o.efficiency_rating - t.team_efficiency_rating) AS efficiency_rating_diff
FROM team_metrics AS t
LEFT JOIN `data-to-insights.ncaa.feature_engineering` AS o
  ON o.season = t.season
 AND o.team   = t.opponent_school
ORDER BY t.season, t.team_school, t.game_result;
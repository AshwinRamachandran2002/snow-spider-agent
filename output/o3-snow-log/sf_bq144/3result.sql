/* =========================================================================
   NCAA ‑ Tournament games (2014-present) enriched with pace & efficiency
   ========================================================================= */
WITH "hist" AS (   -- 2014-present historical tournament games
    SELECT
        "season",
        'win'                 AS "label",
        "win_seed"            AS "seed",
        "win_school_ncaa"     AS "school_ncaa",
        "lose_seed"           AS "opponent_seed",
        "lose_school_ncaa"    AS "opponent_school_ncaa"
    FROM NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014

    UNION ALL

    SELECT
        "season",
        'loss'                AS "label",
        "lose_seed"           AS "seed",
        "lose_school_ncaa"    AS "school_ncaa",
        "win_seed"            AS "opponent_seed",
        "win_school_ncaa"     AS "opponent_school_ncaa"
    FROM NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014
),

"results18" AS (   -- 2018 play-in and main-bracket results (already labelled)
    SELECT
        "season",
        "label",
        "seed",
        "school_ncaa",
        "opponent_seed",
        "opponent_school_ncaa"
    FROM NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
    WHERE "season" >= 2014
),

/* -------------------------------------------------------------------------
   Union all tournament rows into one set
   ------------------------------------------------------------------------- */
"games" AS (
    SELECT * FROM "hist"
    UNION ALL
    SELECT * FROM "results18"
),

/* -------------------------------------------------------------------------
   Convenience view of pace / efficiency metrics
   ------------------------------------------------------------------------- */
"fe" AS (
    SELECT
        "season",
        "team",
        "pace_rank",
        "poss_40min",
        "pace_rating",
        "efficiency_rank",
        "pts_100poss",
        "efficiency_rating"
    FROM NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING
)

/* -------------------------------------------------------------------------
   Final dataset
   ------------------------------------------------------------------------- */
SELECT
    g."season",
    g."label",                     -- win / loss
    g."seed",
    g."school_ncaa",
    g."opponent_seed",
    g."opponent_school_ncaa",

    /* ---------------- Team metrics ---------------- */
    fe."pace_rank"           AS "pace_rank",
    fe."poss_40min"          AS "poss_40min",
    fe."pace_rating"         AS "pace_rating",
    fe."efficiency_rank"     AS "efficiency_rank",
    fe."pts_100poss"         AS "pts_100poss",
    fe."efficiency_rating"   AS "efficiency_rating",

    /* -------------- Opponent metrics -------------- */
    opp_fe."pace_rank"       AS "opp_pace_rank",
    opp_fe."poss_40min"      AS "opp_poss_40min",
    opp_fe."pace_rating"     AS "opp_pace_rating",
    opp_fe."efficiency_rank" AS "opp_efficiency_rank",
    opp_fe."pts_100poss"     AS "opp_pts_100poss",
    opp_fe."efficiency_rating" AS "opp_efficiency_rating",

    /* ------------- Metric-difference features ------------- */
    (opp_fe."pace_rank"        - fe."pace_rank")        AS "pace_rank_diff",
    (opp_fe."poss_40min"       - fe."poss_40min")       AS "poss_40min_diff",
    (opp_fe."pace_rating"      - fe."pace_rating")      AS "pace_rating_diff",
    (opp_fe."efficiency_rank"  - fe."efficiency_rank")  AS "eff_rank_diff",
    (opp_fe."pts_100poss"      - fe."pts_100poss")      AS "pts_100poss_diff",
    (opp_fe."efficiency_rating" - fe."efficiency_rating") AS "eff_rating_diff"

FROM "games" g
LEFT JOIN "fe"      fe      ON fe."season" = g."season"
                           AND fe."team"   = g."school_ncaa"
LEFT JOIN "fe"      opp_fe  ON opp_fe."season" = g."season"
                           AND opp_fe."team"   = g."opponent_school_ncaa"
ORDER BY g."season", g."school_ncaa", g."label";
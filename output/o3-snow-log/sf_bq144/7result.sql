/* =========================================================================
   NCAA men’s tournament games (2014-present) enriched with pace & efficiency
   metrics for both teams and their opponents
   ========================================================================= */
WITH
/* --------- 1.  Historical tournament games (2014+) ----------------------- */
hist AS (
    /* winners */
    SELECT
        h."season",
        'win'                                           AS "label",
        h."win_seed"        AS "seed",
        h."win_school_ncaa" AS "school_ncaa",
        h."lose_seed"       AS "opponent_seed",
        h."lose_school_ncaa"AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES h
    WHERE h."season" >= 2014

    UNION ALL

    /* losers */
    SELECT
        h."season",
        'loss'                                          AS "label",
        h."lose_seed"       AS "seed",
        h."lose_school_ncaa"AS "school_ncaa",
        h."win_seed"        AS "opponent_seed",
        h."win_school_ncaa" AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES h
    WHERE h."season" >= 2014
),

/* --------- 2.  2018 tournament results table ----------------------------- */
res18 AS (
    SELECT
        r."season",
        r."label",
        r."seed",
        r."school_ncaa"          AS "school_ncaa",
        r."opponent_seed",
        r."opponent_school_ncaa" AS "opponent_school_ncaa"
    FROM NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS r
),

/* --------- 3.  Combine game lists --------------------------------------- */
games AS (
    SELECT * FROM hist
    UNION ALL
    SELECT * FROM res18
),

/* --------- 4.  Join pace/efficiency metrics for teams & opponents -------- */
enriched AS (
    SELECT
        g."season",
        g."label",
        g."seed",
        g."school_ncaa",
        g."opponent_seed",
        g."opponent_school_ncaa",

        /* ------------------ team metrics ------------------ */
        t."pace_rank"          AS "pace_rank",
        t."poss_40min"         AS "poss_40min",
        t."pace_rating"        AS "pace_rating",
        t."efficiency_rank"    AS "efficiency_rank",
        t."pts_100poss"        AS "pts_100poss",
        t."efficiency_rating"  AS "efficiency_rating",

        /* ---------------- opponent metrics ---------------- */
        o."pace_rank"          AS "opp_pace_rank",
        o."poss_40min"         AS "opp_poss_40min",
        o."pace_rating"        AS "opp_pace_rating",
        o."efficiency_rank"    AS "opp_efficiency_rank",
        o."pts_100poss"        AS "opp_pts_100poss",
        o."efficiency_rating"  AS "opp_efficiency_rating",

        /* --------------- metric differentials ------------- */
        (o."pace_rank"        - t."pace_rank")         AS "pace_rank_diff",
        (o."poss_40min"       - t."poss_40min")        AS "poss_40min_diff",
        (o."pace_rating"      - t."pace_rating")       AS "pace_rating_diff",
        (o."efficiency_rank"  - t."efficiency_rank")   AS "eff_rank_diff",
        (o."pts_100poss"      - t."pts_100poss")       AS "pts_100poss_diff",
        (o."efficiency_rating"- t."efficiency_rating") AS "eff_rating_diff"
    FROM  games g
          /* team metrics */
          LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING t
                 ON  t."season" = g."season"
                 AND UPPER(t."team") = UPPER(g."school_ncaa")
          /* opponent metrics */
          LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING o
                 ON  o."season" = g."season"
                 AND UPPER(o."team") = UPPER(g."opponent_school_ncaa")
)

/* ----------------- 5.  Final ordered dataset ----------------------------- */
SELECT *
FROM   enriched
ORDER BY "season", "school_ncaa", "label", "opponent_school_ncaa";
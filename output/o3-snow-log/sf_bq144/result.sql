/* ===============================================================
   NCAA MEN'S TOURNAMENT (2014-PRESENT)
   – OUTCOMES WITH PACE / EFFICIENCY METRICS & DIFFERENCES
   ===============================================================*/

WITH tournament_games AS (

    /* ---------------- winners ---------------- */
    SELECT
        "season"                               AS season,
        'win'                                  AS label,
        "win_seed"                             AS seed,
        "win_school_ncaa"                      AS school_ncaa,
        "lose_seed"                            AS opponent_seed,
        "lose_school_ncaa"                     AS opponent_school_ncaa
    FROM NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014

    UNION ALL

    /* ---------------- losers ----------------- */
    SELECT
        "season"                               AS season,
        'loss'                                 AS label,
        "lose_seed"                            AS seed,
        "lose_school_ncaa"                     AS school_ncaa,
        "win_seed"                             AS opponent_seed,
        "win_school_ncaa"                      AS opponent_school_ncaa
    FROM NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE "season" >= 2014

    UNION ALL

    /* -------------- 2018 table --------------- */
    SELECT
        "season"                               AS season,
        "label"                                AS label,
        "seed"                                 AS seed,
        "school_ncaa"                          AS school_ncaa,
        "opponent_seed"                        AS opponent_seed,
        "opponent_school_ncaa"                 AS opponent_school_ncaa
    FROM NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
    WHERE "season" >= 2014
),

metrics AS (
    SELECT
        tg.*,

        /* ------------ team metrics ------------- */
        fe_t."pace_rank"            AS pace_rank,
        fe_t."poss_40min"           AS poss_40min,
        fe_t."pace_rating"          AS pace_rating,
        fe_t."efficiency_rank"      AS efficiency_rank,
        fe_t."pts_100poss"          AS pts_100poss,
        fe_t."efficiency_rating"    AS efficiency_rating,

        /* ---------- opponent metrics ----------- */
        fe_o."pace_rank"            AS opp_pace_rank,
        fe_o."poss_40min"           AS opp_poss_40min,
        fe_o."pace_rating"          AS opp_pace_rating,
        fe_o."efficiency_rank"      AS opp_efficiency_rank,
        fe_o."pts_100poss"          AS opp_pts_100poss,
        fe_o."efficiency_rating"    AS opp_efficiency_rating

    FROM tournament_games tg
    LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING fe_t
           ON fe_t."season" = tg.season
          AND UPPER(TRIM(fe_t."team")) = UPPER(TRIM(tg.school_ncaa))
    LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING fe_o
           ON fe_o."season" = tg.season
          AND UPPER(TRIM(fe_o."team")) = UPPER(TRIM(tg.opponent_school_ncaa))
)

SELECT
    season,
    label,
    seed,
    school_ncaa,
    opponent_seed,
    opponent_school_ncaa,

    /* -------- team values -------- */
    pace_rank,
    poss_40min,
    pace_rating,
    efficiency_rank,
    pts_100poss,
    efficiency_rating,

    /* ----- opponent values ------ */
    opp_pace_rank,
    opp_poss_40min,
    opp_pace_rating,
    opp_efficiency_rank,
    opp_pts_100poss,
    opp_efficiency_rating,

    /* --------- deltas (opp – team) ---------- */
    (opp_pace_rank        - pace_rank)        AS pace_rank_diff,
    (opp_poss_40min       - poss_40min)       AS poss_40min_diff,
    (opp_pace_rating      - pace_rating)      AS pace_rating_diff,
    (opp_efficiency_rank  - efficiency_rank)  AS efficiency_rank_diff,
    (opp_pts_100poss      - pts_100poss)      AS pts_100poss_diff,
    (opp_efficiency_rating - efficiency_rating) AS efficiency_rating_diff

FROM metrics
ORDER BY season, school_ncaa, label;
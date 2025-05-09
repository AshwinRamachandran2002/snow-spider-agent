WITH game_records AS (
    SELECT
        htg."season",
        'win' AS "label",
        CAST(LTRIM(htg."win_seed", '0') AS INTEGER) AS "seed",
        htg."win_school_ncaa" AS "school_ncaa",
        CAST(LTRIM(htg."lose_seed", '0') AS INTEGER) AS "opponent_seed",
        htg."lose_school_ncaa" AS "opponent_school_ncaa"
    FROM "NCAA_INSIGHTS"."NCAA"."MBB_HISTORICAL_TOURNAMENT_GAMES" htg
    WHERE htg."season" BETWEEN 2014 AND 2018

    UNION ALL

    SELECT
        htg."season",
        'loss' AS "label",
        CAST(LTRIM(htg."lose_seed", '0') AS INTEGER) AS "seed",
        htg."lose_school_ncaa" AS "school_ncaa",
        CAST(LTRIM(htg."win_seed", '0') AS INTEGER) AS "opponent_seed",
        htg."win_school_ncaa" AS "opponent_school_ncaa"
    FROM "NCAA_INSIGHTS"."NCAA"."MBB_HISTORICAL_TOURNAMENT_GAMES" htg
    WHERE htg."season" BETWEEN 2014 AND 2018
)

SELECT
    gr."season",
    gr."label",
    gr."seed",
    gr."school_ncaa",
    gr."opponent_seed",
    gr."opponent_school_ncaa",
    ROUND(fe_team."pace_rank", 4) AS "pace_rank",
    ROUND(fe_team."poss_40min", 4) AS "poss_40min",
    ROUND(fe_team."pace_rating", 4) AS "pace_rating",
    ROUND(fe_team."efficiency_rank", 4) AS "efficiency_rank",
    ROUND(fe_team."pts_100poss", 4) AS "pts_100poss",
    ROUND(fe_team."efficiency_rating", 4) AS "efficiency_rating",
    ROUND(fe_opp."pace_rank", 4) AS "opp_pace_rank",
    ROUND(fe_opp."poss_40min", 4) AS "opp_poss_40min",
    ROUND(fe_opp."pace_rating", 4) AS "opp_pace_rating",
    ROUND(fe_opp."efficiency_rank", 4) AS "opp_efficiency_rank",
    ROUND(fe_opp."pts_100poss", 4) AS "opp_pts_100poss",
    ROUND(fe_opp."efficiency_rating", 4) AS "opp_efficiency_rating",
    ROUND(fe_opp."pace_rank" - fe_team."pace_rank", 4) AS "pace_rank_diff",
    ROUND(fe_opp."poss_40min" - fe_team."poss_40min", 4) AS "pace_stat_diff",
    ROUND(fe_opp."pace_rating" - fe_team."pace_rating", 4) AS "pace_rating_diff",
    ROUND(fe_opp."efficiency_rank" - fe_team."efficiency_rank", 4) AS "eff_rank_diff",
    ROUND(fe_opp."pts_100poss" - fe_team."pts_100poss", 4) AS "eff_stat_diff",
    ROUND(fe_opp."efficiency_rating" - fe_team."efficiency_rating", 4) AS "eff_rating_diff"
FROM game_records gr
LEFT JOIN "NCAA_INSIGHTS"."NCAA"."FEATURE_ENGINEERING" fe_team
    ON REGEXP_REPLACE(LOWER(gr."school_ncaa"), '[^a-z]', '') = REGEXP_REPLACE(LOWER(fe_team."team"), '[^a-z]', '')
    AND gr."season" = fe_team."season"
LEFT JOIN "NCAA_INSIGHTS"."NCAA"."FEATURE_ENGINEERING" fe_opp
    ON REGEXP_REPLACE(LOWER(gr."opponent_school_ncaa"), '[^a-z]', '') = REGEXP_REPLACE(LOWER(fe_opp."team"), '[^a-z]', '')
    AND gr."season" = fe_opp."season";
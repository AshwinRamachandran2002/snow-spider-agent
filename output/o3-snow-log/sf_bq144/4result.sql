/* -------------------------------------------------------------------------
   NCAA Men’s Tournament Outcomes (2014-present) with Pace & Efficiency Data
   -------------------------------------------------------------------------
   • Combines historical tournament games (2014+) with the 2018 results file
   • Produces one record per team-game with a win / loss label
   • Adds season-level pace & efficiency metrics for both team and opponent
   • Calculates metric differences (team minus opponent)
---------------------------------------------------------------------------*/

WITH games AS (      -- 1.  Reshape tournament game results into one-row-per-team
    /* 1a.  Historical tournament games, 2014-present */
    SELECT
        htg."season",
        'win'                 AS "label",
        htg."win_seed"        AS "seed",
        htg."win_school_ncaa" AS "school_ncaa",
        htg."lose_seed"       AS "opponent_seed",
        htg."lose_school_ncaa"AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES htg
    WHERE htg."season" >= 2014

    UNION ALL

    SELECT
        htg."season",
        'loss'                AS "label",
        htg."lose_seed"       AS "seed",
        htg."lose_school_ncaa"AS "school_ncaa",
        htg."win_seed"        AS "opponent_seed",
        htg."win_school_ncaa" AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES htg
    WHERE htg."season" >= 2014

    /* 1b.  2018 tournament file (already one-row-per-team)  */
    UNION ALL
    SELECT
        tr."season",
        tr."label"            AS "label",
        tr."seed"             AS "seed",
        tr."school_ncaa"      AS "school_ncaa",
        tr."opponent_seed"    AS "opponent_seed",
        tr."opponent_school_ncaa" AS "opponent_school_ncaa"
    FROM  NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS tr
    WHERE tr."season" >= 2014
),

/* 2.  Join season-level pace / efficiency metrics for team and opponent */
joined AS (
    SELECT
        g."season",
        g."label",
        g."seed",
        g."school_ncaa",
        g."opponent_seed",
        g."opponent_school_ncaa",

        /* ----  team metrics  ---- */
        tfe."pace_rank"          AS "pace_rank",
        tfe."poss_40min"         AS "poss_40min",
        tfe."pace_rating"        AS "pace_rating",
        tfe."efficiency_rank"    AS "efficiency_rank",
        tfe."pts_100poss"        AS "pts_100poss",
        tfe."efficiency_rating"  AS "efficiency_rating",

        /* ----  opponent metrics  ---- */
        ofe."pace_rank"          AS "opp_pace_rank",
        ofe."poss_40min"         AS "opp_poss_40min",
        ofe."pace_rating"        AS "opp_pace_rating",
        ofe."efficiency_rank"    AS "opp_efficiency_rank",
        ofe."pts_100poss"        AS "opp_pts_100poss",
        ofe."efficiency_rating"  AS "opp_efficiency_rating"

    FROM       games g
    INNER JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING tfe
           ON  tfe."season" = g."season"
           AND tfe."team"   = g."school_ncaa"
    INNER JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING ofe
           ON  ofe."season" = g."season"
           AND ofe."team"   = g."opponent_school_ncaa"
)

/* 3.  Final select with metric differences */
SELECT
    "season",
    "label",
    "seed"                     AS "team_seed",
    "school_ncaa"              AS "team_school",
    "opponent_seed",
    "opponent_school_ncaa"     AS "opponent_school",

    /* --- team metrics --- */
    "pace_rank",
    "poss_40min",
    "pace_rating",
    "efficiency_rank",
    "pts_100poss",
    "efficiency_rating",

    /* --- opponent metrics --- */
    "opp_pace_rank",
    "opp_poss_40min",
    "opp_pace_rating",
    "opp_efficiency_rank",
    "opp_pts_100poss",
    "opp_efficiency_rating",

    /* --- differences (team – opponent) --- */
    ("pace_rank"        - "opp_pace_rank")        AS "pace_rank_diff",
    ("poss_40min"       - "opp_poss_40min")       AS "pace_stat_diff",
    ("pace_rating"      - "opp_pace_rating")      AS "pace_rating_diff",
    ("efficiency_rank"  - "opp_efficiency_rank")  AS "eff_rank_diff",
    ("pts_100poss"      - "opp_pts_100poss")      AS "eff_stat_diff",
    ("efficiency_rating"- "opp_efficiency_rating")AS "eff_rating_diff"

FROM   joined
ORDER  BY "season" ASC, "team_school" ASC;
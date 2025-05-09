/* =========================================================================
   Dataset:  NCAA MEN’S TOURNAMENT (2014–present)  │  Pace- & Efficiency-Based
   -------------------------------------------------------------------------
   • Includes one record per team-game (win or loss) beginning with 2014.
   • Sources
       – Historical tournament box ⇒  NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
       – 2018 tournament results    ⇒  NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
       – Team pace / efficiency     ⇒  NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING
   • Returned fields
       – Game context … season, label (win / loss), seed, opponent-seed, schools
       – Team & opponent pace / efficiency metrics
       – Metric differences (opponent minus team)
   ========================================================================= */
WITH tournament_games AS
(
    /* ----------  Historical bracket, winners ---------- */
    SELECT
        "season",
        'win'                                             AS "label",
        "win_seed"                                        AS "seed",
        "win_school_ncaa"                                 AS "school_ncaa",
        "lose_seed"                                       AS "opponent_seed",
        "lose_school_ncaa"                                AS "opponent_school_ncaa"
    FROM   NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE  "season" >= 2014

    UNION ALL

    /* ----------  Historical bracket, losers  ---------- */
    SELECT
        "season",
        'loss'                                            AS "label",
        "lose_seed"                                       AS "seed",
        "lose_school_ncaa"                                AS "school_ncaa",
        "win_seed"                                        AS "opponent_seed",
        "win_school_ncaa"                                 AS "opponent_school_ncaa"
    FROM   NCAA_INSIGHTS.NCAA.MBB_HISTORICAL_TOURNAMENT_GAMES
    WHERE  "season" >= 2014

    UNION ALL

    /* ----------  2018 play-in / main bracket ---------- */
    SELECT
        "season",
        "label",                                          /* already ‘win’ / ‘loss’ */
        "seed",
        "school_ncaa"                                     AS "school_ncaa",
        "opponent_seed",
        "opponent_school_ncaa"
    FROM   NCAA_INSIGHTS.NCAA._2018_TOURNAMENT_RESULTS
    WHERE  "season" >= 2014
),

/* ----------  Attach feature-engineering metrics ---------- */
team_metrics AS
(
    SELECT
        tg.*,

        /* -------- team  -------- */
        fe."pace_rank"            AS "pace_rank",
        fe."poss_40min"           AS "poss_40min",
        fe."pace_rating"          AS "pace_rating",
        fe."efficiency_rank"      AS "efficiency_rank",
        fe."pts_100poss"          AS "pts_100poss",
        fe."efficiency_rating"    AS "efficiency_rating",

        /* -------- opponent ------ */
        op."pace_rank"            AS "opp_pace_rank",
        op."poss_40min"           AS "opp_poss_40min",
        op."pace_rating"          AS "opp_pace_rating",
        op."efficiency_rank"      AS "opp_efficiency_rank",
        op."pts_100poss"          AS "opp_pts_100poss",
        op."efficiency_rating"    AS "opp_efficiency_rating"
    FROM   tournament_games tg
           /* join to team metrics */
           LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING fe
             ON  fe."season" = tg."season"
             AND UPPER(fe."team") = UPPER(tg."school_ncaa")

           /* join to opponent metrics */
           LEFT JOIN NCAA_INSIGHTS.NCAA.FEATURE_ENGINEERING op
             ON  op."season" = tg."season"
             AND UPPER(op."team") = UPPER(tg."opponent_school_ncaa")
)

/* ----------  Final projection with metric differences ---------- */
SELECT
    "season",
    "label",
    "seed",
    "school_ncaa",
    "opponent_seed",
    "opponent_school_ncaa",

    /* ----  team metrics  ---- */
    "pace_rank",
    "poss_40min",
    "pace_rating",
    "efficiency_rank",
    "pts_100poss",
    "efficiency_rating",

    /* ----  opponent metrics  ---- */
    "opp_pace_rank",
    "opp_poss_40min",
    "opp_pace_rating",
    "opp_efficiency_rank",
    "opp_pts_100poss",
    "opp_efficiency_rating",

    /* ----  differences (opponent – team) ---- */
    ("opp_pace_rank"       - "pace_rank")        AS "pace_rank_diff",
    ("opp_poss_40min"      - "poss_40min")       AS "poss_40min_diff",
    ("opp_pace_rating"     - "pace_rating")      AS "pace_rating_diff",
    ("opp_efficiency_rank" - "efficiency_rank")  AS "eff_rank_diff",
    ("opp_pts_100poss"     - "pts_100poss")      AS "pts_100poss_diff",
    ("opp_efficiency_rating" - "efficiency_rating") AS "eff_rating_diff"

FROM   team_metrics
ORDER  BY "season" DESC NULLS LAST,
          "school_ncaa",
          "label";
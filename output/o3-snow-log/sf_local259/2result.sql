/*  ****************   CAREER-WISE BATTING & BOWLING SUMMARY FOR EVERY PLAYER   **************** */
WITH player_base AS (      /* basic information */
    SELECT  p."player_id",
            p."player_name",
            p."batting_hand",
            p."bowling_skill"
    FROM    IPL.IPL."PLAYER" p
),

/* ---------------------------  MOST-FREQUENT ROLE  --------------------------- */
role_counts AS (
    SELECT  pm."player_id",
            pm."role",
            COUNT(*) AS role_cnt
    FROM    IPL.IPL."PLAYER_MATCH" pm
    GROUP BY pm."player_id", pm."role"
),
most_role AS (
    SELECT  "player_id",
            "role" AS most_frequent_role
    FROM   (
            SELECT  *,
                    ROW_NUMBER() OVER (PARTITION BY "player_id"
                                       ORDER BY role_cnt DESC, "role") AS rn
            FROM    role_counts
           )
    WHERE   rn = 1
),

/* ---------------------------  MATCHES PLAYED  --------------------------- */
matches_played AS (
    SELECT  "player_id",
            COUNT(DISTINCT "match_id") AS matches_played
    FROM    IPL.IPL."PLAYER_MATCH"
    GROUP BY "player_id"
),

/* ---------------------------  BALL-LEVEL JOIN (for runs)  --------------------------- */
batting_ball AS (
    SELECT  bb."match_id",
            bb."striker"        AS player_id,
            bs."runs_scored"    AS runs_scored
    FROM    IPL.IPL."BALL_BY_BALL"  bb
    JOIN    IPL.IPL."BATSMAN_SCORED" bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
           AND bb."innings_no" = bs."innings_no"
),

/* ---------------------------  BATTING – OVERALL  --------------------------- */
batting_overall AS (
    SELECT  player_id,
            SUM(runs_scored)     AS total_runs,
            COUNT(*)             AS balls_faced
    FROM    batting_ball
    GROUP BY player_id
),

/* ---------------------------  PER-MATCH RUNS  --------------------------- */
batting_per_match AS (
    SELECT  player_id,
            "match_id",
            SUM(runs_scored)     AS runs_in_match
    FROM    batting_ball
    GROUP BY player_id, "match_id"
),
batting_extra AS (
    SELECT  player_id,
            MAX(runs_in_match)                                                AS highest_score,
            SUM(CASE WHEN runs_in_match >=  30 THEN 1 ELSE 0 END)             AS matches_30_plus,
            SUM(CASE WHEN runs_in_match >=  50 THEN 1 ELSE 0 END)             AS matches_50_plus,
            SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)             AS matches_100_plus
    FROM    batting_per_match
    GROUP BY player_id
),

/* ---------------------------  DISMISSALS  --------------------------- */
dismissals AS (
    SELECT  wt."player_out" AS player_id,
            COUNT(*)        AS dismissals
    FROM    IPL.IPL."WICKET_TAKEN" wt
    GROUP BY wt."player_out"
),

/* ---------------------------  BOWLING – RUNS CONCEDED (ignore extras)  --------------------------- */
bowling_ball AS (
    SELECT  bb."bowler"      AS player_id,
            bb."match_id",
            bs."runs_scored" AS runs_scored
    FROM    IPL.IPL."BALL_BY_BALL"  bb
    JOIN    IPL.IPL."BATSMAN_SCORED" bs
           ON  bb."match_id"   = bs."match_id"
           AND bb."over_id"    = bs."over_id"
           AND bb."ball_id"    = bs."ball_id"
           AND bb."innings_no" = bs."innings_no"
),
bowling_overall AS (
    SELECT  player_id,
            SUM(runs_scored) AS runs_conceded,
            COUNT(*)         AS balls_bowled
    FROM    bowling_ball
    GROUP BY player_id
),

/* ---------------------------  WICKETS TAKEN  --------------------------- */
wickets_total AS (
    SELECT  bb."bowler" AS player_id,
            COUNT(*)    AS wickets_taken
    FROM    IPL.IPL."WICKET_TAKEN" wt
    JOIN    IPL.IPL."BALL_BY_BALL" bb
           ON  wt."match_id"   = bb."match_id"
           AND wt."over_id"    = bb."over_id"
           AND wt."ball_id"    = bb."ball_id"
           AND wt."innings_no" = bb."innings_no"
    GROUP BY bb."bowler"
),

/* ---------------------------  BEST BOWLING FIGURES (per match)  --------------------------- */
wickets_per_match AS (
    SELECT  bb."bowler" AS player_id,
            bb."match_id",
            COUNT(*)    AS wickets
    FROM    IPL.IPL."WICKET_TAKEN" wt
    JOIN    IPL.IPL."BALL_BY_BALL" bb
           ON  wt."match_id"   = bb."match_id"
           AND wt."over_id"    = bb."over_id"
           AND wt."ball_id"    = bb."ball_id"
           AND wt."innings_no" = bb."innings_no"
    GROUP BY bb."bowler", bb."match_id"
),
runs_conceded_per_match AS (
    SELECT  player_id,
            "match_id",
            SUM(runs_scored) AS runs_given
    FROM    bowling_ball
    GROUP BY player_id, "match_id"
),
bowling_per_match AS (
    SELECT  w.player_id,
            w."match_id",
            w.wickets,
            COALESCE(r.runs_given, 0) AS runs_given
    FROM    wickets_per_match w
    LEFT JOIN runs_conceded_per_match r
           ON  w.player_id = r.player_id
           AND w."match_id" = r."match_id"
),
best_bowling AS (
    SELECT  player_id,
            wickets,
            runs_given,
            CAST(wickets AS STRING) || '-' || CAST(runs_given AS STRING)   AS best_bowling_figures
    FROM   (
            SELECT  *,
                    ROW_NUMBER() OVER (PARTITION BY player_id
                                       ORDER BY wickets DESC, runs_given ASC) AS rn
            FROM    bowling_per_match
           )
    WHERE   rn = 1
)

/* =========================================================================== */
/* ===============================   FINAL OUTPUT   =========================== */
/* =========================================================================== */
SELECT  pb."player_id",
        pb."player_name",
        mr.most_frequent_role                                   AS "most_frequent_role",
        pb."batting_hand",
        pb."bowling_skill",
        bo.total_runs,
        mp.matches_played,
        d.dismissals,
        /* Batting Average */
        CASE
             WHEN d.dismissals IS NULL OR d.dismissals = 0
             THEN NULL
             ELSE ROUND(bo.total_runs::FLOAT / d.dismissals, 4)
        END                                                    AS batting_average,
        be.highest_score,
        be.matches_30_plus,
        be.matches_50_plus,
        be.matches_100_plus,
        bo.balls_faced,
        /* Strike Rate */
        CASE
             WHEN bo.balls_faced IS NULL OR bo.balls_faced = 0
             THEN NULL
             ELSE ROUND((bo.total_runs::FLOAT / bo.balls_faced) * 100, 4)
        END                                                    AS strike_rate,
        wt.wickets_taken,
        /* Economy Rate */
        CASE
             WHEN bl.balls_bowled IS NULL OR bl.balls_bowled = 0
             THEN NULL
             ELSE ROUND((bl.runs_conceded::FLOAT / bl.balls_bowled) * 6, 4)
        END                                                    AS economy_rate,
        bb.best_bowling_figures
FROM        player_base     pb
LEFT JOIN   most_role       mr  ON pb."player_id" = mr."player_id"
LEFT JOIN   batting_overall bo  ON pb."player_id" = bo.player_id
LEFT JOIN   matches_played  mp  ON pb."player_id" = mp."player_id"
LEFT JOIN   dismissals      d   ON pb."player_id" = d.player_id
LEFT JOIN   batting_extra   be  ON pb."player_id" = be.player_id
LEFT JOIN   wickets_total   wt  ON pb."player_id" = wt.player_id
LEFT JOIN   bowling_overall bl  ON pb."player_id" = bl.player_id
LEFT JOIN   best_bowling    bb  ON pb."player_id" = bb.player_id
ORDER BY    bo.total_runs DESC NULLS LAST,
            pb."player_id";
/* ===============================================================
   COMPLETE CAREER SUMMARY – ONE ROW PER PLAYER
   =============================================================== */
WITH
/* 1.  Most-frequent role (mode) -------------------------------- */
role_mode AS (
    SELECT  "player_id",
            "role"
    FROM   (
            SELECT  "player_id",
                    "role",
                    ROW_NUMBER() OVER (PARTITION BY "player_id"
                                       ORDER BY COUNT(*) DESC , "role") AS rn
            FROM    IPL.IPL.PLAYER_MATCH
            GROUP   BY "player_id","role"
           )
    WHERE   rn = 1
),

/* 2.  Matches played ------------------------------------------- */
matches_played AS (
    SELECT  "player_id",
            COUNT(DISTINCT "match_id") AS total_matches
    FROM    IPL.IPL.PLAYER_MATCH
    GROUP   BY "player_id"
),

/* 3.  Batting – career totals ---------------------------------- */
batting_totals AS (
    SELECT  bb."striker"                         AS player_id,
            SUM(bs."runs_scored")                AS total_runs,
            COUNT(*)                             AS balls_faced
    FROM        IPL.IPL.BATSMAN_SCORED   bs
    JOIN        IPL.IPL.BALL_BY_BALL     bb
           ON   bb."match_id"   = bs."match_id"
          AND   bb."innings_no" = bs."innings_no"
          AND   bb."over_id"    = bs."over_id"
          AND   bb."ball_id"    = bs."ball_id"
    GROUP  BY bb."striker"
),

/* 4.  Dismissals ----------------------------------------------- */
dismissals AS (
    SELECT  "player_out" AS player_id,
            COUNT(*)     AS dismissals
    FROM    IPL.IPL.WICKET_TAKEN
    GROUP   BY "player_out"
),

/* 5.  Batting – per-match figures ------------------------------ */
batting_per_match AS (
    SELECT  bb."striker"                     AS player_id,
            bs."match_id"                    AS match_id,
            SUM(bs."runs_scored")            AS runs_in_match
    FROM        IPL.IPL.BATSMAN_SCORED   bs
    JOIN        IPL.IPL.BALL_BY_BALL     bb
           ON   bb."match_id"   = bs."match_id"
          AND   bb."innings_no" = bs."innings_no"
          AND   bb."over_id"    = bs."over_id"
          AND   bb."ball_id"    = bs."ball_id"
    GROUP  BY bb."striker", bs."match_id"
),
batting_match_aggr AS (
    SELECT  player_id,
            MAX(runs_in_match)                                         AS highest_score,
            COUNT_IF(runs_in_match >= 30)                              AS matches_30plus,
            COUNT_IF(runs_in_match >= 50)                              AS matches_50plus,
            COUNT_IF(runs_in_match >=100)                              AS matches_100plus
    FROM    batting_per_match
    GROUP   BY player_id
),

/* 6.  Bowling – runs conceded & balls bowled -------------------- */
bowling_runs AS (
    SELECT  bb."bowler"                     AS player_id,
            SUM(bs."runs_scored")           AS runs_conceded,
            COUNT(*)                        AS balls_bowled
    FROM        IPL.IPL.BATSMAN_SCORED   bs
    JOIN        IPL.IPL.BALL_BY_BALL     bb
           ON   bb."match_id"   = bs."match_id"
          AND   bb."innings_no" = bs."innings_no"
          AND   bb."over_id"    = bs."over_id"
          AND   bb."ball_id"    = bs."ball_id"
    GROUP  BY bb."bowler"
),

/* 7.  Bowling – wickets taken ----------------------------------- */
bowling_wkts AS (
    SELECT  bb."bowler"     AS player_id,
            COUNT(*)        AS wickets
    FROM        IPL.IPL.WICKET_TAKEN  wt
    JOIN        IPL.IPL.BALL_BY_BALL  bb
           ON   bb."match_id"   = wt."match_id"
          AND   bb."innings_no" = wt."innings_no"
          AND   bb."over_id"    = wt."over_id"
          AND   bb."ball_id"    = wt."ball_id"
    GROUP  BY bb."bowler"
),

/* 8.  Bowling – best figures in a single match ------------------ */
bowling_match_stats AS (
    /* Runs conceded per (bowler, match) */
    SELECT  r.player_id,
            r.match_id,
            COALESCE(w.wickets,0)      AS wickets,
            r.runs_conceded
    FROM   (
            SELECT  bb."bowler"            AS player_id,
                    bs."match_id"          AS match_id,
                    SUM(bs."runs_scored")  AS runs_conceded
            FROM        IPL.IPL.BATSMAN_SCORED   bs
            JOIN        IPL.IPL.BALL_BY_BALL     bb
                   ON   bb."match_id"   = bs."match_id"
                  AND   bb."innings_no" = bs."innings_no"
                  AND   bb."over_id"    = bs."over_id"
                  AND   bb."ball_id"    = bs."ball_id"
            GROUP  BY bb."bowler", bs."match_id"
           ) r
    LEFT JOIN (
            SELECT  bb."bowler"           AS player_id,
                    wt."match_id"         AS match_id,
                    COUNT(*)              AS wickets
            FROM        IPL.IPL.WICKET_TAKEN  wt
            JOIN        IPL.IPL.BALL_BY_BALL  bb
                   ON   bb."match_id"   = wt."match_id"
                  AND   bb."innings_no" = wt."innings_no"
                  AND   bb."over_id"    = wt."over_id"
                  AND   bb."ball_id"    = wt."ball_id"
            GROUP  BY bb."bowler", wt."match_id"
           ) w
      ON  r.player_id = w.player_id
     AND  r.match_id  = w.match_id
),
best_bowling AS (
    SELECT  player_id,
            CONCAT(wickets,'-',runs_conceded) AS best_bowling
    FROM   (
            SELECT  player_id,
                    wickets,
                    runs_conceded,
                    ROW_NUMBER() OVER (PARTITION BY player_id
                                       ORDER BY wickets DESC , runs_conceded ASC) AS rn
            FROM    bowling_match_stats
           )
    WHERE   rn = 1
)

/* =================================================================
   FINAL OUTPUT
   ================================================================= */
SELECT
        p."player_id"                                                        AS player_id,
        p."player_name"                                                      AS player_name,
        rm."role"                                                            AS most_frequent_role,
        p."batting_hand",
        p."bowling_skill",

        /* Batting */
        COALESCE(bt.total_runs,0)                                            AS total_runs_scored,
        COALESCE(mp.total_matches,0)                                         AS total_matches_played,
        COALESCE(d.dismissals,0)                                             AS total_dismissals,
        CASE WHEN COALESCE(d.dismissals,0)=0 THEN NULL
             ELSE ROUND(bt.total_runs / d.dismissals,4) END                  AS batting_average,
        bma.highest_score,
        bma.matches_30plus,
        bma.matches_50plus,
        bma.matches_100plus,
        COALESCE(bt.balls_faced,0)                                           AS balls_faced,
        CASE WHEN COALESCE(bt.balls_faced,0)=0 THEN NULL
             ELSE ROUND((bt.total_runs / bt.balls_faced)*100 ,4) END         AS strike_rate,

        /* Bowling */
        COALESCE(wk.wickets,0)                                               AS total_wickets_taken,
        CASE WHEN COALESCE(br.balls_bowled,0)=0 THEN NULL
             ELSE ROUND((br.runs_conceded / br.balls_bowled)*6 ,4) END       AS economy_rate,
        bb.best_bowling                                                      AS best_bowling_performance

FROM        IPL.IPL.PLAYER                         p
LEFT JOIN   role_mode                              rm  ON p."player_id" = rm."player_id"
LEFT JOIN   matches_played                         mp  ON p."player_id" = mp."player_id"
LEFT JOIN   batting_totals                         bt  ON p."player_id" = bt.player_id
LEFT JOIN   dismissals                             d   ON p."player_id" = d.player_id
LEFT JOIN   batting_match_aggr                     bma ON p."player_id" = bma.player_id
LEFT JOIN   bowling_runs                           br  ON p."player_id" = br.player_id
LEFT JOIN   bowling_wkts                           wk  ON p."player_id" = wk.player_id
LEFT JOIN   best_bowling                           bb  ON p."player_id" = bb.player_id

ORDER BY    p."player_id";
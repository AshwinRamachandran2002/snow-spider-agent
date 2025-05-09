/* ------------------------------------------------------------------
   Highest-run batting partnerships of every IPL match
   ------------------------------------------------------------------ */
WITH ball_data AS (          /* every legal delivery with the runs it produced */
    SELECT
        b."match_id"               AS match_id,
        b."innings_no"             AS innings_no,
        b."over_id"                AS over_id,
        b."ball_id"                AS ball_id,
        b."striker"                AS striker,
        b."non_striker"            AS non_striker,
        COALESCE(bs."runs_scored",0)              AS runs_scored,

        /* was either current batter dismissed on this ball? */
        CASE
             WHEN EXISTS ( SELECT 1
                           FROM IPL.IPL.WICKET_TAKEN w
                           WHERE w."match_id"  = b."match_id"
                             AND w."innings_no" = b."innings_no"
                             AND w."over_id"    = b."over_id"
                             AND w."ball_id"    = b."ball_id"
                             AND w."player_out" IN (b."striker",b."non_striker") )
             THEN 1 ELSE 0
        END                                        AS wicket_flag
    FROM IPL.IPL.BALL_BY_BALL            b
    LEFT JOIN IPL.IPL.BATSMAN_SCORED     bs
           ON  bs."match_id"   = b."match_id"
           AND bs."innings_no" = b."innings_no"
           AND bs."over_id"    = b."over_id"
           AND bs."ball_id"    = b."ball_id"
),

/* partnership_id changes on the ball *after* a wicket occurs            */
partnership_seq AS (
    SELECT  *,
            SUM(CASE WHEN wicket_flag = 1 THEN 1 ELSE 0 END)
                OVER (PARTITION BY match_id, innings_no
                      ORDER BY over_id, ball_id
                      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)  AS partnership_id
    FROM ball_data
),

/* total runs scored by every batter inside a partnership                */
player_runs AS (
    SELECT  match_id,
            innings_no,
            partnership_id,
            striker       AS player_id,
            SUM(runs_scored) AS runs
    FROM partnership_seq
    GROUP BY match_id, innings_no, partnership_id, striker
),

/* bring the two batters of a partnership onto one row                   */
partners AS (
    SELECT  pr1.match_id,
            pr1.partnership_id,
            pr1.player_id        AS player1_raw,
            pr1.runs             AS runs1_raw,
            pr2.player_id        AS player2_raw,
            pr2.runs             AS runs2_raw,
            pr1.runs + pr2.runs  AS partnership_total
    FROM   player_runs pr1
    JOIN   player_runs pr2
           ON  pr1.match_id       = pr2.match_id
           AND pr1.innings_no     = pr2.innings_no
           AND pr1.partnership_id = pr2.partnership_id
           AND pr1.player_id      < pr2.player_id         /* one row per pair */
),

/* reorder players : higher individual score first; if tie, higher id first */
ordered_partners AS (
    SELECT
        match_id,

        CASE
            WHEN runs1_raw > runs2_raw                                   THEN player1_raw
            WHEN runs2_raw > runs1_raw                                   THEN player2_raw
            WHEN runs1_raw = runs2_raw AND player1_raw > player2_raw     THEN player1_raw
            ELSE                                                              player2_raw
        END  AS player1_id,

        CASE
            WHEN runs1_raw > runs2_raw                                   THEN runs1_raw
            WHEN runs2_raw > runs1_raw                                   THEN runs2_raw
            WHEN runs1_raw = runs2_raw AND player1_raw > player2_raw     THEN runs1_raw
            ELSE                                                              runs2_raw
        END  AS player1_runs,

        CASE
            WHEN runs1_raw > runs2_raw                                   THEN player2_raw
            WHEN runs2_raw > runs1_raw                                   THEN player1_raw
            WHEN runs1_raw = runs2_raw AND player1_raw > player2_raw     THEN player2_raw
            ELSE                                                              player1_raw
        END  AS player2_id,

        CASE
            WHEN runs1_raw > runs2_raw                                   THEN runs2_raw
            WHEN runs2_raw > runs1_raw                                   THEN runs1_raw
            WHEN runs1_raw = runs2_raw AND player1_raw > player2_raw     THEN runs2_raw
            ELSE                                                              runs1_raw
        END  AS player2_runs,

        partnership_total
    FROM partners
),

/* highest-run partnership(s) of every match                              */
max_partners AS (
    SELECT  op.*,
            MAX(partnership_total) OVER (PARTITION BY match_id) AS max_total
    FROM    ordered_partners op
)

SELECT  match_id            AS "MATCH_ID",
        player1_id          AS "PLAYER1_ID",
        player1_runs        AS "PLAYER1_RUNS",
        player2_id          AS "PLAYER2_ID",
        player2_runs        AS "PLAYER2_RUNS",
        partnership_total   AS "PARTNERSHIP_RUNS"
FROM    max_partners
WHERE   partnership_total = max_total          /* only the biggest for each match */
ORDER BY match_id,
         player1_id,
         player2_id;
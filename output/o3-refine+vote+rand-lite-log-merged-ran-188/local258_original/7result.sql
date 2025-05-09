WITH
/*------------------------------------------------------------------
Every delivery bowled by every bowler.  
 – runs_off_bat : only runs that came from the bat  
 – legal_ball   : 1 if it is a legal delivery (not a wide/no‑ball),
                  0 otherwise – this is used to work out overs bowled
------------------------------------------------------------------*/
ball_runs AS (
    SELECT
        bb.match_id,
        bb.over_id,
        bb.ball_id,
        bb.innings_no,
        bb.bowler,
        COALESCE(bs.runs_scored,0)                                                       AS runs_off_bat,
        CASE
             WHEN LOWER(er.extra_type) IN ('wides','noballs') THEN 0
             ELSE 1
        END                                                                               AS legal_ball
    FROM ball_by_ball            AS bb
    LEFT JOIN batsman_scored     AS bs
           ON  bs.match_id   = bb.match_id
           AND bs.over_id    = bb.over_id
           AND bs.ball_id    = bb.ball_id
           AND bs.innings_no = bb.innings_no
    /* only interested in knowing if the delivery was a wide / no‑ball */
    LEFT JOIN extra_runs         AS er
           ON  er.match_id   = bb.match_id
           AND er.over_id    = bb.over_id
           AND er.ball_id    = bb.ball_id
           AND er.innings_no = bb.innings_no
           AND LOWER(er.extra_type) IN ('wides','noballs')
),
/*------------------------------------------------------------------
Wickets that are credited to the bowler (run‑outs etc. removed)
------------------------------------------------------------------*/
wickets AS (
    SELECT
        bb.bowler,
        wt.match_id,
        wt.over_id,
        wt.ball_id,
        wt.innings_no
    FROM wicket_taken        AS wt
    JOIN ball_by_ball        AS bb
         ON  bb.match_id   = wt.match_id
         AND bb.over_id    = wt.over_id
         AND bb.ball_id    = wt.ball_id
         AND bb.innings_no = wt.innings_no
    WHERE LOWER(wt.kind_out) NOT IN ('run out')            -- dismissals NOT credited are excluded
),
/*------------------------------------------------------------------
Figures for every bowler in every single match
------------------------------------------------------------------*/
per_match AS (
    SELECT
        br.bowler,
        br.match_id,
        SUM(br.legal_ball)                                                    AS balls_bowled,   -- legal balls only
        SUM(br.runs_off_bat)                                                  AS runs_conceded,  -- no extras
        SUM(CASE WHEN w.bowler IS NOT NULL THEN 1 ELSE 0 END)                 AS wickets_taken
    FROM ball_runs AS br
    LEFT JOIN wickets  AS w
           ON  w.bowler     = br.bowler
           AND w.match_id   = br.match_id
           AND w.over_id    = br.over_id
           AND w.ball_id    = br.ball_id
           AND w.innings_no = br.innings_no
    GROUP BY br.bowler, br.match_id
),
/*------------------------------------------------------------------
Career aggregates for every bowler
------------------------------------------------------------------*/
career AS (
    SELECT
        bowler,
        SUM(wickets_taken)                                                    AS total_wickets,
        SUM(runs_conceded)                                                    AS total_runs,
        SUM(balls_bowled)                                                     AS total_balls,
        ROUND(SUM(runs_conceded) * 6.0 / NULLIF(SUM(balls_bowled),0), 4)      AS economy_rate,
        ROUND(1.0 * SUM(balls_bowled) / NULLIF(SUM(wickets_taken),0), 4)      AS strike_rate
    FROM per_match
    GROUP BY bowler
),
/*------------------------------------------------------------------
Best bowling performance (most wickets, then least runs)
------------------------------------------------------------------*/
best_perf AS (
    SELECT
        bowler,
        wickets_taken,
        runs_conceded,
        ROW_NUMBER() OVER (PARTITION BY bowler
                           ORDER BY wickets_taken DESC, runs_conceded ASC)    AS rn
    FROM per_match
),
best AS (
    SELECT
        bowler,
        wickets_taken || '-' || runs_conceded                                 AS best_bowling
    FROM best_perf
    WHERE rn = 1
)
/*------------------------------------------------------------------
Final result
------------------------------------------------------------------*/
SELECT
    p.player_name      AS bowler_name,
    c.total_wickets,
    c.economy_rate,
    c.strike_rate,
    b.best_bowling
FROM career  AS c
JOIN best    AS b  ON b.bowler = c.bowler
JOIN player  AS p  ON p.player_id = c.bowler
ORDER BY c.total_wickets DESC, p.player_name;
WITH legal_balls AS (
    /* all legitimate balls – wides & no-balls are NOT counted */
    SELECT
        bb.bowler,
        COUNT(*)                AS legal_balls
    FROM   ball_by_ball  bb
    LEFT JOIN extra_runs  er
           ON  er.match_id   = bb.match_id
          AND er.over_id    = bb.over_id
          AND er.ball_id    = bb.ball_id
          AND er.innings_no = bb.innings_no
          AND er.extra_type IN ('wides' , 'noballs')
    WHERE  er.extra_type IS NULL
    GROUP BY bb.bowler
),
runs_conceded AS (
    /* runs that came off the bat only */
    SELECT
        bb.bowler,
        SUM(bs.runs_scored)     AS runs_conceded
    FROM   ball_by_ball   bb
    JOIN   batsman_scored bs
           ON  bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
    GROUP BY bb.bowler
),
wickets_total AS (
    /* total wickets that are credited to the bowler */
    SELECT
        bb.bowler,
        COUNT(*)                AS total_wickets
    FROM   wicket_taken  wt
    JOIN   ball_by_ball  bb
           ON  wt.match_id   = bb.match_id
          AND wt.over_id    = bb.over_id
          AND wt.ball_id    = bb.ball_id
          AND wt.innings_no = bb.innings_no
    WHERE  wt.kind_out NOT IN ('run out','retired hurt','obstructing the field')
    GROUP BY bb.bowler
),
/* ----------   figures on a match-by-match basis   ---------- */
wickets_per_match AS (
    SELECT
        bb.bowler,
        wt.match_id,
        COUNT(*)                AS wkts_in_match
    FROM   wicket_taken wt
    JOIN   ball_by_ball bb
           ON  wt.match_id   = bb.match_id
          AND wt.over_id    = bb.over_id
          AND wt.ball_id    = bb.ball_id
          AND wt.innings_no = bb.innings_no
    WHERE  wt.kind_out NOT IN ('run out','retired hurt','obstructing the field')
    GROUP BY bb.bowler , wt.match_id
),
runs_per_match AS (
    SELECT
        bb.bowler,
        bb.match_id,
        SUM(bs.runs_scored)     AS runs_in_match
    FROM   ball_by_ball   bb
    JOIN   batsman_scored bs
           ON  bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
    GROUP BY bb.bowler , bb.match_id
),
per_match AS (
    /* merge the two previous CTEs */
    SELECT
        rp.bowler,
        rp.match_id,
        COALESCE(wp.wkts_in_match,0) AS wkts_in_match,
        rp.runs_in_match
    FROM   runs_per_match    rp
    LEFT  JOIN wickets_per_match wp
           ON  wp.bowler   = rp.bowler
          AND wp.match_id  = rp.match_id
),
best_match AS (
    /* pick the bowler’s best haul – most wickets, then least runs */
    SELECT bowler,
           printf('%d-%d', wkts_in_match , runs_in_match) AS best_bowling
    FROM (
        SELECT
            pm.*,
            ROW_NUMBER() OVER (PARTITION BY bowler
                               ORDER BY wkts_in_match DESC,
                                        runs_in_match ASC) AS rn
        FROM   per_match pm
    )
    WHERE rn = 1
)
/* ----------   final output   ---------- */
SELECT
    lb.bowler                         AS bowler_id,
    wt.total_wickets                  AS total_wickets,
    ROUND(rc.runs_conceded * 6.0 / lb.legal_balls , 4) AS economy_rate,
    ROUND(lb.legal_balls  * 1.0 / wt.total_wickets, 4) AS strike_rate,
    bm.best_bowling
FROM   legal_balls   lb
JOIN   runs_conceded rc  ON rc.bowler = lb.bowler
JOIN   wickets_total wt  ON wt.bowler = lb.bowler
JOIN   best_match    bm  ON bm.bowler = lb.bowler
ORDER BY wt.total_wickets DESC,
         economy_rate          ASC;
WITH
/*------------------------------------------------------------------
1.  Runs scored on every single ball (batsmen + extras)
------------------------------------------------------------------*/
per_ball AS (
    SELECT
        b.match_id,
        b.innings_no,
        b.over_id,
        b.ball_id,
        COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0)   AS runs_in_ball
    FROM ball_by_ball          AS b
    LEFT JOIN batsman_scored   AS bs
           ON bs.match_id  = b.match_id
          AND bs.innings_no = b.innings_no
          AND bs.over_id   = b.over_id
          AND bs.ball_id   = b.ball_id
    LEFT JOIN extra_runs       AS er
           ON er.match_id  = b.match_id
          AND er.innings_no = b.innings_no
          AND er.over_id   = b.over_id
          AND er.ball_id   = b.ball_id
),
/*------------------------------------------------------------------
2.  Total runs collected in every over of every innings
------------------------------------------------------------------*/
over_total AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        SUM(runs_in_ball) AS total_runs
    FROM per_ball
    GROUP BY match_id, innings_no, over_id
),
/*------------------------------------------------------------------
3.  Identify the bowler who started (first ball of) each over
------------------------------------------------------------------*/
over_bowler AS (
    SELECT
        match_id,
        innings_no,
        over_id,
        bowler_id
    FROM (
        SELECT
            match_id,
            innings_no,
            over_id,
            bowler                    AS bowler_id,
            ROW_NUMBER() OVER (PARTITION BY match_id, innings_no, over_id
                               ORDER BY ball_id) AS rn
        FROM ball_by_ball
    )
    WHERE rn = 1
),
/*------------------------------------------------------------------
4.  Merge runs & bowler information per over
------------------------------------------------------------------*/
over_details AS (
    SELECT
        o.match_id,
        o.innings_no,
        o.over_id,
        o.total_runs,
        ob.bowler_id
    FROM over_total  AS o
    JOIN over_bowler AS ob
      ON  ob.match_id   = o.match_id
     AND ob.innings_no  = o.innings_no
     AND ob.over_id     = o.over_id
),
/*------------------------------------------------------------------
5.  Pick the single highest‑scoring over in every match
    (if tied, earliest innings/over is kept)
------------------------------------------------------------------*/
highest_over_per_match AS (
    SELECT *
    FROM (
        SELECT
            od.*,
            ROW_NUMBER() OVER (PARTITION BY match_id
                               ORDER BY total_runs DESC,
                                        innings_no,
                                        over_id) AS rn
        FROM over_details od
    )
    WHERE rn = 1
)
/*------------------------------------------------------------------
6.  Final output: details for each match’s top over together with
   the overall average of those over‑totals
------------------------------------------------------------------*/
SELECT
    h.match_id,
    h.innings_no,
    h.over_id,
    h.total_runs                     AS highest_over_runs,
    h.bowler_id,
    p.player_name                    AS bowler_name,
    ROUND(AVG(h.total_runs) OVER (), 4) AS avg_highest_over_runs
FROM highest_over_per_match h
LEFT JOIN player p
       ON p.player_id = h.bowler_id
ORDER BY h.match_id;
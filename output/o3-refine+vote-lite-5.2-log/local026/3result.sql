WITH over_runs AS (
    /* Runs conceded by each bowler in every over of every match              */
    SELECT
        b.match_id,
        b.innings_no,
        b.over_id,
        b.bowler,                        -- player_id of the bowler
        SUM(bs.runs_scored
            + COALESCE(er.extra_runs,0)) AS runs_conceded
    FROM ball_by_ball      b
    JOIN batsman_scored    bs
         ON  b.match_id   = bs.match_id
         AND b.over_id    = bs.over_id
         AND b.ball_id    = bs.ball_id
         AND b.innings_no = bs.innings_no
    LEFT JOIN extra_runs   er
         ON  b.match_id   = er.match_id
         AND b.over_id    = er.over_id
         AND b.ball_id    = er.ball_id
         AND b.innings_no = er.innings_no
    GROUP BY b.match_id, b.innings_no, b.over_id, b.bowler
),
match_max AS (
    /* Highest‑run over (irrespective of bowler) in every match               */
    SELECT
        match_id,
        MAX(runs_conceded) AS max_runs_in_match
    FROM over_runs
    GROUP BY match_id
),
overs_with_max AS (
    /* Only those overs that are the most expensive in their respective match */
    SELECT
        o.match_id,
        o.bowler,
        o.runs_conceded
    FROM over_runs o
    JOIN match_max m
          ON  o.match_id      = m.match_id
          AND o.runs_conceded = m.max_runs_in_match
),
bowler_worst AS (
    /* For each bowler, keep the single worst (highest runs) such over        */
    SELECT
        bowler,
        match_id,
        runs_conceded,
        ROW_NUMBER() OVER (PARTITION BY bowler 
                           ORDER BY runs_conceded DESC, match_id) AS rn
    FROM overs_with_max
),
top_bowlers AS (
    /* Pick that single worst over per bowler                                 */
    SELECT bowler,
           match_id,
           runs_conceded
    FROM bowler_worst
    WHERE rn = 1
    ORDER BY runs_conceded DESC, bowler
    LIMIT 3                                -- top‑3 bowlers overall
)
SELECT
    p.player_name  AS bowler_name,
    tb.match_id,
    tb.runs_conceded
FROM top_bowlers tb
JOIN player p
  ON p.player_id = tb.bowler
ORDER BY tb.runs_conceded DESC,
         bowler_name;
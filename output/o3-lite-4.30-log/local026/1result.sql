WITH over_runs AS (
    SELECT  bb.match_id,
            bb.over_id,
            bb.innings_no,
            bb.bowler,
            SUM(COALESCE(bs.runs_scored,0)) +
            SUM(CASE
                    WHEN er.extra_type IN ('wides','noballs')
                    THEN COALESCE(er.extra_runs,0)
                    ELSE 0
                END)                                   AS runs_conceded
    FROM ball_by_ball AS bb
    LEFT JOIN batsman_scored AS bs
           ON bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
    LEFT JOIN extra_runs AS er
           ON er.match_id   = bb.match_id
          AND er.over_id    = bb.over_id
          AND er.ball_id    = bb.ball_id
          AND er.innings_no = bb.innings_no
    GROUP BY bb.match_id, bb.over_id, bb.innings_no, bb.bowler
),
match_max AS (                       -- maximum runs conceded in any over of each match
    SELECT match_id,
           MAX(runs_conceded) AS mx
    FROM over_runs
    GROUP BY match_id
),
max_overs AS (                       -- overs that reached the match maximum
    SELECT o.match_id,
           o.bowler,
           o.runs_conceded
    FROM over_runs o
    JOIN match_max m
      ON o.match_id      = m.match_id
     AND o.runs_conceded = m.mx
),
ranked AS (                          -- rank those overs across all matches
    SELECT mo.*,
           ROW_NUMBER() OVER (ORDER BY mo.runs_conceded DESC, mo.match_id) AS rnk
    FROM max_overs mo
)
SELECT  p.player_name  AS bowler,
        ranked.match_id AS match,
        ranked.runs_conceded AS runs_conceded_in_over
FROM ranked
JOIN player p ON p.player_id = ranked.bowler
WHERE ranked.rnk <= 3
ORDER BY ranked.rnk;
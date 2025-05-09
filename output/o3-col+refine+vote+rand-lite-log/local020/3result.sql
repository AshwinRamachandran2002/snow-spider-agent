WITH runs AS (
    -- total runs (off the bat + extras) conceded by every bowler
    SELECT  bb.bowler,
            SUM( COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0) ) AS total_runs
    FROM    ball_by_ball AS bb
    LEFT JOIN batsman_scored AS bs
           ON bs.match_id = bb.match_id
          AND bs.over_id  = bb.over_id
          AND bs.ball_id  = bb.ball_id
    LEFT JOIN extra_runs     AS er
           ON er.match_id = bb.match_id
          AND er.over_id  = bb.over_id
          AND er.ball_id  = bb.ball_id
    GROUP BY bb.bowler
),
wickets AS (
    -- number of wickets credited to each bowler
    SELECT  bb.bowler,
            COUNT(*) AS wickets
    FROM    wicket_taken AS w
    JOIN    ball_by_ball AS bb
           ON bb.match_id = w.match_id
          AND bb.over_id  = w.over_id
          AND bb.ball_id  = w.ball_id
    GROUP BY bb.bowler
),
averages AS (
    -- bowling average = runs conceded / wickets
    SELECT  r.bowler,
            CAST(r.total_runs AS REAL) / w.wickets AS bowling_average
    FROM    runs    AS r
    JOIN    wickets AS w  ON w.bowler = r.bowler
    WHERE   w.wickets > 0        -- avoid division by zero
)
SELECT  p.player_name,
        a.bowling_average
FROM    averages AS a
JOIN    player   AS p  ON p.player_id = a.bowler
ORDER BY a.bowling_average ASC, p.player_name
LIMIT 1;
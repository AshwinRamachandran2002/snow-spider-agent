WITH over_runs AS (                -- 1. runs conceded by every bowler in every over
    SELECT
        b.match_id,
        b.over_id,
        b.bowler,
        SUM(COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0)) AS runs_in_over
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS bs
           USING (match_id, over_id, ball_id, innings_no)
    LEFT JOIN extra_runs AS er
           USING (match_id, over_id, ball_id, innings_no)
    GROUP BY b.match_id, b.over_id, b.bowler
),

match_max AS (                     -- 2. maximum-run over in every match
    SELECT
        match_id,
        MAX(runs_in_over) AS max_runs_in_over
    FROM over_runs
    GROUP BY match_id
),

worst_overs AS (                   -- 3. only those overs that equal the match maximum
    SELECT
        o.match_id,
        o.bowler,
        o.runs_in_over
    FROM over_runs o
    JOIN match_max m
      ON o.match_id      = m.match_id
     AND o.runs_in_over = m.max_runs_in_over
),

top_three AS (                     -- 4. pick the three biggest such overs overall
    SELECT
        bowler,
        match_id,
        runs_in_over
    FROM worst_overs
    ORDER BY runs_in_over DESC
    LIMIT 3
)

SELECT
    p.player_name AS bowler_name,
    t.match_id,
    t.runs_in_over
FROM top_three t
JOIN player p
  ON p.player_id = t.bowler;
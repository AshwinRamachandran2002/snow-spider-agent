WITH bs_runs AS (        -- runs off the bat for every ball
    SELECT match_id,
           over_id,
           ball_id,
           innings_no,
           SUM(runs_scored) AS runs_bat
    FROM batsman_scored
    GROUP BY match_id, over_id, ball_id, innings_no
),
ex_runs AS (             -- all extras for every ball
    SELECT match_id,
           over_id,
           ball_id,
           innings_no,
           SUM(extra_runs) AS runs_extra
    FROM extra_runs
    GROUP BY match_id, over_id, ball_id, innings_no
),
ball_runs AS (           -- total runs conceded on every delivery
    SELECT b.match_id,
           b.over_id,
           b.ball_id,
           b.innings_no,
           b.bowler,
           COALESCE(bs.runs_bat,0) + COALESCE(er.runs_extra,0) AS runs_conceded
    FROM ball_by_ball AS b
    LEFT JOIN bs_runs  AS bs ON  bs.match_id  = b.match_id
                            AND bs.over_id    = b.over_id
                            AND bs.ball_id    = b.ball_id
                            AND bs.innings_no = b.innings_no
    LEFT JOIN ex_runs  AS er ON  er.match_id  = b.match_id
                            AND er.over_id    = b.over_id
                            AND er.ball_id    = b.ball_id
                            AND er.innings_no = b.innings_no
),
bowler_totals AS (       -- total runs & wickets for every bowler
    SELECT br.bowler,
           SUM(br.runs_conceded)                                    AS total_runs,
           COUNT(wt.player_out)                                     AS wickets
    FROM ball_runs      AS br
    LEFT JOIN wicket_taken AS wt
           ON  wt.match_id  = br.match_id
           AND wt.over_id   = br.over_id
           AND wt.ball_id   = br.ball_id
           AND wt.innings_no= br.innings_no
    GROUP BY br.bowler
    HAVING wickets > 0                 -- keep only bowlers who actually took wickets
),
bowling_avg AS (         -- bowling average = runs per wicket
    SELECT bowler,
           1.0 * total_runs / wickets  AS avg_per_wicket
    FROM bowler_totals
)
SELECT p.player_name
FROM   bowling_avg AS ba
JOIN   player      AS p ON p.player_id = ba.bowler
ORDER  BY ba.avg_per_wicket ASC, p.player_name
LIMIT  1;
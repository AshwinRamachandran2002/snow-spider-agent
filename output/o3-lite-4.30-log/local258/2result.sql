WITH legal_wickets AS (
    /* wickets credited to the bowler (exclude run‑outs, retired hurt, obstruction) */
    SELECT b.bowler,
           b.match_id,
           COUNT(*) AS wickets
    FROM wicket_taken AS wt
    JOIN ball_by_ball AS b
      ON wt.match_id   = b.match_id
     AND wt.over_id    = b.over_id
     AND wt.ball_id    = b.ball_id
     AND wt.innings_no = b.innings_no
    WHERE wt.kind_out NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP BY b.bowler, b.match_id
),
runs_balls AS (
    /* runs off the bat conceded and balls delivered by every bowler in every match */
    SELECT b.bowler,
           b.match_id,
           SUM(bs.runs_scored) AS runs_conceded,
           COUNT(*)            AS balls
    FROM ball_by_ball AS b
    JOIN batsman_scored AS bs
      ON bs.match_id   = b.match_id
     AND bs.over_id    = b.over_id
     AND bs.ball_id    = b.ball_id
     AND bs.innings_no = b.innings_no
    GROUP BY b.bowler, b.match_id
),
combined AS (
    /* merge match‑level numbers */
    SELECT rb.bowler,
           rb.match_id,
           COALESCE(lw.wickets, 0) AS wickets,
           rb.runs_conceded,
           rb.balls
    FROM runs_balls rb
    LEFT JOIN legal_wickets lw
      ON lw.bowler   = rb.bowler
     AND lw.match_id = rb.match_id
),
overall AS (
    /* career aggregates */
    SELECT bowler,
           SUM(wickets)       AS total_wickets,
           SUM(runs_conceded) AS total_runs,
           SUM(balls)         AS total_balls
    FROM combined
    GROUP BY bowler
),
best AS (
    /* best spell per bowler: most wickets, then least runs */
    SELECT c.bowler,
           c.wickets || '-' || c.runs_conceded AS best_bowling
    FROM combined c
    WHERE c.wickets > 0
      AND NOT EXISTS (
            SELECT 1
            FROM combined c2
            WHERE c2.bowler = c.bowler
              AND (c2.wickets >  c.wickets
                   OR (c2.wickets = c.wickets AND c2.runs_conceded < c.runs_conceded))
        )
)
SELECT
    o.bowler                                 AS bowler,
    o.total_wickets                          AS total_wickets,
    ROUND(o.total_runs * 6.0 / o.total_balls, 4) AS economy_rate,
    CASE
        WHEN o.total_wickets = 0 THEN NULL
        ELSE ROUND(o.total_balls * 1.0 / o.total_wickets, 4)
    END                                      AS strike_rate,
    b.best_bowling
FROM overall o
LEFT JOIN best b
  ON b.bowler = o.bowler
ORDER BY o.total_wickets DESC, o.bowler;
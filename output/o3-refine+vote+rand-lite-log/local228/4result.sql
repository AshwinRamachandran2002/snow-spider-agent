WITH ball_runs AS (      -- runs scored by striker on every ball
    SELECT 
        m.season_id,
        bb.striker            AS player_id,
        bs.runs_scored
    FROM batsman_scored bs
    JOIN ball_by_ball bb
         ON bs.match_id  = bb.match_id
        AND bs.over_id   = bb.over_id
        AND bs.ball_id   = bb.ball_id
        AND bs.innings_no= bb.innings_no
    JOIN match m
         ON bs.match_id = m.match_id
),
batsman_totals AS (      -- total runs per batsman, per season
    SELECT
        season_id,
        player_id,
        SUM(runs_scored) AS total_runs
    FROM ball_runs
    GROUP BY season_id, player_id
),
batsman_ranked AS (      -- rank batsmen within each season
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id 
                           ORDER BY total_runs DESC, player_id ASC) AS rn
    FROM batsman_totals
),
top_batsmen AS (         -- keep only top‑3
    SELECT
        season_id,
        player_id  AS batsman_id,
        total_runs AS batsman_runs,
        rn
    FROM batsman_ranked
    WHERE rn <= 3
),

filtered_wickets AS (    -- wickets credited to bowlers, excluding specified kinds
    SELECT
        m.season_id,
        bb.bowler         AS player_id,
        1                 AS wicket
    FROM wicket_taken w
    JOIN ball_by_ball bb
         ON w.match_id   = bb.match_id
        AND w.over_id    = bb.over_id
        AND w.ball_id    = bb.ball_id
        AND w.innings_no = bb.innings_no
    JOIN match m
         ON w.match_id = m.match_id
    WHERE LOWER(w.kind_out) NOT IN ('run out','hit wicket','retired hurt')
),
bowler_totals AS (       -- total wickets per bowler, per season
    SELECT
        season_id,
        player_id,
        SUM(wicket) AS total_wkts
    FROM filtered_wickets
    GROUP BY season_id, player_id
),
bowler_ranked AS (       -- rank bowlers within each season
    SELECT
        season_id,
        player_id,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id 
                           ORDER BY total_wkts DESC, player_id ASC) AS rn
    FROM bowler_totals
),
top_bowlers AS (         -- keep only top‑3
    SELECT
        season_id,
        player_id  AS bowler_id,
        total_wkts AS bowler_wkts,
        rn
    FROM bowler_ranked
    WHERE rn <= 3
)

-- pair batsmen and bowlers rank‑wise for every season
SELECT
    b.season_id,
    b.batsman_id,
    b.batsman_runs,
    bo.bowler_id,
    bo.bowler_wkts
FROM top_batsmen b
JOIN top_bowlers bo
  ON b.season_id = bo.season_id
 AND b.rn        = bo.rn          -- match 1‑to‑1, 2‑to‑2, 3‑to‑3
ORDER BY
    b.season_id,
    b.rn;
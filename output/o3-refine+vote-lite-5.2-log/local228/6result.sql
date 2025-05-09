WITH
/* -------------------------------------------------
   Total runs scored by every batsman in every season
--------------------------------------------------*/
batsman_runs AS (
    SELECT
        m.season_id,
        bb.striker              AS player_id,
        SUM(bs.runs_scored)     AS total_runs
    FROM batsman_scored  bs
    JOIN ball_by_ball    bb
         ON  bb.match_id   = bs.match_id
         AND bb.over_id    = bs.over_id
         AND bb.ball_id    = bs.ball_id
         AND bb.innings_no = bs.innings_no
    JOIN match           m   ON m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
/* Rank batsmen per season (break ties by smaller player_id) */
batsman_ranked AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id ASC) AS rk
    FROM batsman_runs
),
top_batsmen AS (
    SELECT * FROM batsman_ranked WHERE rk <= 3
),

/* -------------------------------------------------
   Total wickets taken by every bowler (excluding
   run‑out, hit‑wicket, retired‑hurt) in every season
--------------------------------------------------*/
bowler_wkts AS (
    SELECT
        m.season_id,
        bb.bowler              AS player_id,
        COUNT(*)               AS total_wkts
    FROM wicket_taken   wt
    JOIN ball_by_ball   bb
         ON  bb.match_id   = wt.match_id
         AND bb.over_id    = wt.over_id
         AND bb.ball_id    = wt.ball_id
         AND bb.innings_no = wt.innings_no
    JOIN match          m   ON m.match_id = wt.match_id
    WHERE LOWER(wt.kind_out) NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
/* Rank bowlers per season (break ties by smaller player_id) */
bowler_ranked AS (
    SELECT
        season_id,
        player_id,
        total_wkts,
        ROW_NUMBER() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id ASC) AS rk
    FROM bowler_wkts
),
top_bowlers AS (
    SELECT * FROM bowler_ranked WHERE rk <= 3
)

/* -------------------------------------------------
   Pair the top‑3 batsmen and bowlers by matching ranks
--------------------------------------------------*/
SELECT
    b.season_id,
    b.player_id  AS batsman_id,
    b.total_runs,
    w.player_id  AS bowler_id,
    w.total_wkts
FROM top_batsmen  b
JOIN top_bowlers  w
     ON w.season_id = b.season_id
    AND w.rk        = b.rk          -- match 1‑vs‑1, 2‑vs‑2, 3‑vs‑3
ORDER BY
    b.season_id,
    b.rk;
WITH batsman_runs AS (
    SELECT
        m.season_id,
        bb.striker                         AS player_id,
        SUM(bs.runs_scored)                AS total_runs
    FROM batsman_scored AS bs
    JOIN ball_by_ball AS bb
         ON bs.match_id   = bb.match_id
        AND bs.over_id    = bb.over_id
        AND bs.ball_id    = bb.ball_id
        AND bs.innings_no = bb.innings_no
    JOIN match AS m
         ON m.match_id = bs.match_id
    GROUP BY m.season_id, bb.striker
),
batsman_ranked AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        DENSE_RANK() OVER (PARTITION BY season_id
                           ORDER BY total_runs DESC, player_id ASC) AS rnk
    FROM batsman_runs
),
top_batsmen AS (
    SELECT season_id, player_id, total_runs, rnk
    FROM batsman_ranked
    WHERE rnk <= 3
),

wickets AS (
    SELECT
        m.season_id,
        bb.bowler                         AS player_id,
        COUNT(*)                          AS total_wkts
    FROM wicket_taken AS w
    JOIN ball_by_ball AS bb
         ON w.match_id   = bb.match_id
        AND w.over_id    = bb.over_id
        AND w.ball_id    = bb.ball_id
        AND w.innings_no = bb.innings_no
    JOIN match AS m
         ON m.match_id = w.match_id
    WHERE LOWER(w.kind_out) NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
bowler_ranked AS (
    SELECT
        season_id,
        player_id,
        total_wkts,
        DENSE_RANK() OVER (PARTITION BY season_id
                           ORDER BY total_wkts DESC, player_id ASC) AS rnk
    FROM wickets
),
top_bowlers AS (
    SELECT season_id, player_id, total_wkts, rnk
    FROM bowler_ranked
    WHERE rnk <= 3
)

SELECT
    b.season_id,
    b.player_id  AS batsman_id,
    b.total_runs,
    bw.player_id AS bowler_id,
    bw.total_wkts
FROM top_batsmen  AS b
JOIN top_bowlers AS bw
  ON b.season_id = bw.season_id
 AND b.rnk       = bw.rnk
ORDER BY
    b.season_id,
    b.rnk;
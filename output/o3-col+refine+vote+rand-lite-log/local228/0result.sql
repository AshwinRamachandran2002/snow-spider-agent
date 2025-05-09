WITH runs AS (
    SELECT
        m.season_id,
        bb.striker                       AS player_id,
        SUM(bs.runs_scored)              AS total_runs
    FROM batsman_scored  bs
    JOIN ball_by_ball    bb USING (match_id, over_id, ball_id, innings_no)
    JOIN match           m  USING (match_id)
    GROUP BY m.season_id, bb.striker
),
ranked_bats AS (
    SELECT
        season_id,
        player_id,
        total_runs,
        DENSE_RANK() OVER (
            PARTITION BY season_id
            ORDER BY total_runs DESC, player_id ASC
        )                                AS rnk
    FROM runs
),
top_bats AS (
    SELECT *
    FROM ranked_bats
    WHERE rnk <= 3
),
wickets AS (
    SELECT
        m.season_id,
        bb.bowler                       AS player_id,
        COUNT(*)                        AS total_wkts
    FROM wicket_taken   w
    JOIN ball_by_ball   bb USING (match_id, over_id, ball_id, innings_no)
    JOIN match          m  USING (match_id)
    WHERE w.kind_out NOT IN ('run out', 'hit wicket', 'retired hurt')
    GROUP BY m.season_id, bb.bowler
),
ranked_bowls AS (
    SELECT
        season_id,
        player_id,
        total_wkts,
        DENSE_RANK() OVER (
            PARTITION BY season_id
            ORDER BY total_wkts DESC, player_id ASC
        )                                AS rnk
    FROM wickets
),
top_bowls AS (
    SELECT *
    FROM ranked_bowls
    WHERE rnk <= 3
)
SELECT
    b.season_id,
    b.player_id                 AS batsman_id,
    p1.player_name              AS batsman_name,
    b.total_runs,
    bl.player_id                AS bowler_id,
    p2.player_name              AS bowler_name,
    bl.total_wkts
FROM       top_bats  b
JOIN       top_bowls bl
           ON b.season_id = bl.season_id
          AND b.rnk       = bl.rnk           -- pair rank-wise
JOIN player p1 ON p1.player_id = b.player_id
JOIN player p2 ON p2.player_id = bl.player_id
ORDER BY b.season_id, b.rnk;
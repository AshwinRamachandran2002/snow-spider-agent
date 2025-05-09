WITH ordered_deliveries AS (
    SELECT
        b.match_id,
        b.innings_no,
        b.over_id,
        b.ball_id,
        b.striker,
        b.non_striker,
        -- Batsman IDs in sorted order
        CASE WHEN b.striker < b.non_striker THEN b.striker ELSE b.non_striker END AS batsman1_id,
        CASE WHEN b.striker >= b.non_striker THEN b.striker ELSE b.non_striker END AS batsman2_id,
        ROW_NUMBER() OVER (PARTITION BY b.match_id, b.innings_no ORDER BY b.over_id, b.ball_id) AS delivery_no,
        w.player_out
    FROM
        "ball_by_ball" b
    LEFT JOIN "wicket_taken" w ON
        b.match_id = w.match_id AND
        b.innings_no = w.innings_no AND
        b.over_id = w.over_id AND
        b.ball_id = w.ball_id
),
partnerships AS (
    SELECT
        od.*,
        od.batsman1_id || '_' || od.batsman2_id AS batsmen_set,
        LAG(od.batsman1_id || '_' || od.batsman2_id) OVER (
            PARTITION BY od.match_id, od.innings_no ORDER BY od.delivery_no
        ) AS prev_batsmen_set,
        CASE
            WHEN LAG(od.batsman1_id || '_' || od.batsman2_id) OVER (
                PARTITION BY od.match_id, od.innings_no ORDER BY od.delivery_no
            ) IS NULL THEN 1
            WHEN (od.batsman1_id || '_' || od.batsman2_id) != LAG(od.batsman1_id || '_' || od.batsman2_id) OVER (
                PARTITION BY od.match_id, od.innings_no ORDER BY od.delivery_no
            ) THEN 1
            WHEN od.player_out IS NOT NULL THEN 1
            ELSE 0
        END AS partnership_change
    FROM
        ordered_deliveries od
),
partnerships_with_id AS (
    SELECT
        p.*,
        SUM(partnership_change) OVER (
            PARTITION BY p.match_id, p.innings_no ORDER BY p.delivery_no
        ) AS partnership_id
    FROM
        partnerships p
),
partnership_runs AS (
    SELECT
        p.match_id,
        p.partnership_id,
        p.batsman1_id,
        p.batsman2_id,
        -- Sum runs scored by batsman1
        SUM(CASE WHEN b.striker = p.batsman1_id THEN s.runs_scored ELSE 0 END) AS batsman1_runs,
        -- Sum runs scored by batsman2
        SUM(CASE WHEN b.striker = p.batsman2_id THEN s.runs_scored ELSE 0 END) AS batsman2_runs,
        -- Total partnership runs (sum of both)
        SUM(s.runs_scored) AS partnership_runs
    FROM
        partnerships_with_id p
    JOIN "ball_by_ball" b ON
        p.match_id = b.match_id AND
        p.innings_no = b.innings_no AND
        p.over_id = b.over_id AND
        p.ball_id = b.ball_id
    JOIN "batsman_scored" s ON
        b.match_id = s.match_id AND
        b.innings_no = s.innings_no AND
        b.over_id = s.over_id AND
        b.ball_id = s.ball_id
    GROUP BY
        p.match_id,
        p.partnership_id,
        p.batsman1_id,
        p.batsman2_id
),
max_partnerships AS (
    SELECT
        pr.match_id,
        MAX(pr.partnership_runs) AS max_partnership_runs
    FROM
        partnership_runs pr
    GROUP BY
        pr.match_id
)
SELECT
    pr.match_id,
    CASE
        WHEN pr.batsman1_runs > pr.batsman2_runs THEN pr.batsman1_id
        WHEN pr.batsman1_runs < pr.batsman2_runs THEN pr.batsman2_id
        WHEN pr.batsman1_id > pr.batsman2_id THEN pr.batsman1_id
        ELSE pr.batsman2_id
    END AS player1_id,
    CASE
        WHEN pr.batsman1_runs > pr.batsman2_runs THEN pr.batsman1_runs
        WHEN pr.batsman1_runs < pr.batsman2_runs THEN pr.batsman2_runs
        ELSE pr.batsman1_runs
    END AS player1_runs,
    CASE
        WHEN pr.batsman1_runs > pr.batsman2_runs THEN pr.batsman2_id
        WHEN pr.batsman1_runs < pr.batsman2_runs THEN pr.batsman1_id
        WHEN pr.batsman1_id <= pr.batsman2_id THEN pr.batsman1_id
        ELSE pr.batsman2_id
    END AS player2_id,
    CASE
        WHEN pr.batsman1_runs > pr.batsman2_runs THEN pr.batsman2_runs
        WHEN pr.batsman1_runs < pr.batsman2_runs THEN pr.batsman1_runs
        ELSE pr.batsman2_runs
    END AS player2_runs,
    pr.partnership_runs
FROM
    partnership_runs pr
JOIN
    max_partnerships mp ON pr.match_id = mp.match_id AND pr.partnership_runs = mp.max_partnership_runs
ORDER BY
    pr.match_id;
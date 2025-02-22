-- Task: For each batsman in each partnership, find the total runs they scored, limited to 100 records.
WITH ball_with_wickets AS (
    SELECT
        bb.match_id,
        bb.innings_no,
        bb.over_id,
        bb.ball_id,
        bb.striker,
        bs.runs_scored,
        CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END AS wicket_fall
    FROM "ball_by_ball" bb
    LEFT JOIN "batsman_scored" bs
        ON bb.match_id = bs.match_id
        AND bb.innings_no = bs.innings_no
        AND bb.over_id = bs.over_id
        AND bb.ball_id = bs.ball_id
    LEFT JOIN "wicket_taken" wt
        ON bb.match_id = wt.match_id
        AND bb.innings_no = wt.innings_no
        AND bb.over_id = wt.over_id
        AND bb.ball_id = wt.ball_id
),
ball_with_delivery_no AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY match_id, innings_no ORDER BY over_id, ball_id) AS delivery_no
    FROM ball_with_wickets
),
ball_with_cum_wickets AS (
    SELECT
        *,
        SUM(wicket_fall) OVER (PARTITION BY match_id, innings_no ORDER BY delivery_no) AS cumulative_wickets,
        SUM(wicket_fall) OVER (
            PARTITION BY match_id, innings_no
            ORDER BY delivery_no
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS partnership_id_prev
    FROM ball_with_delivery_no
),
ball_with_partnership_id_fixed AS (
    SELECT
        *,
        COALESCE(partnership_id_prev, 0) AS partnership_id
    FROM ball_with_cum_wickets
),
batsman_runs_in_partnership AS (
    SELECT
        match_id,
        innings_no,
        partnership_id,
        striker AS batsman_id,
        SUM(runs_scored) AS runs
    FROM ball_with_partnership_id_fixed
    GROUP BY match_id, innings_no, partnership_id, striker
)
SELECT
    match_id,
    innings_no,
    partnership_id,
    batsman_id,
    runs
FROM batsman_runs_in_partnership
ORDER BY match_id, partnership_id, batsman_id
LIMIT 100;
WITH ball_with_wickets AS (
    SELECT
        bb.match_id,
        bb.innings_no,
        bb.over_id,
        bb.ball_id,
        bb.striker,
        bb.non_striker,
        bs.runs_scored,
        CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END AS wicket_fall
    FROM ball_by_ball bb
    LEFT JOIN batsman_scored bs 
        ON bb.match_id = bs.match_id 
        AND bb.innings_no = bs.innings_no 
        AND bb.over_id = bs.over_id 
        AND bb.ball_id = bs.ball_id
    LEFT JOIN wicket_taken wt 
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
        SUM(wicket_fall) OVER (PARTITION BY match_id, innings_no ORDER BY delivery_no ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS partnership_id_prev
    FROM ball_with_delivery_no
),
ball_with_partnership_id_fixed AS (
    SELECT
        *,
        COALESCE(partnership_id_prev, 0) AS partnership_id
    FROM ball_with_cum_wickets
),
batsmen_in_partnership AS (
    SELECT
        match_id,
        innings_no,
        partnership_id,
        batsman_id
    FROM (
        SELECT
            match_id,
            innings_no,
            partnership_id,
            striker AS batsman_id
        FROM ball_with_partnership_id_fixed
        UNION
        SELECT
            match_id,
            innings_no,
            partnership_id,
            non_striker AS batsman_id
        FROM ball_with_partnership_id_fixed
    )
    GROUP BY match_id, innings_no, partnership_id, batsman_id
),
partnership_batsmen AS (
    SELECT
        match_id,
        innings_no,
        partnership_id,
        MIN(batsman_id) AS batsman1_id,
        MAX(batsman_id) AS batsman2_id
    FROM batsmen_in_partnership
    GROUP BY match_id, innings_no, partnership_id
),
batsman_runs_in_partnership AS (
    SELECT
        bw.match_id,
        bw.innings_no,
        bw.partnership_id,
        bw.striker AS batsman_id,
        SUM(bw.runs_scored) AS runs
    FROM ball_with_partnership_id_fixed bw
    GROUP BY bw.match_id, bw.innings_no, bw.partnership_id, bw.striker
),
partnerships_with_runs AS (
    SELECT
        pb.match_id,
        pb.innings_no,
        pb.partnership_id,
        pb.batsman1_id,
        pb.batsman2_id,
        COALESCE(br1.runs, 0) AS batsman1_runs,
        COALESCE(br2.runs, 0) AS batsman2_runs,
        COALESCE(br1.runs, 0) + COALESCE(br2.runs, 0) AS partnership_runs
    FROM partnership_batsmen pb
    LEFT JOIN batsman_runs_in_partnership br1 
        ON pb.match_id = br1.match_id 
        AND pb.innings_no = br1.innings_no 
        AND pb.partnership_id = br1.partnership_id 
        AND br1.batsman_id = pb.batsman1_id
    LEFT JOIN batsman_runs_in_partnership br2 
        ON pb.match_id = br2.match_id 
        AND pb.innings_no = br2.innings_no 
        AND pb.partnership_id = br2.partnership_id 
        AND br2.batsman_id = pb.batsman2_id
),
max_partnerships AS (
    SELECT
        pwr.match_id,
        pwr.batsman1_id,
        pwr.batsman2_id,
        pwr.batsman1_runs,
        pwr.batsman2_runs,
        pwr.partnership_runs
    FROM partnerships_with_runs pwr
    JOIN (
        SELECT
            match_id,
            MAX(partnership_runs) AS max_partnership_runs
        FROM partnerships_with_runs
        GROUP BY match_id
    ) mp 
        ON pwr.match_id = mp.match_id 
        AND pwr.partnership_runs = mp.max_partnership_runs
)
SELECT
    mp.match_id,
    CASE
        WHEN mp.batsman1_runs > mp.batsman2_runs THEN mp.batsman1_id
        WHEN mp.batsman2_runs > mp.batsman1_runs THEN mp.batsman2_id
        WHEN mp.batsman1_id > mp.batsman2_id THEN mp.batsman1_id
        ELSE mp.batsman2_id
    END AS player1_id,
    CASE
        WHEN mp.batsman1_runs > mp.batsman2_runs THEN mp.batsman1_runs
        WHEN mp.batsman2_runs > mp.batsman1_runs THEN mp.batsman2_runs
        ELSE mp.batsman1_runs
    END AS player1_runs,
    CASE
        WHEN mp.batsman1_runs > mp.batsman2_runs THEN mp.batsman2_id
        WHEN mp.batsman2_runs > mp.batsman1_runs THEN mp.batsman1_id
        WHEN mp.batsman1_id < mp.batsman2_id THEN mp.batsman1_id
        ELSE mp.batsman2_id
    END AS player2_id,
    CASE
        WHEN mp.batsman1_runs > mp.batsman2_runs THEN mp.batsman2_runs
        WHEN mp.batsman2_runs > mp.batsman1_runs THEN mp.batsman1_runs
        ELSE mp.batsman1_runs
    END AS player2_runs,
    mp.partnership_runs
FROM max_partnerships mp
ORDER BY mp.match_id;
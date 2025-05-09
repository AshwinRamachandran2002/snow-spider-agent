WITH partnership_balls AS (
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."ball_id",
        bb."striker",
        bb."non_striker",
        bs."runs_scored",
        CASE WHEN wt."player_out" IS NOT NULL THEN 1 ELSE 0 END AS "wicket_fell",
        SUM(CASE WHEN wt."player_out" IS NOT NULL THEN 1 ELSE 0 END) OVER (
            PARTITION BY bb."match_id", bb."innings_no"
            ORDER BY bb."over_id", bb."ball_id"
            ROWS UNBOUNDED PRECEDING
        ) AS "partnership_no"
    FROM "IPL"."IPL"."BALL_BY_BALL" bb
    JOIN "IPL"."IPL"."BATSMAN_SCORED" bs
        ON bb."match_id" = bs."match_id"
        AND bb."innings_no" = bs."innings_no"
        AND bb."over_id" = bs."over_id"
        AND bb."ball_id" = bs."ball_id"
    LEFT JOIN "IPL"."IPL"."WICKET_TAKEN" wt
        ON bb."match_id" = wt."match_id"
        AND bb."innings_no" = wt."innings_no"
        AND bb."over_id" = wt."over_id"
        AND bb."ball_id" = wt."ball_id"
),
first_ball_per_partnership AS (
    SELECT
        pb."match_id",
        pb."innings_no",
        pb."partnership_no",
        pb."striker" AS "batsman1_id",
        pb."non_striker" AS "batsman2_id"
    FROM (
        SELECT
            pb.*,
            ROW_NUMBER() OVER (
                PARTITION BY pb."match_id", pb."innings_no", pb."partnership_no"
                ORDER BY pb."over_id", pb."ball_id"
            ) AS rn
        FROM partnership_balls pb
    ) pb
    WHERE pb.rn = 1
),
partnership_runs AS (
    SELECT
        pb."match_id",
        pb."innings_no",
        pb."partnership_no",
        SUM(pb."runs_scored") AS "partnership_runs"
    FROM partnership_balls pb
    GROUP BY
        pb."match_id",
        pb."innings_no",
        pb."partnership_no"
),
batsman_runs_per_partnership AS (
    SELECT
        pb."match_id",
        pb."innings_no",
        pb."partnership_no",
        pb."striker" AS "batsman_id",
        SUM(pb."runs_scored") AS "batsman_runs"
    FROM partnership_balls pb
    GROUP BY
        pb."match_id",
        pb."innings_no",
        pb."partnership_no",
        pb."striker"
),
partnerships_unique AS (
    SELECT
        fp."match_id",
        fp."innings_no",
        fp."partnership_no",
        fp."batsman1_id",
        fp."batsman2_id",
        pr."partnership_runs",
        COALESCE(b1."batsman_runs", 0) AS "batsman1_score",
        COALESCE(b2."batsman_runs", 0) AS "batsman2_score"
    FROM first_ball_per_partnership fp
    JOIN partnership_runs pr
        ON fp."match_id" = pr."match_id"
        AND fp."innings_no" = pr."innings_no"
        AND fp."partnership_no" = pr."partnership_no"
    LEFT JOIN batsman_runs_per_partnership b1
        ON fp."match_id" = b1."match_id"
        AND fp."innings_no" = b1."innings_no"
        AND fp."partnership_no" = b1."partnership_no"
        AND fp."batsman1_id" = b1."batsman_id"
    LEFT JOIN batsman_runs_per_partnership b2
        ON fp."match_id" = b2."match_id"
        AND fp."innings_no" = b2."innings_no"
        AND fp."partnership_no" = b2."partnership_no"
        AND fp."batsman2_id" = b2."batsman_id"
),
max_partnerships AS (
    SELECT
        "match_id",
        MAX("partnership_runs") AS "max_partnership_runs"
    FROM partnerships_unique
    GROUP BY "match_id"
),
top_partnerships AS (
    SELECT
        p."match_id",
        p."batsman1_id",
        p."batsman1_score",
        p."batsman2_id",
        p."batsman2_score",
        p."partnership_runs",
        CASE
            WHEN p."batsman1_score" > p."batsman2_score" THEN p."batsman1_id"
            WHEN p."batsman2_score" > p."batsman1_score" THEN p."batsman2_id"
            WHEN p."batsman1_id" > p."batsman2_id" THEN p."batsman1_id"
            ELSE p."batsman2_id"
        END AS "player1_id",
        CASE
            WHEN p."batsman1_score" < p."batsman2_score" THEN p."batsman1_id"
            WHEN p."batsman2_score" < p."batsman1_score" THEN p."batsman2_id"
            WHEN p."batsman1_id" < p."batsman2_id" THEN p."batsman1_id"
            ELSE p."batsman2_id"
        END AS "player2_id",
        CASE
            WHEN p."batsman1_score" > p."batsman2_score" THEN p."batsman1_score"
            WHEN p."batsman2_score" > p."batsman1_score" THEN p."batsman2_score"
            WHEN p."batsman1_id" > p."batsman2_id" THEN p."batsman1_score"
            ELSE p."batsman2_score"
        END AS "player1_score",
        CASE
            WHEN p."batsman1_score" < p."batsman2_score" THEN p."batsman1_score"
            WHEN p."batsman2_score" < p."batsman1_score" THEN p."batsman2_score"
            WHEN p."batsman1_id" < p."batsman2_id" THEN p."batsman1_score"
            ELSE p."batsman2_score"
        END AS "player2_score"
    FROM partnerships_unique p
    JOIN max_partnerships mp
        ON p."match_id" = mp."match_id"
        AND p."partnership_runs" = mp."max_partnership_runs"
)
SELECT
    "match_id",
    "player1_id",
    "player1_score",
    "player2_id",
    "player2_score",
    "partnership_runs" AS "partnership_score"
FROM top_partnerships
ORDER BY "match_id";
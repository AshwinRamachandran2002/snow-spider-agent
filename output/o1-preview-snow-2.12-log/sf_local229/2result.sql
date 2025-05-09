WITH ball_with_wickets AS (
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."ball_id",
        bb."striker",
        bb."non_striker",
        bb."bowler",
        bs."runs_scored",
        CASE WHEN wt."player_out" IS NOT NULL THEN 1 ELSE 0 END AS "is_wicket"
    FROM
        IPL.IPL."BALL_BY_BALL" bb
    LEFT JOIN
        IPL.IPL."BATSMAN_SCORED" bs
        ON bb."match_id" = bs."match_id"
        AND bb."innings_no" = bs."innings_no"
        AND bb."over_id" = bs."over_id"
        AND bb."ball_id" = bs."ball_id"
    LEFT JOIN
        IPL.IPL."WICKET_TAKEN" wt
        ON bb."match_id" = wt."match_id"
        AND bb."innings_no" = wt."innings_no"
        AND bb."over_id" = wt."over_id"
        AND bb."ball_id" = wt."ball_id"
),
ball_with_partnership AS (
    SELECT
        *,
        SUM("is_wicket") OVER (
            PARTITION BY "match_id", "innings_no"
            ORDER BY "over_id", "ball_id"
            ROWS UNBOUNDED PRECEDING
        ) AS "partnership_no"
    FROM
        ball_with_wickets
),
partnership_batsmen AS (
    SELECT
        "match_id",
        "innings_no",
        "partnership_no",
        MIN("batsman_id") AS "batsman_id1",
        MAX("batsman_id") AS "batsman_id2"
    FROM (
        SELECT "match_id", "innings_no", "partnership_no", "striker" AS "batsman_id"
        FROM ball_with_partnership
        UNION
        SELECT "match_id", "innings_no", "partnership_no", "non_striker" AS "batsman_id"
        FROM ball_with_partnership
    )
    GROUP BY
        "match_id",
        "innings_no",
        "partnership_no"
    HAVING COUNT(DISTINCT "batsman_id") = 2
),
partnership_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "partnership_no",
        SUM("runs_scored") AS "partnership_runs"
    FROM ball_with_partnership
    GROUP BY
        "match_id",
        "innings_no",
        "partnership_no"
),
batsman_runs AS (
    SELECT
        "match_id",
        "innings_no",
        "partnership_no",
        "batsman_id",
        SUM("runs_scored") AS "player_runs"
    FROM (
        SELECT
            "match_id",
            "innings_no",
            "partnership_no",
            "striker" AS "batsman_id",
            "runs_scored"
        FROM ball_with_partnership
        WHERE "runs_scored" IS NOT NULL
    )
    GROUP BY
        "match_id",
        "innings_no",
        "partnership_no",
        "batsman_id"
),
partnership_details AS (
    SELECT
        pr."match_id",
        pr."innings_no",
        pr."partnership_no",
        pb."batsman_id1",
        pb."batsman_id2",
        COALESCE(br1."player_runs", 0) AS "player1_runs",
        COALESCE(br2."player_runs", 0) AS "player2_runs",
        pr."partnership_runs"
    FROM partnership_runs pr
    JOIN partnership_batsmen pb
        ON pr."match_id" = pb."match_id"
        AND pr."innings_no" = pb."innings_no"
        AND pr."partnership_no" = pb."partnership_no"
    LEFT JOIN batsman_runs br1
        ON pr."match_id" = br1."match_id"
        AND pr."innings_no" = br1."innings_no"
        AND pr."partnership_no" = br1."partnership_no"
        AND br1."batsman_id" = pb."batsman_id1"
    LEFT JOIN batsman_runs br2
        ON pr."match_id" = br2."match_id"
        AND pr."innings_no" = br2."innings_no"
        AND pr."partnership_no" = br2."partnership_no"
        AND br2."batsman_id" = pb."batsman_id2"
),
max_partnerships AS (
    SELECT
        "match_id",
        MAX("partnership_runs") AS "max_partnership_runs"
    FROM partnership_details
    GROUP BY "match_id"
)
SELECT
    pd."match_id",
    CASE
        WHEN pd."player1_runs" > pd."player2_runs" THEN pd."batsman_id1"
        WHEN pd."player1_runs" < pd."player2_runs" THEN pd."batsman_id2"
        WHEN pd."batsman_id1" < pd."batsman_id2" THEN pd."batsman_id2"
        ELSE pd."batsman_id1"
    END AS "player1_id",
    CASE
        WHEN pd."player1_runs" > pd."player2_runs" THEN pd."player1_runs"
        WHEN pd."player1_runs" < pd."player2_runs" THEN pd."player2_runs"
        WHEN pd."batsman_id1" < pd."batsman_id2" THEN pd."player2_runs"
        ELSE pd."player1_runs"
    END AS "player1_score",
    CASE
        WHEN pd."player1_runs" > pd."player2_runs" THEN pd."batsman_id2"
        WHEN pd."player1_runs" < pd."player2_runs" THEN pd."batsman_id1"
        WHEN pd."batsman_id1" < pd."batsman_id2" THEN pd."batsman_id1"
        ELSE pd."batsman_id2"
    END AS "player2_id",
    CASE
        WHEN pd."player1_runs" > pd."player2_runs" THEN pd."player2_runs"
        WHEN pd."player1_runs" < pd."player2_runs" THEN pd."player1_runs"
        WHEN pd."batsman_id1" < pd."batsman_id2" THEN pd."player1_runs"
        ELSE pd."player2_runs"
    END AS "player2_score",
    pd."partnership_runs" AS "partnership_score"
FROM partnership_details pd
JOIN max_partnerships mp
    ON pd."match_id" = mp."match_id"
    AND pd."partnership_runs" = mp."max_partnership_runs"
ORDER BY pd."match_id";
WITH deliveries_with_pn AS (
    SELECT
        b."match_id",
        b."innings_no",
        b."over_id",
        b."ball_id",
        b."striker",
        b."non_striker",
        s."runs_scored",
        CASE WHEN w."player_out" IS NOT NULL THEN 1 ELSE 0 END AS "wicket_fell",
        SUM(CASE WHEN w."player_out" IS NOT NULL THEN 1 ELSE 0 END) OVER (
            PARTITION BY b."match_id", b."innings_no"
            ORDER BY b."over_id", b."ball_id"
            ROWS UNBOUNDED PRECEDING
        ) AS "partnership_number"
    FROM IPL.IPL."BALL_BY_BALL" b
    JOIN IPL.IPL."BATSMAN_SCORED" s
        ON b."match_id" = s."match_id"
        AND b."innings_no" = s."innings_no"
        AND b."over_id" = s."over_id"
        AND b."ball_id" = s."ball_id"
    LEFT JOIN IPL.IPL."WICKET_TAKEN" w
        ON b."match_id" = w."match_id"
        AND b."innings_no" = w."innings_no"
        AND b."over_id" = w."over_id"
        AND b."ball_id" = w."ball_id"
),
partners AS (
    SELECT
        dw."match_id",
        dw."innings_no",
        dw."partnership_number",
        dw."striker" AS "player1_id",
        dw."non_striker" AS "player2_id"
    FROM (
        SELECT
            dw.*,
            ROW_NUMBER() OVER (
                PARTITION BY dw."match_id", dw."innings_no", dw."partnership_number"
                ORDER BY dw."over_id", dw."ball_id"
            ) AS rn
        FROM deliveries_with_pn dw
    ) dw
    WHERE dw.rn = 1
),
partnership_runs AS (
    SELECT
        dw."match_id",
        dw."partnership_number",
        SUM(dw."runs_scored" + COALESCE(er."extra_runs", 0)) AS "partnership_runs"
    FROM deliveries_with_pn dw
    LEFT JOIN IPL.IPL."EXTRA_RUNS" er
        ON dw."match_id" = er."match_id"
        AND dw."innings_no" = er."innings_no"
        AND dw."over_id" = er."over_id"
        AND dw."ball_id" = er."ball_id"
    GROUP BY dw."match_id", dw."partnership_number"
),
individual_scores AS (
    SELECT
        dw."match_id",
        dw."partnership_number",
        dw."striker" AS "player_id",
        SUM(dw."runs_scored") AS "player_runs"
    FROM deliveries_with_pn dw
    GROUP BY dw."match_id", dw."partnership_number", dw."striker"
),
partnerships_with_scores AS (
    SELECT
        p."match_id",
        p."player1_id",
        p."player2_id",
        pr."partnership_runs",
        COALESCE(is1."player_runs", 0) AS "player1_score",
        COALESCE(is2."player_runs", 0) AS "player2_score"
    FROM partners p
    JOIN partnership_runs pr
        ON p."match_id" = pr."match_id"
        AND p."partnership_number" = pr."partnership_number"
    LEFT JOIN individual_scores is1
        ON p."match_id" = is1."match_id"
        AND p."partnership_number" = is1."partnership_number"
        AND p."player1_id" = is1."player_id"
    LEFT JOIN individual_scores is2
        ON p."match_id" = is2."match_id"
        AND p."partnership_number" = is2."partnership_number"
        AND p."player2_id" = is2."player_id"
),
ordered_partnerships AS (
    SELECT
        pws."match_id",
        CASE
            WHEN pws."player1_score" > pws."player2_score" THEN pws."player1_id"
            WHEN pws."player2_score" > pws."player1_score" THEN pws."player2_id"
            WHEN pws."player1_id" > pws."player2_id" THEN pws."player1_id"
            ELSE pws."player2_id"
        END AS "player1_id",
        CASE
            WHEN pws."player1_score" > pws."player2_score" THEN pws."player1_score"
            WHEN pws."player2_score" > pws."player1_score" THEN pws."player2_score"
            WHEN pws."player1_id" > pws."player2_id" THEN pws."player1_score"
            ELSE pws."player2_score"
        END AS "player1_score",
        CASE
            WHEN pws."player1_score" > pws."player2_score" THEN pws."player2_id"
            WHEN pws."player2_score" > pws."player1_score" THEN pws."player1_id"
            WHEN pws."player1_id" > pws."player2_id" THEN pws."player2_id"
            ELSE pws."player1_id"
        END AS "player2_id",
        CASE
            WHEN pws."player1_score" > pws."player2_score" THEN pws."player2_score"
            WHEN pws."player2_score" > pws."player1_score" THEN pws."player1_score"
            WHEN pws."player1_id" > pws."player2_id" THEN pws."player2_score"
            ELSE pws."player1_score"
        END AS "player2_score",
        pws."partnership_runs" AS "partnership_score"
    FROM partnerships_with_scores pws
)
SELECT
    op."match_id",
    op."player1_id",
    op."player1_score",
    op."player2_id",
    op."player2_score",
    op."partnership_score"
FROM ordered_partnerships op
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY op."match_id"
    ORDER BY op."partnership_score" DESC NULLS LAST, op."player1_id" DESC NULLS LAST, op."player2_id" DESC NULLS LAST
) = 1
ORDER BY op."match_id";
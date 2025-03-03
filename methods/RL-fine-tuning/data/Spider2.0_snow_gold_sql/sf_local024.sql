WITH
country_total_runs AS (
    SELECT
        p."country_name",
        SUM(bs."runs_scored") AS "total_runs"
    FROM
        "IPL"."IPL"."PLAYER" p
        JOIN "IPL"."IPL"."BALL_BY_BALL" bb ON p."player_id" = bb."striker"
        JOIN "IPL"."IPL"."BATSMAN_SCORED" bs ON bb."match_id" = bs."match_id"
            AND bb."over_id" = bs."over_id"
            AND bb."ball_id" = bs."ball_id"
            AND bb."innings_no" = bs."innings_no"
    GROUP BY
        p."country_name"
),
country_total_matches AS (
    SELECT
        p."country_name",
        COUNT(DISTINCT pm."match_id") AS "total_matches"
    FROM
        "IPL"."IPL"."PLAYER" p
        JOIN "IPL"."IPL"."PLAYER_MATCH" pm ON p."player_id" = pm."player_id"
    GROUP BY
        p."country_name"
),
country_dismissals AS (
    SELECT
        p."country_name",
        COUNT(*) AS "dismissals"
    FROM
        "IPL"."IPL"."PLAYER" p
        JOIN "IPL"."IPL"."WICKET_TAKEN" wt ON p."player_id" = wt."player_out"
    GROUP BY
        p."country_name"
)
SELECT
    tr."country_name" AS "Country",
    ROUND(tr."total_runs"::float / tm."total_matches", 4) AS "Average_Runs_per_Match",
    ROUND(tr."total_runs"::float / NULLIF(d."dismissals", 0), 4) AS "Batting_Average"
FROM
    country_total_runs tr
    JOIN country_total_matches tm ON tr."country_name" = tm."country_name"
    LEFT JOIN country_dismissals d ON tr."country_name" = d."country_name"
ORDER BY
    "Average_Runs_per_Match" DESC NULLS LAST
LIMIT 5;
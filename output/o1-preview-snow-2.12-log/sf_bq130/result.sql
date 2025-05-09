WITH
    state_daily_new_cases AS (
        SELECT
            s."date",
            s."state_name",
            s."confirmed_cases",
            COALESCE(
                s."confirmed_cases" - LAG(s."confirmed_cases") OVER (
                    PARTITION BY s."state_name" ORDER BY s."date"
                ),
                s."confirmed_cases"
            ) AS "daily_new_cases"
        FROM
            COVID19_NYT.COVID19_NYT.US_STATES s
        WHERE
            s."date" BETWEEN '2020-03-01' AND '2020-05-31'
    ),
    state_top5 AS (
        SELECT
            "date",
            "state_name",
            "daily_new_cases",
            RANK() OVER (
                PARTITION BY "date"
                ORDER BY "daily_new_cases" DESC NULLS LAST, "state_name" ASC
            ) AS "state_rank"
        FROM
            state_daily_new_cases
    ),
    state_top5_filtered AS (
        SELECT
            *
        FROM
            state_top5
        WHERE
            "state_rank" <= 5
    ),
    state_appearance_counts AS (
        SELECT
            "state_name",
            COUNT(*) AS "appearance_count"
        FROM
            state_top5_filtered
        GROUP BY
            "state_name"
    ),
    state_rankings AS (
        SELECT
            "state_name",
            "appearance_count",
            RANK() OVER (
                ORDER BY "appearance_count" DESC NULLS LAST, "state_name" ASC
            ) AS "state_overall_rank"
        FROM
            state_appearance_counts
    ),
    fourth_ranked_state AS (
        SELECT
            "state_name"
        FROM
            state_rankings
        WHERE
            "state_overall_rank" = 4
    ),
    county_daily_new_cases AS (
        SELECT
            c."date",
            c."state_name",
            c."county",
            c."confirmed_cases",
            COALESCE(
                c."confirmed_cases" - LAG(c."confirmed_cases") OVER (
                    PARTITION BY c."state_name", c."county" ORDER BY c."date"
                ),
                c."confirmed_cases"
            ) AS "daily_new_cases"
        FROM
            COVID19_NYT.COVID19_NYT.US_COUNTIES c
        WHERE
            c."date" BETWEEN '2020-03-01' AND '2020-05-31'
            AND c."state_name" IN (SELECT "state_name" FROM fourth_ranked_state)
    ),
    county_top5 AS (
        SELECT
            "date",
            "state_name",
            "county",
            "daily_new_cases",
            RANK() OVER (
                PARTITION BY "date"
                ORDER BY "daily_new_cases" DESC NULLS LAST, "county" ASC
            ) AS "county_rank"
        FROM
            county_daily_new_cases
    ),
    county_top5_filtered AS (
        SELECT
            *
        FROM
            county_top5
        WHERE
            "county_rank" <= 5
    ),
    county_appearance_counts AS (
        SELECT
            "county" AS "County_Name",
            COUNT(*) AS "Appearance_Count"
        FROM
            county_top5_filtered
        GROUP BY
            "county"
    ),
    county_rankings AS (
        SELECT
            "County_Name",
            "Appearance_Count"
        FROM
            county_appearance_counts
        ORDER BY
            "Appearance_Count" DESC NULLS LAST, "County_Name" ASC
        LIMIT
            5
    )
SELECT
    "County_Name",
    "Appearance_Count"
FROM
    county_rankings;
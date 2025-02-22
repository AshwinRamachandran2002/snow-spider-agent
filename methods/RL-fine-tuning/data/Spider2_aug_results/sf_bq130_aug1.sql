-- Task: Count how many times each state appears in the daily top five increases in COVID-19 cases from March to May 2020.
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
    )
SELECT
    "state_name",
    "appearance_count"
FROM
    state_appearance_counts
ORDER BY
    "appearance_count" DESC NULLS LAST, "state_name" ASC;
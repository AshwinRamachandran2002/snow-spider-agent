WITH state_daily_new_cases AS (
    SELECT
        "state_name",
        "date",
        "confirmed_cases",
        LAG("confirmed_cases") OVER (
            PARTITION BY "state_name" 
            ORDER BY "date"
        ) AS "prev_confirmed_cases",
        ("confirmed_cases" - LAG("confirmed_cases") OVER (
            PARTITION BY "state_name" 
            ORDER BY "date"
        )) AS "daily_new_cases"
    FROM
        "COVID19_NYT"."COVID19_NYT"."US_STATES"
    WHERE
        "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_ranks AS (
    SELECT
        "state_name",
        "date",
        COALESCE("daily_new_cases", "confirmed_cases") AS "daily_new_cases",
        ROW_NUMBER() OVER (
            PARTITION BY "date"
            ORDER BY COALESCE("daily_new_cases", "confirmed_cases") DESC NULLS LAST
        ) AS "rank"
    FROM
        state_daily_new_cases
),
state_appearance_counts AS (
    SELECT
        "state_name",
        COUNT(*) AS "Appearance_Count"
    FROM
        state_daily_ranks
    WHERE
        "rank" <= 5
    GROUP BY
        "state_name"
),
state_overall_ranks AS (
    SELECT
        "state_name",
        "Appearance_Count",
        DENSE_RANK() OVER (
            ORDER BY "Appearance_Count" DESC
        ) AS "overall_rank"
    FROM
        state_appearance_counts
),
fourth_ranked_state AS (
    SELECT
        "state_name"
    FROM
        state_overall_ranks
    WHERE
        "overall_rank" = 4
),
county_daily_new_cases AS (
    SELECT
        c."county",
        c."date",
        c."confirmed_cases",
        LAG(c."confirmed_cases") OVER (
            PARTITION BY c."county"
            ORDER BY c."date"
        ) AS "prev_confirmed_cases",
        (c."confirmed_cases" - LAG(c."confirmed_cases") OVER (
            PARTITION BY c."county"
            ORDER BY c."date"
        )) AS "daily_new_cases"
    FROM
        "COVID19_NYT"."COVID19_NYT"."US_COUNTIES" c
    WHERE
        c."date" BETWEEN '2020-03-01' AND '2020-05-31'
        AND c."state_name" IN (SELECT "state_name" FROM fourth_ranked_state)
),
county_daily_ranks AS (
    SELECT
        "county",
        "date",
        COALESCE("daily_new_cases", "confirmed_cases") AS "daily_new_cases",
        ROW_NUMBER() OVER (
            PARTITION BY "date"
            ORDER BY COALESCE("daily_new_cases", "confirmed_cases") DESC NULLS LAST
        ) AS "rank"
    FROM
        county_daily_new_cases
),
county_appearance_counts AS (
    SELECT
        "county" AS "County_Name",
        COUNT(*) AS "Appearance_Count"
    FROM
        county_daily_ranks
    WHERE
        "rank" <= 5
    GROUP BY
        "county"
)
SELECT
    "County_Name",
    "Appearance_Count"
FROM
    county_appearance_counts
ORDER BY
    "Appearance_Count" DESC NULLS LAST,
    "County_Name" ASC
LIMIT 5;
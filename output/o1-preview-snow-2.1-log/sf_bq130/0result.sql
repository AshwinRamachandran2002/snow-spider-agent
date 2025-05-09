WITH state_daily_new_cases AS (
    SELECT
        s."date",
        s."state_name",
        s."confirmed_cases" - COALESCE(LAG(s."confirmed_cases") OVER (PARTITION BY s."state_name" ORDER BY s."date"), 0) AS "daily_new_cases"
    FROM
        COVID19_NYT.COVID19_NYT.US_STATES s
    WHERE
        s."date" BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_top5 AS (
    SELECT
        dnc."date",
        dnc."state_name",
        dnc."daily_new_cases",
        DENSE_RANK() OVER (PARTITION BY dnc."date" ORDER BY dnc."daily_new_cases" DESC NULLS LAST) AS "state_rank"
    FROM
        state_daily_new_cases dnc
),
state_top_counts AS (
    SELECT
        sdt."state_name",
        COUNT(*) AS "appearance_count"
    FROM
        state_daily_top5 sdt
    WHERE
        sdt."state_rank" <= 5
    GROUP BY
        sdt."state_name"
),
fourth_ranked_state AS (
    SELECT
        stc."state_name"
    FROM
        state_top_counts stc
    ORDER BY
        stc."appearance_count" DESC NULLS LAST
    LIMIT 1 OFFSET 3
),
county_daily_new_cases AS (
    SELECT
        c."date",
        c."county",
        c."confirmed_cases" - COALESCE(LAG(c."confirmed_cases") OVER (PARTITION BY c."state_name", c."county" ORDER BY c."date"), 0) AS "daily_new_cases"
    FROM
        COVID19_NYT.COVID19_NYT.US_COUNTIES c
    WHERE
        c."state_name" = (SELECT "state_name" FROM fourth_ranked_state)
        AND c."date" BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily_top5 AS (
    SELECT
        dnc."date",
        dnc."county",
        dnc."daily_new_cases",
        DENSE_RANK() OVER (PARTITION BY dnc."date" ORDER BY dnc."daily_new_cases" DESC NULLS LAST) AS "county_rank"
    FROM
        county_daily_new_cases dnc
),
county_top_counts AS (
    SELECT
        cdt."county" AS "County_Name",
        COUNT(*) AS "Appearance_Count"
    FROM
        county_daily_top5 cdt
    WHERE
        cdt."county_rank" <= 5
    GROUP BY
        cdt."county"
)
SELECT
    "County_Name",
    "Appearance_Count"
FROM
    county_top_counts
ORDER BY
    "Appearance_Count" DESC NULLS LAST
LIMIT 5;
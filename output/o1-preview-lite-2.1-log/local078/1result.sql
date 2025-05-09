WITH max_compositions AS (
    SELECT
        m."interest_id",
        im."interest_name",
        m."month_year",
        m."composition",
        ROW_NUMBER() OVER (
            PARTITION BY m."interest_id"
            ORDER BY m."composition" DESC
        ) AS rn
    FROM
        "interest_metrics" m
        JOIN "interest_map" im ON m."interest_id" = im."id"
    WHERE m."composition" IS NOT NULL
)
SELECT
    "month_year" AS "Time(MM-YYYY)",
    "interest_name" AS "Interest_Name",
    ROUND("composition", 4) AS "Composition_Value"
FROM (
    SELECT "month_year", "interest_name", "composition"
    FROM max_compositions
    WHERE rn = 1
    ORDER BY "composition" DESC
    LIMIT 10
)
UNION ALL
SELECT
    "month_year" AS "Time(MM-YYYY)",
    "interest_name" AS "Interest_Name",
    ROUND("composition", 4) AS "Composition_Value"
FROM (
    SELECT "month_year", "interest_name", "composition"
    FROM max_compositions
    WHERE rn = 1
    ORDER BY "composition" ASC
    LIMIT 10
)
ORDER BY "Composition_Value" DESC;
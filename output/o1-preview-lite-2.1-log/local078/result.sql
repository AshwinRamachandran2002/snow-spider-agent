WITH max_compositions AS (
    SELECT
        im."interest_id",
        MAX(im."composition") AS "max_composition"
    FROM
        "interest_metrics" AS im
    WHERE
        im."interest_id" IS NOT NULL
        AND im."composition" IS NOT NULL
    GROUP BY
        im."interest_id"
),
max_comp_with_date AS (
    SELECT
        im."interest_id",
        im."month_year",
        im."composition",
        m."interest_name"
    FROM
        "interest_metrics" AS im
    JOIN
        "interest_map" AS m ON im."interest_id" = m."id"
    WHERE
        im."month_year" IS NOT NULL
        AND im."composition" IS NOT NULL
        AND m."interest_name" IS NOT NULL
        AND (im."interest_id", im."composition") IN (
            SELECT mc."interest_id", mc."max_composition"
            FROM max_compositions AS mc
        )
),
top_10 AS (
    SELECT *
    FROM max_comp_with_date
    ORDER BY "composition" DESC
    LIMIT 10
),
bottom_10 AS (
    SELECT *
    FROM max_comp_with_date
    ORDER BY "composition" ASC
    LIMIT 10
),
top_bottom_10 AS (
    SELECT * FROM top_10
    UNION ALL
    SELECT * FROM bottom_10
)
SELECT
    "month_year" AS "Time(MM-YYYY)",
    "interest_name" AS "Interest_Name",
    ROUND("composition", 4) AS "Composition_Value"
FROM
    top_bottom_10
ORDER BY
    "Composition_Value" DESC;
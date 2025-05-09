WITH per_year_cause AS (
    SELECT
        SUBSTR("collision_date", 1, 4) AS "Year",
        "primary_collision_factor" AS "Cause",
        COUNT(*) AS "Count"
    FROM "collisions"
    WHERE "primary_collision_factor" IS NOT NULL AND "primary_collision_factor" <> ''
    GROUP BY "Year", "Cause"
),
top_two_causes_per_year AS (
    SELECT
        t1."Year",
        t1."Cause"
    FROM per_year_cause t1
    WHERE (
        SELECT COUNT(DISTINCT t2."Count")
        FROM per_year_cause t2
        WHERE t2."Year" = t1."Year" AND t2."Count" > t1."Count"
    ) < 2
),
signature_per_year AS (
    SELECT
        "Year",
        GROUP_CONCAT("Cause", '||') AS "Signature"
    FROM (
        SELECT "Year", "Cause"
        FROM top_two_causes_per_year
        ORDER BY "Cause"
    )
    GROUP BY "Year"
),
signature_counts AS (
    SELECT
        "Signature",
        COUNT(*) AS "YearCount"
    FROM signature_per_year
    GROUP BY "Signature"
),
unique_signatures AS (
    SELECT "Signature"
    FROM signature_counts
    WHERE "YearCount" = 1
),
years_with_unique_top_causes AS (
    SELECT "Year"
    FROM signature_per_year
    WHERE "Signature" IN (SELECT "Signature" FROM unique_signatures)
)
SELECT "Year"
FROM years_with_unique_top_causes
ORDER BY "Year";
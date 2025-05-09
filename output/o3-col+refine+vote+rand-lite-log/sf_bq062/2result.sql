WITH license_counts AS (
    SELECT
        pv."System",
        f.value::STRING AS "License",
        COUNT(*)        AS "Occurrences"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS AS pv,
         LATERAL FLATTEN(input => pv."Licenses") f
    GROUP BY
        pv."System",
        f.value::STRING
),
ranked AS (
    SELECT
        "System",
        "License",
        "Occurrences",
        ROW_NUMBER() OVER (PARTITION BY "System" ORDER BY "Occurrences" DESC) AS rn
    FROM license_counts
)
SELECT
    "System",
    "License",
    "Occurrences"
FROM ranked
WHERE rn = 1
ORDER BY "System";
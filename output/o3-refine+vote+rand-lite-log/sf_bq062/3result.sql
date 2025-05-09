WITH license_counts AS (
    SELECT
        "System",
        lic.value::string          AS "License",
        COUNT(*)                   AS "UsageCount"
    FROM
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
        , LATERAL FLATTEN(INPUT => TRY_PARSE_JSON("Licenses")) lic
    WHERE
        lic.value IS NOT NULL
        AND lic.value::string <> ''
    GROUP BY
        "System",
        lic.value::string
),
ranked AS (
    SELECT
        "System",
        "License",
        "UsageCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY "UsageCount" DESC, "License" ASC
        ) AS rn
    FROM
        license_counts
)
SELECT
    "System",
    "License"       AS "MostFrequentLicense",
    "UsageCount"
FROM
    ranked
WHERE
    rn = 1
ORDER BY
    "System" ASC;
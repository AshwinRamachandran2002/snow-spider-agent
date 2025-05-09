WITH flattened AS (
    SELECT
        pv."System",
        f.value::STRING AS "License"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv,
         LATERAL FLATTEN(INPUT => PARSE_JSON(pv."Licenses")) f
),
license_counts AS (
    SELECT
        "System",
        "License",
        COUNT(*) AS "PkgCount",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY COUNT(*) DESC, "License"
        ) AS rn
    FROM flattened
    GROUP BY "System", "License"
)
SELECT
    "System",
    "License"  AS "MostFrequentLicense",
    "PkgCount"
FROM license_counts
WHERE rn = 1
ORDER BY "System";
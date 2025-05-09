WITH exploded_licenses AS (
    SELECT
        "System",
        LA.VALUE::STRING AS "License"
    FROM
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
        LATERAL FLATTEN(INPUT => PARSE_JSON("Licenses")) AS LA
    WHERE
        LA.VALUE IS NOT NULL AND LA.VALUE::STRING != ''
),
license_counts AS (
    SELECT
        "System",
        "License",
        COUNT(*) AS "num_packages"
    FROM
        exploded_licenses
    GROUP BY
        "System",
        "License"
),
ranked_licenses AS (
    SELECT
        "System",
        "License",
        "num_packages",
        RANK() OVER (PARTITION BY "System" ORDER BY "num_packages" DESC NULLS LAST) AS "rank"
    FROM
        license_counts
)
SELECT
    "System",
    "License" AS "Most_Frequently_Used_License"
FROM
    ranked_licenses
WHERE
    "rank" = 1
ORDER BY
    "System";
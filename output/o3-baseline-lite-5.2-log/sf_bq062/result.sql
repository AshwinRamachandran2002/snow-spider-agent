WITH license_counts AS (
    SELECT
        "System",
        fl.value::STRING                  AS "License",
        COUNT(*)                          AS "Pkg_Count"
    FROM
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS",
        LATERAL FLATTEN(
            INPUT => PARSE_JSON("Licenses")
        ) fl                                -- one row per license string
    WHERE
        "Licenses" IS NOT NULL              -- ignore NULL
    GROUP BY
        "System",
        fl.value::STRING
),
ranked AS (
    SELECT
        "System",
        "License",
        "Pkg_Count",
        ROW_NUMBER() OVER (
            PARTITION BY "System"
            ORDER BY "Pkg_Count" DESC, "License"
        )                                   AS rn
    FROM license_counts
)
SELECT
    "System",
    "License"          AS "Most_Frequent_License",
    "Pkg_Count"        AS "Package_Version_Count"
FROM ranked
WHERE rn = 1
ORDER BY "System";
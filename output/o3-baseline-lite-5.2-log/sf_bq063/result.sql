WITH released AS (
    SELECT
        "Name",
        "Version",
        COALESCE(("VersionInfo":"Ordinal")::NUMBER, -1)      AS "Ordinal",
        "Links"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "Name" NOT LIKE '%@%'                       -- exclude scoped packages
      AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE -- keep only releases
),
latest_per_package AS (
    SELECT
        "Name",
        "Version",
        "Links"
    FROM released
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "Ordinal" DESC NULLS LAST) = 1
),
dependency_counts AS (
    SELECT
        "Name",
        "Version",
        COUNT(*) AS dep_count
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES
    WHERE "System" = 'NPM'
    GROUP BY "Name", "Version"
),
candidates AS (
    SELECT
        lp."Name",
        lp."Version",
        lp."Links",
        COALESCE(dc.dep_count, 0) AS dep_count
    FROM latest_per_package lp
    LEFT JOIN dependency_counts dc
           ON dc."Name" = lp."Name"
          AND dc."Version" = lp."Version"
),
top_package AS (
    SELECT *
    FROM candidates
    QUALIFY ROW_NUMBER() OVER (ORDER BY dep_count DESC NULLS LAST,
                               "Name"        ASC) = 1
),
github_source_repo AS (
    SELECT
        fl.value:"URL"::STRING AS url
    FROM top_package tp,
         LATERAL FLATTEN(input => tp."Links") fl
    WHERE fl.value:"Label"::STRING = 'SOURCE_REPO'
      AND fl.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT url
FROM github_source_repo
LIMIT 1;
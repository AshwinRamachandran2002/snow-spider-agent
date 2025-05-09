WITH latest_release AS (
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        pv."VersionInfo":"Ordinal"::NUMBER   AS ordinal
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                       -- exclude scoped packages
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE) = TRUE
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY pv."Name"
        ORDER BY ordinal DESC NULLS LAST, pv."SnapshotAt" DESC
    ) = 1                                                -- keep only the latest release per package
),
deps_count AS (
    SELECT
        lr."Name",
        lr."Version",
        lr."Links",
        COUNT(d."Dependency")         AS dep_count
    FROM latest_release lr
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
           ON d."System" = 'NPM'
          AND d."Name"   = lr."Name"
          AND d."Version"= lr."Version"
    GROUP BY lr."Name", lr."Version", lr."Links"
),
top_pkg AS (                                             -- package whose latest release has most dependencies
    SELECT *
    FROM deps_count
    QUALIFY ROW_NUMBER() OVER (
        ORDER BY dep_count DESC NULLS LAST, "Name"
    ) = 1
)
SELECT
    f.value:"URL"::STRING  AS "GITHUB_SOURCE_REPO_URL"
FROM top_pkg,
     LATERAL FLATTEN(input => top_pkg."Links") f
WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
  AND f.value:"URL"::STRING ILIKE '%github.com%'
LIMIT 1;
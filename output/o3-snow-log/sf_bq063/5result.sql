WITH "LATEST_RELEASED" AS (
    SELECT
        "Name",
        "Version",
        "SnapshotAt",
        "Links",
        ("VersionInfo":"Ordinal")::NUMBER     AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "Name" NOT LIKE '%@%'                                    -- exclude scoped packages
      AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE              -- only released versions
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY ("VersionInfo":"Ordinal")::NUMBER DESC NULLS LAST) = 1
),
"DEP_COUNTS" AS (
    SELECT
        lr."Name",
        lr."Version",
        lr."SnapshotAt",
        lr."Links",
        COUNT(d."Dependency") AS "DepsCount"
    FROM "LATEST_RELEASED" lr
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
           ON d."System"  = 'NPM'
          AND d."Name"    = lr."Name"
          AND d."Version" = lr."Version"
    GROUP BY lr."Name", lr."Version", lr."SnapshotAt", lr."Links"
),
"TOP_PKG" AS (
    SELECT *
    FROM "DEP_COUNTS"
    QUALIFY ROW_NUMBER() OVER (ORDER BY "DepsCount" DESC NULLS LAST) = 1
),
"SRC_REPO_URLS" AS (
    SELECT
        f.value:"URL"::STRING AS "URL"
    FROM "TOP_PKG" tp,
         LATERAL FLATTEN(INPUT => tp."Links") f
    WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
      AND f.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT "URL"
FROM "SRC_REPO_URLS"
QUALIFY ROW_NUMBER() OVER (ORDER BY "URL") = 1;
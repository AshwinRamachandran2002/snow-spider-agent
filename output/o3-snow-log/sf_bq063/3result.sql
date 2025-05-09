WITH latest_release AS (    -- latest released version for each NPM package (excluding names containing '@')
    SELECT
        "Name",
        "Version",
        "Links",
        "SnapshotAt",
        TRY_TO_NUMBER(("VersionInfo":"Ordinal")::STRING)      AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "Name" NOT LIKE '%@%'
      AND COALESCE(TRY_TO_BOOLEAN(("VersionInfo":"IsRelease")::STRING), FALSE)
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY "Name"
              ORDER BY TRY_TO_NUMBER(("VersionInfo":"Ordinal")::STRING) DESC NULLS LAST,
                       "SnapshotAt" DESC
           ) = 1
),
dependency_totals AS (       -- dependency count of those latest releases
    SELECT
        lr."Name",
        lr."Version",
        lr."Links",
        COUNT(d."Dependency")                       AS "DepCount"
    FROM latest_release lr
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
           ON d."System"  = 'NPM'
          AND d."Name"    = lr."Name"
          AND d."Version" = lr."Version"
    GROUP BY lr."Name", lr."Version", lr."Links"
),
top_pkg AS (                 -- package whose latest release has the most dependencies
    SELECT *
    FROM dependency_totals
    QUALIFY ROW_NUMBER() OVER (ORDER BY "DepCount" DESC NULLS LAST) = 1
),
source_repo AS (             -- pick the GitHub SOURCE_REPO URL
    SELECT
        f.value:"URL"::STRING AS "GitHubURL"
    FROM top_pkg tp,
         LATERAL FLATTEN(input => tp."Links") f
    WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
      AND POSITION('github.com', LOWER(f.value:"URL"::STRING)) > 0
)
SELECT "GitHubURL"
FROM source_repo
LIMIT 1;
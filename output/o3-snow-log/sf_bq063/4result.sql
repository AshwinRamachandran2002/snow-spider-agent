WITH latest_release AS (   -- latest released version (IsRelease = true) for every NPM package w/o '@'
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY (pv."VersionInfo":"Ordinal")::NUMBER DESC NULLS LAST,
                     pv."SnapshotAt" DESC NULLS LAST
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"  pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'
      AND COALESCE((pv."VersionInfo":"IsRelease")::BOOLEAN, FALSE) = TRUE
),
latest_release_dedup AS (          -- keep only the latest released version per package
    SELECT "Name","Version","Links"
    FROM   latest_release
    WHERE  rn = 1
),
gh_links AS (                      -- extract GitHub SOURCE_REPO links
    SELECT
        lr."Name",
        lr."Version",
        l.value:"URL"::STRING AS "URL"
    FROM latest_release_dedup lr,
         LATERAL FLATTEN(input => lr."Links") l
    WHERE l.value:"Label"::STRING = 'SOURCE_REPO'
      AND POSITION('github.com', LOWER(l.value:"URL"::STRING)) > 0
),
dep_counts AS (                    -- count dependencies for each latest release
    SELECT
        gl."Name",
        gl."Version",
        gl."URL",
        COUNT(d."Dependency") AS dep_count
    FROM gh_links gl
    LEFT JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
           ON d."System" = 'NPM'
          AND d."Name"   = gl."Name"
          AND d."Version"= gl."Version"
    GROUP BY gl."Name", gl."Version", gl."URL"
),
best_pkg AS (                      -- package with the highest dependency count
    SELECT *
    FROM dep_counts
    ORDER BY dep_count DESC NULLS LAST,
             "Name"      ASC
    LIMIT 1
)
SELECT "URL"
FROM   best_pkg;
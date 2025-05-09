WITH released_versions AS (          -- released, un‑scoped NPM versions
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt",
        pv."Links"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                      -- exclude scoped pkgs
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE) = TRUE
),
latest_released_versions AS (        -- latest released version per package
    SELECT rv.*
    FROM released_versions rv
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY rv."Name"
              ORDER BY rv."SnapshotAt" DESC,
                       rv."Version"   DESC) = 1
),
dependency_counts AS (               -- dependency count for each latest version
    SELECT
        lrv."Name",
        lrv."Version",
        COUNT(d."Dependency") AS dependency_count,
        lrv."Links"
    FROM latest_released_versions lrv
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
           ON d."System"  = 'NPM'
          AND d."Name"    = lrv."Name"
          AND d."Version" = lrv."Version"
    GROUP BY lrv."Name", lrv."Version", lrv."Links"
),
packages_with_link AS (              -- keep only pkgs with GitHub SOURCE_REPO link
    SELECT
        dc."Name",
        dc."Version",
        dc.dependency_count,
        fl.value:"URL"::STRING AS "GitHub_URL"
    FROM dependency_counts dc,
         LATERAL FLATTEN(input => dc."Links") fl
    WHERE fl.value:"Label"::STRING = 'SOURCE_REPO'
      AND fl.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT "GitHub_URL"
FROM packages_with_link
ORDER BY dependency_count DESC NULLS LAST,   -- highest deps first
         "Name" ASC,
         "Version" DESC
LIMIT 1;
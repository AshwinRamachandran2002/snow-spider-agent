WITH latest_release AS (
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt",
        pv."UpstreamPublishedAt",
        pv."Links",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY COALESCE(pv."UpstreamPublishedAt", pv."SnapshotAt") DESC,
                     pv."Version" DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                                            -- exclude scoped packages
      AND TRY_TO_BOOLEAN((pv."VersionInfo":"IsRelease")::STRING) = TRUE       -- only released versions
),
latest_per_pkg AS (
    SELECT
        "Name",
        "Version",
        "Links"
    FROM latest_release
    WHERE rn = 1
),
dep_counts AS (
    SELECT
        lp."Name",
        lp."Version",
        lp."Links",
        COUNT(d."Dependency") AS dep_cnt
    FROM latest_per_pkg lp
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
           ON d."System"  = 'NPM'
          AND d."Name"    = lp."Name"
          AND d."Version" = lp."Version"
    GROUP BY lp."Name", lp."Version", lp."Links"
),
source_repos AS (
    SELECT
        dc.*,
        f.value:"URL"::STRING AS github_url
    FROM dep_counts dc,
         LATERAL FLATTEN(INPUT => dc."Links") f
    WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
      AND POSITION('github.com' IN f.value:"URL"::STRING) > 0
)
SELECT github_url
FROM source_repos
ORDER BY dep_cnt DESC NULLS LAST,
         "Name"   ASC
LIMIT 1;
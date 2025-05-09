WITH latest_released_version AS (   -- one row per NPM package = its latest released version
    SELECT
        pv."Name",
        pv."Version",
        pv."SnapshotAt",
        pv."Links"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE
        pv."System" = 'NPM'
        AND pv."Name" NOT LIKE '%@%'                                       -- exclude scoped packages
        AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE)         -- released versions only
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pv."Name"
                               ORDER BY pv."SnapshotAt" DESC, pv."Version" DESC) = 1
),
deps_count_per_pkg AS (              -- count dependencies for that version
    SELECT
        lrv."Name",
        lrv."Version",
        lrv."SnapshotAt",
        lrv."Links",
        COUNT(d."Dependency")          AS dep_count
    FROM latest_released_version lrv
    LEFT JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
           ON d."System"  = 'NPM'
          AND d."Name"    = lrv."Name"
          AND d."Version" = lrv."Version"
    GROUP BY lrv."Name", lrv."Version", lrv."SnapshotAt", lrv."Links"
),
candidate_urls AS (                 -- keep only packages that have a GitHub SOURCE_REPO link
    SELECT
        p."Name",
        p."Version",
        p.dep_count,
        f.value:"URL"::STRING AS github_url
    FROM deps_count_per_pkg p,
         LATERAL FLATTEN(input => p."Links") f
    WHERE
          f.value:"Label"::STRING = 'SOURCE_REPO'
      AND f.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT github_url
FROM candidate_urls
ORDER BY dep_count DESC NULLS LAST, "Name" ASC       -- highest‑dependency package first
LIMIT 1;
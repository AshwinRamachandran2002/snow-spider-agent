WITH latest_releases AS (   -- latest *released* version (IsRelease = true) of every NPM package without '@'
    SELECT
        pv."Name",
        pv."Version",
        ("VersionInfo":"Ordinal")::NUMBER            AS ordinal,
        pv."SnapshotAt",
        pv."Links"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                  -- exclude scoped packages
      AND ("VersionInfo":"IsRelease")::BOOLEAN      -- only real releases
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY pv."Name"
                ORDER BY ordinal DESC NULLS LAST,
                         pv."SnapshotAt" DESC NULLS LAST
            ) = 1
),
deps_count AS (        -- number of direct dependencies for every (Name,Version)
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS dep_count
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    WHERE d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
),
top_pkg AS (           -- the package whose latest release has the most dependencies
    SELECT
        lr."Name",
        lr."Version",
        COALESCE(dc.dep_count, 0) AS dep_count,
        lr."Links"
    FROM latest_releases lr
    LEFT JOIN deps_count dc
           ON lr."Name"    = dc."Name"
          AND lr."Version" = dc."Version"
    QUALIFY ROW_NUMBER() OVER (
                ORDER BY dep_count DESC NULLS LAST,
                         lr."Name" ASC
            ) = 1
),
source_repo_links AS (  -- SOURCE_REPO links that point to GitHub
    SELECT
        l.value:"URL"::STRING AS github_url,
        ROW_NUMBER() OVER (ORDER BY l.index) AS rn
    FROM top_pkg tp,
         LATERAL FLATTEN(input => tp."Links") l
    WHERE l.value:"Label"::STRING = 'SOURCE_REPO'
      AND l.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT github_url
FROM source_repo_links
WHERE rn = 1;
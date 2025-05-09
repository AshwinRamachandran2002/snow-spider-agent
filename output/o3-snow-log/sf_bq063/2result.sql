WITH latest_release AS (      -- latest released version (IsRelease = true) of every un-scoped NPM package
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY COALESCE(pv."VersionInfo":"Ordinal"::NUMBER,0) DESC NULLS LAST,
                     pv."UpstreamPublishedAt"            DESC NULLS LAST,
                     pv."Version"                        DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"  pv
    WHERE pv."System" = 'NPM'
      AND pv."Name"  NOT LIKE '%@%'                       -- exclude names that contain '@'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE    -- only released versions
),
latest_releases AS (        -- keep just the latest one per package
    SELECT *
    FROM   latest_release
    WHERE  rn = 1
),
dep_counts AS (             -- number of dependencies for every (Name,Version)
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS dep_count
    FROM   DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
    WHERE  d."System" = 'NPM'
    GROUP  BY d."Name", d."Version"
),
releases_with_deps AS (     -- attach dependency counts (0 if none)
    SELECT
        lr."Name",
        lr."Version",
        lr."Links",
        COALESCE(dc.dep_count,0) AS dep_count
    FROM   latest_releases lr
    LEFT  JOIN dep_counts   dc
           ON lr."Name"    = dc."Name"
          AND lr."Version" = dc."Version"
),
github_releases AS (        -- keep only those that have a GitHub SOURCE_REPO link
    SELECT
        rwd.*,
        fl.value:"URL"::STRING AS github_url
    FROM   releases_with_deps rwd,
           LATERAL FLATTEN(input => rwd."Links") fl
    WHERE  fl.value:"Label"::STRING = 'SOURCE_REPO'
      AND  fl.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT github_url
FROM   github_releases
ORDER  BY dep_count DESC NULLS LAST   -- package whose latest release has the most dependencies
LIMIT  1;
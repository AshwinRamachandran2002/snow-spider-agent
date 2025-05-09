WITH dep_counts AS (          -- number of dependencies for every (Name,Version)
    SELECT "Name",
           "Version",
           COUNT(*) AS "DepsCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES
    WHERE "System" = 'NPM'
    GROUP BY "Name", "Version"
),
latest_release_per_pkg AS (   -- latest *released* version of every package (no '@')
    SELECT
        pv."Name",
        pv."Version",
        dc."DepsCount",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    LEFT JOIN dep_counts dc
           ON dc."Name" = pv."Name"
          AND dc."Version" = pv."Version"
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT ILIKE '%@%'                          -- exclude scoped packages
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE       -- only released versions
),
top_pkg AS (                 -- package whose latest release has the most dependencies
    SELECT "Name", "Version"
    FROM   latest_release_per_pkg
    WHERE  rn = 1
    ORDER BY COALESCE("DepsCount",0) DESC NULLS LAST
    LIMIT 1
)
SELECT
       fl.value:"URL"::STRING AS "GitHub_SourceRepo_URL"
FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
JOIN top_pkg tp
  ON pv."Name" = tp."Name"
 AND pv."Version" = tp."Version",
LATERAL FLATTEN(input => pv."Links") fl
WHERE fl.value:"Label"::STRING = 'SOURCE_REPO'    -- keep only SOURCE_REPO links
  AND fl.value:"URL"::STRING ILIKE '%github.com%' -- and only github URLs
LIMIT 1;
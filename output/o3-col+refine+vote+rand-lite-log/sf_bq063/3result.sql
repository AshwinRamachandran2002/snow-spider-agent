WITH latest_released AS (   -- latest *released* version (highest Ordinal) for every NPM package w/o “@”
    SELECT
        "Name",
        MAX(("VersionInfo":"Ordinal")::NUMBER) AS "LatestOrdinal"
    FROM   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE  "System" = 'NPM'
      AND  "Name"   NOT ILIKE '%@%'
      AND  ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    GROUP BY "Name"
),
latest_versions AS (        -- translate Ordinal → concrete Version string
    SELECT
        p."Name",
        p."Version"
    FROM   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS p
    JOIN   latest_released lr
           ON  lr."Name"          = p."Name"
           AND lr."LatestOrdinal" = (p."VersionInfo":"Ordinal")::NUMBER
    WHERE  p."System" = 'NPM'
),
dependency_totals AS (      -- dependency count for each latest-released version
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS "DepCount"
    FROM   DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN   latest_versions lv
           ON  lv."Name"    = d."Name"
           AND lv."Version" = d."Version"
    WHERE  d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
),
top_pkg AS (                -- the package whose latest release has the most dependencies
    SELECT "Name"
    FROM   dependency_totals
    ORDER BY "DepCount" DESC NULLS LAST
    LIMIT  1
)
SELECT DISTINCT
       p."Name",
       p."Version",
       f.value:"URL"::STRING AS "GitHub_SourceRepo_URL"
FROM   top_pkg t
JOIN   DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS p
       ON p."Name" = t."Name"
     , LATERAL FLATTEN(input => p."Links") f
WHERE  f.value:"Label"::STRING = 'SOURCE_REPO'
  AND  f.value:"URL"::STRING ILIKE '%github.com%';
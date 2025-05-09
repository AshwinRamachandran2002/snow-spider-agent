WITH latest_released AS (   -- latest *released* version (IsRelease = true) for each NPM package
    SELECT
        pv."Name",
        pv."Version",
        pv."Links",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY COALESCE(pv."UpstreamPublishedAt",0) DESC, pv."SnapshotAt" DESC
        ) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT LIKE '%@%'                       -- exclude scoped packages
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE   -- released versions only
),
latest_per_pkg AS (
    SELECT "Name","Version","Links"
    FROM latest_released
    WHERE rn = 1
),
dep_counts AS (          -- count dependencies for those latest versions
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS dep_count
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN latest_per_pkg lp
      ON lp."Name" = d."Name"
     AND lp."Version" = d."Version"
    WHERE d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
),
top_pkg AS (             -- package whose latest version has most deps
    SELECT
        dc.*,
        ROW_NUMBER() OVER (ORDER BY dc.dep_count DESC, dc."Name" ASC, dc."Version" ASC) AS rn
    FROM dep_counts dc
)
SELECT
    fl.value:"URL"::STRING AS "GitHub_URL"
FROM top_pkg tp
JOIN latest_per_pkg lp
  ON lp."Name" = tp."Name"
 AND lp."Version" = tp."Version"
, LATERAL FLATTEN(input => lp."Links") fl         -- unpack Links array
WHERE tp.rn = 1
  AND fl.value:"Label"::STRING = 'SOURCE_REPO'    -- keep SOURCE_REPO links
  AND fl.value:"URL"::STRING ILIKE '%github.com%' -- only GitHub URLs
LIMIT 1;
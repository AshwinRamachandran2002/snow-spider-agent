WITH latest AS (
    SELECT
        "Name",
        MAX("VersionInfo":"Ordinal"::NUMBER) AS "LatestOrdinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "Name" NOT ILIKE '%@%'                       -- unscoped packages only
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE    -- released versions only
    GROUP BY "Name"
),
latest_versions AS (
    SELECT
        p."Name",
        p."Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS p
    JOIN latest l
      ON p."Name" = l."Name"
     AND p."VersionInfo":"Ordinal"::NUMBER = l."LatestOrdinal"
    WHERE p."System" = 'NPM'
      AND p."VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
dep_counts AS (
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS "DepCount"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    JOIN latest_versions lv
      ON d."Name"    = lv."Name"
     AND d."Version" = lv."Version"
    GROUP BY d."Name", d."Version"
)
SELECT
    f.value:"URL"::STRING AS "GitHub_SourceRepo_URL"
FROM dep_counts c
JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS p
  ON p."Name"    = c."Name"
 AND p."Version" = c."Version",
LATERAL FLATTEN(input => p."Links") f
WHERE p."System" = 'NPM'
  AND f.value:"Label"::STRING = 'SOURCE_REPO'
  AND f.value:"URL"::STRING ILIKE '%github.com%'
ORDER BY c."DepCount" DESC NULLS LAST
LIMIT 1;
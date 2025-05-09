WITH latest_releases AS (
    -- latest *released* version (highest Ordinal) of every NPM package w/o “@”
    SELECT
        pv."Name",
        MAX(pv."VersionInfo":"Ordinal"::NUMBER) AS "MaxOrdinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT ILIKE '%@%'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
    GROUP BY pv."Name"
),
dependency_totals AS (
    -- how many direct dependency rows each version has
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS "Dependencies_Count"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
    WHERE d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
),
most_dependent_pkg AS (
    -- pick the single latest-release version with the highest dependency count
    SELECT
        pv."Name",
        pv."Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    JOIN latest_releases lr
      ON pv."Name" = lr."Name"
     AND pv."VersionInfo":"Ordinal"::NUMBER = lr."MaxOrdinal"
    LEFT JOIN dependency_totals dt
      ON pv."Name" = dt."Name"
     AND pv."Version" = dt."Version"
    ORDER BY COALESCE(dt."Dependencies_Count", 0) DESC NULLS LAST
    LIMIT 1
)
-- extract the GitHub SOURCE_REPO link for that package version
SELECT
    md."Name",
    md."Version",
    f.value:"URL"::STRING AS "GitHub_SOURCE_REPO_URL"
FROM most_dependent_pkg md
JOIN DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
  ON md."Name" = pv."Name"
 AND md."Version" = pv."Version",
LATERAL FLATTEN(input => pv."Links") f
WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
  AND f.value:"URL"::STRING ILIKE '%github.com%';
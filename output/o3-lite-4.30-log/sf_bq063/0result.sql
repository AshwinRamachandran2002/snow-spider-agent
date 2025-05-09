WITH releases AS (
    SELECT
        "Name",
        "Version",
        "VersionInfo":"Ordinal"::INTEGER AS "Ordinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "Name" NOT LIKE '%@%'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
),
latest AS (
    SELECT
        "Name",
        "Version",
        "Ordinal"
    FROM (
        SELECT
            "Name",
            "Version",
            "Ordinal",
            ROW_NUMBER() OVER (PARTITION BY "Name"
                               ORDER BY "Ordinal" DESC NULLS LAST) AS rn
        FROM releases
    )
    WHERE rn = 1
),
deps_cnt AS (
    SELECT
        l."Name",
        l."Version",
        COUNT(*) AS cnt
    FROM latest l
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
      ON d."System" = 'NPM'
     AND d."Name"  = l."Name"
     AND d."Version" = l."Version"
    GROUP BY l."Name", l."Version"
),
max_pkg AS (
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            cnt,
            ROW_NUMBER() OVER (ORDER BY cnt DESC NULLS LAST, "Name") AS rn
        FROM deps_cnt
    )
    WHERE rn = 1
)
SELECT DISTINCT
       f.value:"URL"::STRING AS "SOURCE_REPO"
FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS p
JOIN max_pkg m
  ON p."System"  = 'NPM'
 AND p."Name"    = m."Name"
 AND p."Version" = m."Version",
LATERAL FLATTEN(input => p."Links") f
WHERE f.value:"Label"::STRING = 'SOURCE_REPO'
  AND f.value:"URL"::STRING ILIKE '%github.com%'
ORDER BY "SOURCE_REPO"
LIMIT 1;
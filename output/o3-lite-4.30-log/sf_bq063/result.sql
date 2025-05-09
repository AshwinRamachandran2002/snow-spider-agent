WITH latest_releases AS (
    SELECT
        pv."Name",
        pv."Version",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY (pv."VersionInfo":"Ordinal")::INT DESC NULLS LAST,
                     pv."Version" DESC
        ) AS rn
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."Name" NOT ILIKE '%@%'
      AND COALESCE((pv."VersionInfo":"IsRelease")::BOOLEAN, FALSE) = TRUE
),
latest AS (
    SELECT "Name", "Version"
    FROM latest_releases
    WHERE rn = 1
),
dep_counts AS (
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS dependency_cnt
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    WHERE d."System" = 'NPM'
    GROUP BY d."Name", d."Version"
),
candidate AS (
    SELECT
        l."Name",
        l."Version",
        COALESCE(dc.dependency_cnt, 0) AS dependency_cnt
    FROM latest l
    LEFT JOIN dep_counts dc
      ON l."Name" = dc."Name"
     AND l."Version" = dc."Version"
),
with_links AS (
    SELECT
        c."Name",
        c."Version",
        c.dependency_cnt,
        fl.value:"URL"::STRING AS SOURCE_REPO
    FROM candidate c
    JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
      ON pv."Name" = c."Name"
     AND pv."Version" = c."Version"
    , LATERAL FLATTEN(input => pv."Links") fl
    WHERE fl.value:"Label"::STRING = 'SOURCE_REPO'
      AND fl.value:"URL"::STRING ILIKE '%github.com%'
)
SELECT
    SOURCE_REPO
FROM with_links
ORDER BY dependency_cnt DESC, SOURCE_REPO ASC
LIMIT 1;
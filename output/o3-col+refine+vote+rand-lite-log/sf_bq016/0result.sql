WITH latest_releases AS (
    SELECT
        "Name",
        "Version"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
               PARTITION BY "Name"
               ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
           ) = 1
),
dep_list AS (
    SELECT
        d."Dependency":"Name"::STRING    AS "DepName",
        d."Dependency":"Version"::STRING AS "DepVersion"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    JOIN latest_releases lr
      ON d."System"  = 'NPM'
     AND d."Name"    = lr."Name"
     AND d."Version" = lr."Version"
)
SELECT
    "DepName",
    "DepVersion",
    COUNT(*) AS "Appearances"
FROM dep_list
GROUP BY
    "DepName",
    "DepVersion"
ORDER BY
    "Appearances" DESC NULLS LAST
LIMIT 1;
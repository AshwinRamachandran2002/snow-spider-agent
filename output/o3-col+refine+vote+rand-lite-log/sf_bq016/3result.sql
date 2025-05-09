WITH highest_release AS (
    SELECT
        "Name",
        "Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND COALESCE("VersionInfo":"IsRelease"::BOOLEAN, FALSE)
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY "Name"
              ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC NULLS LAST
            ) = 1
),
deps AS (
    SELECT
        d."Dependency":"Name"::STRING    AS "DepName",
        d."Dependency":"Version"::STRING AS "DepVersion"
    FROM highest_release hr
    JOIN DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
      ON d."System"  = 'NPM'
     AND d."Name"    = hr."Name"
     AND d."Version" = hr."Version"
)
SELECT
    "DepName",
    "DepVersion",
    COUNT(*) AS "AppearanceCount"
FROM deps
GROUP BY "DepName", "DepVersion"
ORDER BY "AppearanceCount" DESC NULLS LAST
LIMIT 1;
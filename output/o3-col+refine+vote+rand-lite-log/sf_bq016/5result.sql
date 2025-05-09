-- Dependency (package + version) that appears most often among
-- the dependencies of the highest-release NPM package versions
WITH highest_release AS (
    SELECT
        "Name",
        "Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY "Name"
              ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
           ) = 1
),
all_deps AS (
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
    "DepName"    AS "MostFrequentDependency",
    "DepVersion" AS "Version",
    COUNT(*)     AS "Frequency"
FROM all_deps
GROUP BY "DepName", "DepVersion"
ORDER BY "Frequency" DESC NULLS LAST
LIMIT 1;
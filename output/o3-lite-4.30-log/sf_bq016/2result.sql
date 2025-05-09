WITH highest_release AS (
    SELECT
        pv."Name",
        pv."Version"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND pv."VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY pv."Name"
        ORDER BY pv."VersionInfo":"Ordinal"::NUMBER DESC
    ) = 1
),
deps AS (
    SELECT
        d."Dependency":"Name"::STRING    AS dependency_name,
        d."Dependency":"Version"::STRING AS dependency_version
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    JOIN highest_release hr
      ON d."Name"    = hr."Name"
     AND d."Version" = hr."Version"
    WHERE d."System" = 'NPM'
      AND d."Dependency":"System"::STRING = 'NPM'
)
SELECT
    dependency_name,
    dependency_version,
    COUNT(*) AS appearance_count
FROM deps
WHERE dependency_name IS NOT NULL
GROUP BY dependency_name, dependency_version
ORDER BY appearance_count DESC NULLS LAST,
         dependency_name,
         dependency_version
LIMIT 1;
WITH highest_release AS (
    SELECT
        "Name",
        "Version"
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS"
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY "VersionInfo":"Ordinal"::NUMBER =
            MAX("VersionInfo":"Ordinal"::NUMBER) OVER (PARTITION BY "Name")
),
deps AS (
    SELECT
        PARSE_JSON(d."Dependency"):"Name"::TEXT    AS dependency_name,
        PARSE_JSON(d."Dependency"):"Version"::TEXT AS dependency_version
    FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."DEPENDENCIES" d
    JOIN highest_release hr
      ON d."Name"    = hr."Name"
     AND d."Version" = hr."Version"
    WHERE d."System" = 'NPM'
)
SELECT
    dependency_name,
    dependency_version,
    COUNT(*) AS appearance_count
FROM deps
GROUP BY dependency_name, dependency_version
ORDER BY appearance_count DESC NULLS LAST
LIMIT 1;
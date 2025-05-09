WITH latest_release AS (
    SELECT
        "Name",
        "Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
      AND "VersionInfo":"IsRelease"::BOOLEAN = TRUE
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY "VersionInfo":"Ordinal"::NUMBER DESC
            ) = 1
),
deps AS (
    SELECT
        d."Dependency":"Name"::STRING    AS dep_name,
        d."Dependency":"Version"::STRING AS dep_version
    FROM latest_release p
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
      ON d."System"  = 'NPM'
     AND d."Name"    = p."Name"
     AND d."Version" = p."Version"
)
SELECT
    dep_name       AS "Most_Common_Dep_Name",
    dep_version    AS "Most_Common_Dep_Version",
    COUNT(*)       AS "Appearance_Count"
FROM deps
GROUP BY dep_name, dep_version
ORDER BY "Appearance_Count" DESC NULLS LAST
LIMIT 1;
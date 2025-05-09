WITH latest_release AS (
    SELECT
        pv."Name",
        MAX(pv."VersionInfo":"Ordinal") AS "MaxOrdinal"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM'
      AND pv."VersionInfo":"IsRelease" = TRUE
    GROUP BY pv."Name"
),
latest_rows AS (
    SELECT
        pv."Name",
        pv."Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    JOIN latest_release lr
      ON pv."Name" = lr."Name"
     AND pv."VersionInfo":"Ordinal" = lr."MaxOrdinal"
)
SELECT
    d."Dependency":"Name"::STRING    AS dependency_name,
    d."Dependency":"Version"::STRING AS dependency_version,
    COUNT(*)                         AS appearance_count
FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
JOIN latest_rows lr
  ON d."Name" = lr."Name"
 AND d."Version" = lr."Version"
WHERE d."System" = 'NPM'
  AND d."Dependency":"Name" IS NOT NULL
GROUP BY dependency_name, dependency_version
ORDER BY appearance_count DESC NULLS LAST
LIMIT 1;
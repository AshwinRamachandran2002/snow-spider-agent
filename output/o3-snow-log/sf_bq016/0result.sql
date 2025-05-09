WITH highest_release AS (
    SELECT
        pv."Name",
        pv."Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
    WHERE pv."System" = 'NPM'
      AND COALESCE(pv."VersionInfo":"IsRelease"::BOOLEAN, FALSE) = TRUE
      AND pv."VersionInfo":"Ordinal" IS NOT NULL
    QUALIFY pv."VersionInfo":"Ordinal"::NUMBER =
            MAX(pv."VersionInfo":"Ordinal"::NUMBER)
            OVER (PARTITION BY pv."Name")
)
SELECT
    d."Dependency":"Name"::TEXT    AS "DependencyName",
    d."Dependency":"Version"::TEXT AS "DependencyVersion",
    COUNT(*)                       AS "Frequency"
FROM DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" d
JOIN highest_release hr
  ON d."System" = 'NPM'
 AND d."Name"   = hr."Name"
 AND d."Version"= hr."Version"
GROUP BY
    "DependencyName",
    "DependencyVersion"
ORDER BY
    "Frequency" DESC NULLS LAST
LIMIT 1;
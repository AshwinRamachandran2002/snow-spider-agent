WITH highest_releases AS (
    /* highest released version for every NPM package */
    SELECT
        sub."Name",
        sub."Version"
    FROM (
        SELECT
            pv."Name",
            pv."Version",
            (pv."VersionInfo":IsRelease)::BOOLEAN                              AS is_release,
            (pv."VersionInfo":Ordinal)::NUMBER                                 AS ord,
            ROW_NUMBER() OVER (PARTITION BY pv."Name"
                               ORDER BY (pv."VersionInfo":Ordinal)::NUMBER DESC NULLS LAST) AS rn
        FROM DEPS_DEV_V1.DEPS_DEV_V1."PACKAGEVERSIONS" pv
        WHERE pv."System" = 'NPM'
    ) sub
    WHERE is_release = TRUE
      AND rn = 1
)

SELECT
    dep."Dependency":"Name"::STRING    AS "DependencyPackage",
    dep."Dependency":"Version"::STRING AS "DependencyVersion",
    COUNT(*)                           AS "Frequency"
FROM DEPS_DEV_V1.DEPS_DEV_V1."DEPENDENCIES" dep
JOIN highest_releases hr
      ON  hr."Name"    = dep."Name"
      AND hr."Version" = dep."Version"
WHERE dep."System" = 'NPM'
  AND dep."Dependency":"System"::STRING = 'NPM'
GROUP BY "DependencyPackage", "DependencyVersion"
ORDER BY "Frequency" DESC NULLS LAST
LIMIT 1;
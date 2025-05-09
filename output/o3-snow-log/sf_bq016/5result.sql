WITH "highest_release" AS (
    SELECT
        "Name",
        "Version"
    FROM (
        SELECT
            "Name",
            "Version",
            ("VersionInfo":"Ordinal")::NUMBER                    AS "ord",
            ROW_NUMBER() OVER (
                PARTITION BY "Name"
                ORDER BY ("VersionInfo":"Ordinal")::NUMBER DESC NULLS LAST
            )                                                   AS "rn"
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE "System" = 'NPM'
          AND ("VersionInfo":"IsRelease")::BOOLEAN = TRUE
    )
    WHERE "rn" = 1
)

SELECT
    d."Dependency":"Name"::STRING    AS "DependencyName",
    d."Dependency":"Version"::STRING AS "DependencyVersion",
    COUNT(*)                         AS "Frequency"
FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
JOIN "highest_release" hr
      ON d."Name"    = hr."Name"
     AND d."Version" = hr."Version"
WHERE d."System" = 'NPM'
GROUP BY
    "DependencyName",
    "DependencyVersion"
ORDER BY
    "Frequency" DESC NULLS LAST
LIMIT 1;
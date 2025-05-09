SELECT
    t."PackageName",
    t."Version"
FROM (
    SELECT
        pv."Name" AS "PackageName",
        pv."Version",
        p."StarsCount" AS "StarCount",
        ROW_NUMBER() OVER (
            PARTITION BY pv."Name"
            ORDER BY pv."VersionInfo":"Ordinal" DESC
        ) AS rn
    FROM
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
    JOIN
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvp
        ON
            pv."Name" = pvp."Name" AND
            pv."Version" = pvp."Version"
    JOIN
        "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" p
        ON
            pvp."ProjectName" = p."Name"
    WHERE
        pv."System" = 'NPM' AND
        pv."VersionInfo":"IsRelease" = TRUE
) t
WHERE
    t.rn = 1
ORDER BY
    t."StarCount" DESC NULLS LAST
LIMIT 8;
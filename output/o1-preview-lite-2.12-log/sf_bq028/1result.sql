SELECT DISTINCT
    pv_sub."Name" AS "Package_Name",
    pv_sub."Version",
    p."StarsCount" AS "Stars"
FROM
    (
        SELECT
            pv_sub."Name",
            pv_sub."Version"
        FROM
            "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv_sub
        WHERE
            pv_sub."System" ILIKE 'npm' AND pv_sub."UpstreamPublishedAt" IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY pv_sub."Name"
            ORDER BY pv_sub."UpstreamPublishedAt" DESC NULLS LAST
        ) = 1
    ) pv_sub
JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvtp
    ON pv_sub."Name" = pvtp."Name" AND pvtp."ProjectType" ILIKE 'github'
JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" p
    ON pvtp."ProjectName" = p."Name" AND p."Type" ILIKE 'github' AND p."StarsCount" IS NOT NULL
ORDER BY
    p."StarsCount" DESC NULLS LAST
LIMIT 8;
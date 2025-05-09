SELECT
    pv."Name" AS "Package_Name",
    pv."Version",
    COUNT(*) AS "Dependent_Count"
FROM (
    SELECT
        "Name",
        "Version",
        ROW_NUMBER() OVER (PARTITION BY "Name" ORDER BY "UpstreamPublishedAt" DESC NULLS LAST) AS rn
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
    WHERE "System" = 'NPM'
) pv
JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENTS d
    ON pv."Name" = d."Name"
    AND pv."Version" = d."Version"
    AND d."System" = 'NPM'
WHERE pv.rn = 1
GROUP BY pv."Name", pv."Version"
ORDER BY "Dependent_Count" DESC NULLS LAST
LIMIT 1;
SELECT d."Name" AS Package_Name, d."Version", COUNT(*) AS Dependent_Count
FROM DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENTS d
INNER JOIN (
    SELECT pv."Name", pv."Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    INNER JOIN (
        SELECT "Name", MAX("UpstreamPublishedAt") AS "LatestPublishedAt"
        FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS
        WHERE LOWER("System") = 'npm'
        GROUP BY "Name"
    ) latestVersions ON pv."Name" = latestVersions."Name" AND pv."UpstreamPublishedAt" = latestVersions."LatestPublishedAt"
    WHERE LOWER(pv."System") = 'npm'
) hv ON d."Name" = hv."Name" AND d."Version" = hv."Version"
WHERE LOWER(d."System") = 'npm'
GROUP BY d."Name", d."Version"
ORDER BY Dependent_Count DESC NULLS LAST
LIMIT 1;
SELECT pv."Name" AS "Package_Name", pv."Version", COUNT(d."Dependent") AS "Dependent_Count"
FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
JOIN DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENTS d
  ON pv."Name" = d."Name" AND pv."Version" = d."Version"
WHERE pv."System" = 'NPM' AND d."System" = 'NPM' 
  AND pv."UpstreamPublishedAt" = (
    SELECT MAX(pv2."UpstreamPublishedAt")
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv2
    WHERE pv2."System" = 'NPM' AND pv2."Name" = pv."Name"
)
GROUP BY pv."Name", pv."Version"
ORDER BY "Dependent_Count" DESC NULLS LAST
LIMIT 1;
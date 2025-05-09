WITH latest_versions AS (
  SELECT pv."Name", pv."Version",
    ROW_NUMBER() OVER (PARTITION BY pv."Name" ORDER BY pv."UpstreamPublishedAt" DESC) AS rn
  FROM "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONS" pv
  WHERE pv."System" = 'NPM' AND pv."UpstreamPublishedAt" IS NOT NULL
),
latest_npm_versions AS (
  SELECT lv."Name", lv."Version"
  FROM latest_versions lv
  WHERE lv.rn = 1
),
package_projects AS (
  SELECT lv."Name", lv."Version", pvp."ProjectType", pvp."ProjectName"
  FROM latest_npm_versions lv
  JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PACKAGEVERSIONTOPROJECT" pvp
    ON lv."Name" = pvp."Name" AND lv."Version" = pvp."Version" AND pvp."System" = 'NPM'
),
package_stars AS (
  SELECT pp."Name", pp."Version", pr."StarsCount"
  FROM package_projects pp
  JOIN "DEPS_DEV_V1"."DEPS_DEV_V1"."PROJECTS" pr
    ON pp."ProjectType" = pr."Type" AND pp."ProjectName" = pr."Name"
  WHERE pr."StarsCount" IS NOT NULL AND pr."StarsCount" > 0
),
distinct_packages AS (
  SELECT ps."Name", ps."Version", ps."StarsCount",
    ROW_NUMBER() OVER (PARTITION BY ps."Name" ORDER BY ps."StarsCount" DESC) AS rn
  FROM package_stars ps
)
SELECT dp."Name" AS "Package_Name", dp."Version", dp."StarsCount" AS "Stars"
FROM distinct_packages dp
WHERE dp.rn = 1
ORDER BY dp."StarsCount" DESC NULLS LAST
LIMIT 8;
WITH LatestVersions AS (
    SELECT
        pv."Name" AS "PackageName",
        MAX(pv."UpstreamPublishedAt") AS "LatestPublishedAt"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    WHERE pv."System" = 'NPM' AND pv."UpstreamPublishedAt" IS NOT NULL
    GROUP BY pv."Name"
),
LatestPackageVersions AS (
    SELECT
        pv."Name",
        pv."Version"
    FROM DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
    JOIN LatestVersions lv
        ON pv."Name" = lv."PackageName"
           AND pv."UpstreamPublishedAt" = lv."LatestPublishedAt"
    WHERE pv."System" = 'NPM'
),
PackageProject AS (
    SELECT
        lpv."Name" AS "PackageName",
        lpv."Version",
        MAX(p."StarsCount") AS "GitHubStars"
    FROM LatestPackageVersions lpv
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONTOPROJECT pvtp
        ON lpv."Name" = pvtp."Name"
           AND lpv."Version" = pvtp."Version"
           AND pvtp."System" = 'NPM'
    JOIN DEPS_DEV_V1.DEPS_DEV_V1.PROJECTS p
        ON pvtp."ProjectType" = p."Type"
           AND pvtp."ProjectName" = p."Name"
    GROUP BY lpv."Name", lpv."Version"
)
SELECT
    "PackageName",
    "Version"
FROM PackageProject
ORDER BY "GitHubStars" DESC NULLS LAST
LIMIT 8;
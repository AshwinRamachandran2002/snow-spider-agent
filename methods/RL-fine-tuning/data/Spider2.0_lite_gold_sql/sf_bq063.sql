WITH DependencyCounts AS (
    SELECT
        d."Name",
        d."Version",
        COUNT(*) AS "DependencyCount"
    FROM
        DEPS_DEV_V1.DEPS_DEV_V1.DEPENDENCIES d
    WHERE
        d."System" = 'NPM'
        AND d."Name" NOT LIKE '%@%'
    GROUP BY
        d."Name",
        d."Version"
),
MaxDependencyCount AS (
    SELECT MAX("DependencyCount") AS "MaxDepCount"
    FROM DependencyCounts
),
HighestDependencies AS (
    SELECT dc."Name", dc."Version", dc."DependencyCount"
    FROM DependencyCounts dc
    WHERE dc."DependencyCount" = (SELECT "MaxDepCount" FROM MaxDependencyCount)
),
PackagesWithGitHubURL AS (
    SELECT
        hd."Name",
        hd."Version",
        pv."UpstreamPublishedAt",
        l.value:"URL"::STRING AS "GitHub_URL"
    FROM
        HighestDependencies hd
    JOIN
        DEPS_DEV_V1.DEPS_DEV_V1.PACKAGEVERSIONS pv
            ON hd."Name" = pv."Name" AND hd."Version" = pv."Version"
        , LATERAL FLATTEN(input => pv."Links") l
    WHERE
        pv."System" = 'NPM'
        AND pv."Name" NOT LIKE '%@%'
        AND l.value:"Label"::STRING = 'SOURCE_REPO'
),
LatestPackage AS (
    SELECT
        pwg."GitHub_URL",
        ROW_NUMBER() OVER (ORDER BY pwg."UpstreamPublishedAt" DESC NULLS LAST) AS rn
    FROM
        PackagesWithGitHubURL pwg
)
SELECT
    "GitHub_URL"
FROM
    LatestPackage
WHERE
    rn = 1;
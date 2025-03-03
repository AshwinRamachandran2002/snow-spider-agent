SELECT
    r."repo_name" AS "Repository_Name",
    r."watch_count" AS "Total_Combined_Count"
FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    INNER JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LICENSES" l ON f."repo_name" = l."repo_name"
    INNER JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_REPOS" r ON f."repo_name" = r."repo_name"
WHERE
    f."ref" = 'refs/heads/master'
    AND f."path" ILIKE '%.py'
    AND l."license" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
ORDER BY
    r."watch_count" DESC NULLS LAST
LIMIT 1;
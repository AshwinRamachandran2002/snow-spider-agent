SELECT
    w."repo":"name"::STRING AS "repo_name",
    COUNT(DISTINCT w."actor":"id") AS "watcher_count"
FROM
    "GITHUB_REPOS_DATE"."YEAR"."_2017" AS w
JOIN
    "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES" AS s
    ON w."repo":"name"::STRING = s."repo_name"
WHERE
    w."type" = 'WatchEvent'
GROUP BY
    w."repo":"name"::STRING
HAVING
    COUNT(DISTINCT w."actor":"id") > 300
ORDER BY
    "watcher_count" DESC NULLS LAST
LIMIT 2;
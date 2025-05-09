SELECT
    t."repo":"name"::STRING AS "repo_name",
    COUNT(DISTINCT t."actor":"id"::NUMBER) AS "watcher_count"
FROM
    "GITHUB_REPOS_DATE"."YEAR"."_2017" t
JOIN
    (SELECT DISTINCT "repo_name"
     FROM "GITHUB_REPOS_DATE"."GITHUB_REPOS"."SAMPLE_FILES") s
    ON t."repo":"name"::STRING = s."repo_name"
WHERE
    t."type" = 'WatchEvent'
GROUP BY
    t."repo":"name"::STRING
HAVING
    COUNT(DISTINCT t."actor":"id"::NUMBER) > 300
ORDER BY
    "watcher_count" DESC NULLS LAST
LIMIT 2;
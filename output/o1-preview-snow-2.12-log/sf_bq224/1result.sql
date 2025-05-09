SELECT e."repo_name",
       e."fork_count",
       e."issues_count",
       e."watch_count",
       e."total_events",
       l."license"
FROM
(
    SELECT "repo"::VARIANT['name']::STRING AS "repo_name",
           SUM(CASE WHEN "type" = 'ForkEvent' THEN 1 ELSE 0 END) AS "fork_count",
           SUM(CASE WHEN "type" = 'IssuesEvent' THEN 1 ELSE 0 END) AS "issues_count",
           SUM(CASE WHEN "type" = 'WatchEvent' THEN 1 ELSE 0 END) AS "watch_count",
           SUM(CASE WHEN "type" IN ('ForkEvent', 'IssuesEvent', 'WatchEvent') THEN 1 ELSE 0 END) AS "total_events"
    FROM "GITHUB_REPOS_DATE"."MONTH"."_202204"
    GROUP BY "repo_name"
) e
JOIN "GITHUB_REPOS_DATE"."GITHUB_REPOS"."LICENSES" l
    ON e."repo_name" = l."repo_name"
WHERE l."license" IN ('mit', 'apache-2.0', 'GPL-3.0')
ORDER BY e."total_events" DESC NULLS LAST
LIMIT 1;
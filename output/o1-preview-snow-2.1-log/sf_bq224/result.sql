SELECT
  l."repo_name",
  SUM(CASE WHEN m."type" = 'ForkEvent' THEN 1 ELSE 0 END) AS fork_count,
  SUM(CASE WHEN m."type" = 'IssuesEvent' THEN 1 ELSE 0 END) AS issue_count,
  SUM(CASE WHEN m."type" = 'WatchEvent' THEN 1 ELSE 0 END) AS watch_count,
  (SUM(CASE WHEN m."type" = 'ForkEvent' THEN 1 ELSE 0 END)
   + SUM(CASE WHEN m."type" = 'IssuesEvent' THEN 1 ELSE 0 END)
   + SUM(CASE WHEN m."type" = 'WatchEvent' THEN 1 ELSE 0 END)) AS total_count
FROM
  GITHUB_REPOS_DATE.GITHUB_REPOS.LICENSES l
JOIN
  (
    SELECT
      m."repo":"name"::STRING AS "repo_name",
      m."type"
    FROM
      GITHUB_REPOS_DATE.MONTH."_202204" m
  ) m
  ON l."repo_name" = m."repo_name"
WHERE
  l."license" IN ('mit', 'apache-2.0')
GROUP BY
  l."repo_name"
ORDER BY
  total_count DESC NULLS LAST,
  l."repo_name" ASC
LIMIT 1;
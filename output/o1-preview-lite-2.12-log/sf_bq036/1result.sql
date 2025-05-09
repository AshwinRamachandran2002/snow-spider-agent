SELECT
  ROUND(AVG(monthly_commits), 4) AS "Average_Commits_per_Month"
FROM (
  SELECT
    TO_CHAR(TO_TIMESTAMP_NTZ(c."author"::VARIANT:"time_sec"), 'YYYY-MM') AS "commit_month",
    COUNT(*) AS monthly_commits
  FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" c
  INNER JOIN (
    SELECT DISTINCT t."repo_name"
    FROM
      "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" t,
      LATERAL FLATTEN(input => t."language") f
    WHERE f.value:"name"::STRING = 'Python'
  ) py_repos ON c."repo_name" = py_repos."repo_name"
  WHERE
    EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ(c."author"::VARIANT:"time_sec")) = 2016
  GROUP BY
    "commit_month"
)
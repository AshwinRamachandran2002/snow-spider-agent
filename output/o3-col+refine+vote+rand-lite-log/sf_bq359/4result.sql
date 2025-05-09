WITH lang_rank AS (
  SELECT
      l."repo_name",
      f.value:"name"::STRING   AS "language_name",
      f.value:"bytes"::NUMBER  AS "bytes",
      ROW_NUMBER() OVER (
          PARTITION BY l."repo_name"
          ORDER BY f.value:"bytes"::NUMBER DESC
      ) AS rn
  FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
       LATERAL FLATTEN(input => l."language") f
),
js_primary_repos AS (
  SELECT "repo_name"
  FROM   lang_rank
  WHERE  rn = 1
    AND  LOWER("language_name") = 'javascript'
)
SELECT
    c."repo_name",
    COUNT(*) AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS c
JOIN js_primary_repos j
  ON c."repo_name" = j."repo_name"
GROUP BY c."repo_name"
ORDER BY "commit_count" DESC NULLS LAST
LIMIT 2;
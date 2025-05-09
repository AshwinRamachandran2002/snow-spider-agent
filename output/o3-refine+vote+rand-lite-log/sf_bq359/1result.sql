WITH js_repos AS (
    SELECT
        "repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    WHERE LOWER(TO_VARCHAR("language")) LIKE '%javascript%'
),
commit_counts AS (
    SELECT
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
)
SELECT
    c."repo_name",
    c."commit_count"
FROM commit_counts c
JOIN js_repos j
  ON c."repo_name" = j."repo_name"
ORDER BY
    c."commit_count" DESC NULLS LAST,
    c."repo_name"
LIMIT 2;
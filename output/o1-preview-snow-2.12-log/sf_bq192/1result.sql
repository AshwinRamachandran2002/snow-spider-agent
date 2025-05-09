SELECT
  r."repo_name" AS "Repository_Name",
  COALESCE(r."watch_count", 0) + COALESCE(fork_count, 0) + COALESCE(issue_count, 0) AS "Total_Combined_Count"
FROM
  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_REPOS r
JOIN
  GITHUB_REPOS.GITHUB_REPOS.LICENSES l ON r."repo_name" = l."repo_name"
JOIN
  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f ON r."repo_name" = f."repo_name"
LEFT JOIN
  (
    SELECT
      "repo_name",
      COUNT(*) AS fork_count
    FROM
      GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE
      "commit" LIKE '%fork%'
      AND TO_VARCHAR(
        TO_TIMESTAMP_NTZ(("committer":"date")::NUMBER / 1000000), 'YYYY-MM'
      ) = '2022-04'
    GROUP BY
      "repo_name"
  ) forks ON r."repo_name" = forks."repo_name"
LEFT JOIN
  (
    SELECT
      "repo_name",
      COUNT(*) AS issue_count
    FROM
      GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    WHERE
      "commit" LIKE '%issue%'
      AND TO_VARCHAR(
        TO_TIMESTAMP_NTZ(("committer":"date")::NUMBER / 1000000), 'YYYY-MM'
      ) = '2022-04'
    GROUP BY
      "repo_name"
  ) issues ON r."repo_name" = issues."repo_name"
WHERE
  l."license" IN ('artistic-2.0', 'isc', 'mit', 'apache-2.0')
  AND f."ref" = 'refs/heads/master'
  AND f."path" LIKE '%.py'
ORDER BY
  "Total_Combined_Count" DESC NULLS LAST
LIMIT 1;
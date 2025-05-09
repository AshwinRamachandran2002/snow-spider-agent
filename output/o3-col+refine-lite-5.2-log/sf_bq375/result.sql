SELECT
  LOWER(SPLIT_PART("path", '.', -1)) AS "winning_extension",
  COUNT(*) AS "file_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
WHERE REGEXP_COUNT("path", '/') > 10
  AND LOWER(SPLIT_PART("path", '.', -1)) IN ('py', 'c', 'ipynb', 'java', 'js')
GROUP BY 1
ORDER BY "file_count" DESC NULLS LAST
LIMIT 1;
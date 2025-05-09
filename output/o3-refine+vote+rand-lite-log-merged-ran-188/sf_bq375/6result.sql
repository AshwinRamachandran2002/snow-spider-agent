SELECT
  "extension"  AS "file_type",
  "file_count"
FROM (
  SELECT
    LOWER(SPLIT_PART("path", '.', -1)) AS "extension",
    COUNT(*)                            AS "file_count"
  FROM
    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
  WHERE
        (LENGTH("path") - LENGTH(REPLACE("path", '/', ''))) > 10     -- directory depth > 10
    AND LOWER(SPLIT_PART("path", '.', -1)) IN ('py', 'c', 'ipynb', 'java', 'js')
  GROUP BY
    "extension"
)
ORDER BY
  "file_count" DESC NULLS LAST
LIMIT 1;
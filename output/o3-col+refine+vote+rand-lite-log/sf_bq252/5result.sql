SELECT
  "sample_repo_name"
FROM
  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE
  "binary" = FALSE
  AND "sample_path" ILIKE '%.swift'
ORDER BY
  "copies" DESC NULLS LAST
LIMIT 1;
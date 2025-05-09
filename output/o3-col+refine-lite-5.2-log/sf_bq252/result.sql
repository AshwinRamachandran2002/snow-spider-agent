WITH swift_files AS (
    SELECT
        "id",
        "sample_repo_name",
        "copies"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.swift'
      AND "binary" = FALSE
),
max_copies AS (
    SELECT MAX("copies") AS max_val
    FROM swift_files
)
SELECT DISTINCT
       sf."sample_repo_name"
FROM swift_files sf
JOIN max_copies mc
  ON sf."copies" = mc.max_val
ORDER BY sf."sample_repo_name";
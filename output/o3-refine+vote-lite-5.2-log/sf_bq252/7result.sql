WITH swift_files AS (
    SELECT 
        "id",
        "copies",
        "sample_repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE ( "binary" = FALSE OR "binary" IS NULL )          -- non‑binary files
      AND LOWER("sample_path") LIKE '%.swift'               -- Swift source code
),
max_copies AS (
    SELECT MAX("copies") AS max_copies
    FROM swift_files
)
SELECT 
    "sample_repo_name"
FROM swift_files
JOIN max_copies
  ON swift_files."copies" = max_copies.max_copies
ORDER BY "sample_repo_name"         -- tie‑breaker, alphabetical
LIMIT 1;
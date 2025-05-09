WITH "SWIFT_FILES" AS (
    SELECT
        "id",
        "copies",
        "sample_repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%.swift'
),
"MAX_COPIES" AS (
    SELECT MAX("copies") AS "max_copies"
    FROM "SWIFT_FILES"
)
SELECT
    "sample_repo_name"
FROM "SWIFT_FILES"
JOIN "MAX_COPIES"
  ON "SWIFT_FILES"."copies" = "MAX_COPIES"."max_copies"
ORDER BY "sample_repo_name"
LIMIT 1;
WITH "SWIFT_BLOBS" AS (
    SELECT
        "id",
        "copies"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE
        "binary" = FALSE
        AND LOWER("sample_path") LIKE '%.swift'
),
"TOP_BLOB" AS (
    SELECT
        "id"
    FROM "SWIFT_BLOBS"
    QUALIFY ROW_NUMBER() OVER (ORDER BY "copies" DESC, "id") = 1
)
SELECT
    "sample_repo_name" AS "repo_name"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
WHERE "id" IN (SELECT "id" FROM "TOP_BLOB")
ORDER BY "sample_repo_name"
LIMIT 1;
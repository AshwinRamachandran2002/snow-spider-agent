WITH non_binary_swift AS (
    SELECT
        "id",
        "sample_repo_name",
        "copies"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE "binary" = FALSE
      AND "sample_path" ILIKE '%.swift'
),
deduplicated AS (
    SELECT
        "id",
        "sample_repo_name",
        "copies",
        ROW_NUMBER() OVER (PARTITION BY "id" ORDER BY "sample_repo_name") AS rn
    FROM non_binary_swift
)
SELECT
    "sample_repo_name" AS repository_name
FROM deduplicated
WHERE rn = 1
ORDER BY "copies" DESC NULLS LAST, "id"
LIMIT 1;
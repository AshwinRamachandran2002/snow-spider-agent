SELECT "repository_name"
FROM (
    SELECT
        "sample_repo_name" AS "repository_name",
        "copies",
        ROW_NUMBER() OVER (
            PARTITION BY "id"
            ORDER BY "copies" DESC, "sample_repo_name"
        ) AS rn
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE "binary" = FALSE
      AND LOWER("sample_path") LIKE '%.swift'
)
WHERE rn = 1
ORDER BY "copies" DESC NULLS LAST
LIMIT 1;
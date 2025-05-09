WITH ranked_swift AS (
    SELECT
        "id",
        "sample_repo_name",
        "copies",
        RANK() OVER (ORDER BY "copies" DESC) AS "rnk"
    FROM
        "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE
        "binary" = FALSE
        AND "sample_path" ILIKE '%.swift'
)
SELECT
    "sample_repo_name" AS repository_name
FROM
    ranked_swift
WHERE
    "rnk" = 1;
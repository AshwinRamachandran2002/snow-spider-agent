SELECT 
    f."repo_name",
    f."id" AS "file_id"
FROM 
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" AS f
JOIN 
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
ON 
    f."id" = c."id"
WHERE 
    f."path" LIKE '%.swift'
    AND c."binary" = FALSE
ORDER BY 
    c."copies" DESC NULLS LAST
LIMIT 1;
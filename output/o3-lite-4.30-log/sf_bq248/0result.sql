SELECT
    ROUND(
        SUM(CASE WHEN c."content" ILIKE '%copyright (c)%' THEN 1 ELSE 0 END)::FLOAT
        / NULLIF(COUNT(*), 0),
        4
    ) AS proportion
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"      f
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"         l
  ON f."repo_name" = l."repo_name"
JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"   c
  ON c."id" = f."id"
WHERE CAST(l."language" AS STRING) NOT ILIKE '%python%'
  AND f."path" ILIKE '%readme.md%';
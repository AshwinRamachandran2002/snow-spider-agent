SELECT
  ROUND(
        SUM(CASE 
              WHEN LOWER(c."content") LIKE '%copyright (c)%' THEN 1 
              ELSE 0 
            END)::FLOAT 
        / NULLIF(COUNT(*),0)
       ,4)                                     AS "proportion",
  COUNT(*)                                     AS "total_readme_files",
  SUM(CASE WHEN LOWER(c."content") LIKE '%copyright (c)%' THEN 1 END)
                                              AS "matching_readme_files"
FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     AS f
JOIN  GITHUB_REPOS.GITHUB_REPOS.LANGUAGES        AS l
      ON f."repo_name" = l."repo_name"
JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
      ON f."id" = c."id"
WHERE LOWER(TO_VARCHAR(l."language")) NOT LIKE '%python%'   -- exclude repos using Python
  AND LOWER(f."path")            LIKE '%readme.md%'         -- only README files
;
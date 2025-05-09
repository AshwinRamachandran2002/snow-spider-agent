SELECT
  "language",
  COUNT(*) AS "file_count"
FROM (
  SELECT
    CASE
      WHEN LOWER(f."path") LIKE '%.asm' OR LOWER(f."path") LIKE '%.nasm'                                                 THEN 'Assembly'
      WHEN LOWER(f."path") LIKE '%.c'   OR LOWER(f."path") LIKE '%.h'                                                    THEN 'C'
      WHEN LOWER(f."path") LIKE '%.c++' OR LOWER(f."path") LIKE '%.cpp'
        OR LOWER(f."path") LIKE '%.h++' OR LOWER(f."path") LIKE '%.hpp'                                                  THEN 'C++'
      WHEN LOWER(f."path") LIKE '%.cs'                                                                                  THEN 'C#'
      WHEN LOWER(f."path") LIKE '%.css'                                                                                 THEN 'CSS'
      WHEN LOWER(f."path") LIKE '%/dockerfile'  OR LOWER(f."path") LIKE 'dockerfile'
        OR LOWER(f."path") LIKE '%.dockerfile'                                                                          THEN 'Dockerfile'
      WHEN LOWER(f."path") LIKE '%.go'                                                                                  THEN 'Go'
      WHEN LOWER(f."path") LIKE '%.html' OR LOWER(f."path") LIKE '%.htm'                                                 THEN 'HTML'
      WHEN LOWER(f."path") LIKE '%.java'                                                                                THEN 'Java'
      WHEN LOWER(f."path") LIKE '%.js'  OR LOWER(f."path") LIKE '%.cjs'                                                  THEN 'JavaScript'
      WHEN LOWER(f."path") LIKE '%.json'                                                                                THEN 'JSON'
      WHEN LOWER(f."path") LIKE '%.php'                                                                                 THEN 'PHP'
      WHEN LOWER(f."path") LIKE '%.py'                                                                                  THEN 'Python'
      WHEN LOWER(f."path") LIKE '%.rb'                                                                                  THEN 'Ruby'
      WHEN LOWER(f."path") LIKE '%.rs'                                                                                  THEN 'Rust'
      WHEN LOWER(f."path") LIKE '%.scss'                                                                                THEN 'SCSS'
      WHEN LOWER(f."path") LIKE '%.sh'  OR LOWER(f."path") LIKE '%.bash'                                                 THEN 'Shell'
      WHEN LOWER(f."path") LIKE '%.swift'                                                                               THEN 'Swift'
      WHEN LOWER(f."path") LIKE '%.ts'                                                                                  THEN 'TypeScript'
      WHEN LOWER(f."path") LIKE '%.xml'                                                                                 THEN 'XML'
      WHEN LOWER(f."path") LIKE '%.yml' OR LOWER(f."path") LIKE '%.yaml'                                                 THEN 'YAML'
      ELSE NULL
    END AS "language"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"      AS f
  JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"   AS c
    ON f."id" = c."id"
  WHERE c."binary" = FALSE
    AND c."content" IS NOT NULL
    AND c."size" > 0
) AS lang_map
WHERE "language" IS NOT NULL
GROUP BY "language"
ORDER BY "file_count" DESC NULLS LAST, "language"
LIMIT 10;
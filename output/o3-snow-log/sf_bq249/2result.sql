SELECT
  SUM(CASE WHEN REGEXP_LIKE(f.value::STRING, '[ \t]+$') THEN 1 ELSE 0 END)                                                   AS "total_trailing",
  SUM(CASE WHEN NOT REGEXP_LIKE(f.value::STRING, '[ \t]+$') 
                AND REGEXP_LIKE(f.value::STRING, '^[ ]')                               THEN 1 ELSE 0 END)                  AS "total_space",
  SUM(CASE WHEN NOT REGEXP_LIKE(f.value::STRING, '[ \t]+$') 
                AND NOT REGEXP_LIKE(f.value::STRING, '^[ ]')                           THEN 1 ELSE 0 END)                  AS "total_other"
FROM  "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  t,
      LATERAL FLATTEN(input => SPLIT(t."content", '\n')) f;
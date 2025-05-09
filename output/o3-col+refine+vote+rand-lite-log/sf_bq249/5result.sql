SELECT
  CASE
    WHEN REGEXP_LIKE(f."VALUE"::STRING, ' $') THEN 'trailing'          -- ends with blank char
    WHEN REGEXP_LIKE(f."VALUE"::STRING, '^ ') THEN 'Space'             -- starts with space
    ELSE 'Other'                                                       -- all other lines
  END                                    AS "line_type",
  COUNT(*)                               AS "total_occurrences"
FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c,
     LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n'))  f
GROUP BY "line_type"
ORDER BY "total_occurrences" DESC NULLS LAST;
SELECT
  CASE
    WHEN REGEXP_LIKE(f.value::STRING, '[ \t]$') THEN 'trailing'
    WHEN REGEXP_LIKE(f.value::STRING, '^[ ]')   THEN 'Space'
    ELSE 'Other'
  END                           AS "line_type",
  COUNT(*)                      AS "total_occurrences"
FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" s,
     LATERAL FLATTEN( INPUT => SPLIT(s."content", '\n') ) AS f
GROUP BY "line_type"
ORDER BY "line_type";
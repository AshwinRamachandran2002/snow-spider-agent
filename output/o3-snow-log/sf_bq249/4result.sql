SELECT
  "line_type",
  COUNT(*) AS "total_occurrences"
FROM (
  SELECT
    CASE
      WHEN REGEXP_LIKE(f.value::STRING, ' *$') 
           AND LENGTH(f.value::STRING) > 0  THEN 'trailing'
      WHEN REGEXP_LIKE(f.value::STRING, '^ ')                   THEN 'Space'
      ELSE 'Other'
    END AS "line_type"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
       LATERAL SPLIT_TO_TABLE(sc."content", '\n') f
)
GROUP BY "line_type"
ORDER BY "total_occurrences" DESC NULLS LAST;
SELECT
  CASE
    WHEN line <> RTRIM(line)                 THEN 'Trailing'         -- ends with blank(s)
    WHEN REGEXP_LIKE(line, '^ ')            THEN 'Space'            -- starts with a space
    ELSE 'Other'                                                    -- all remaining lines
  END                                                     AS "line_type",
  COUNT(*)                                                AS "occurrences"
FROM (
  /* explode every file's content into individual lines */
  SELECT f.VALUE::STRING AS line
  FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
)
GROUP BY "line_type"
ORDER BY "line_type";
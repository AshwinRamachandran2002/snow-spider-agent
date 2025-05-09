SELECT
       category,
       COUNT(*) AS occurrences
FROM   (
          SELECT
                 CASE
                     WHEN REGEXP_LIKE(f.value::string , '[ \t]+$') THEN 'trailing'
                     WHEN REGEXP_LIKE(f.value::string , '^[ ]')    THEN 'Space'
                     ELSE                                            'Other'
                 END AS category
          FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
                 LATERAL FLATTEN ( INPUT => SPLIT(sc."content", '\n') ) f
       )
GROUP  BY category;
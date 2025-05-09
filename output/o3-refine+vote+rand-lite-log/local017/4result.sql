WITH cause_counts AS (  -- count every violation category per calendar year
    SELECT ci.db_year  AS year,
           c.pcf_violation_category            AS cause,
           COUNT(*)                            AS cnt
    FROM   collisions  c
    JOIN   case_ids    ci  ON ci.case_id = c.case_id
    WHERE  c.pcf_violation_category IS NOT NULL
    GROUP  BY ci.db_year, c.pcf_violation_category
),
ranked AS (            -- keep the two most frequent causes for each year
    SELECT year,
           cause,
           cnt,
           ROW_NUMBER() OVER (PARTITION BY year
                              ORDER BY cnt DESC, cause) AS rn
    FROM   cause_counts
),
top2 AS (
    SELECT year, cause, rn
    FROM   ranked
    WHERE  rn <= 2
),
signatures AS (        -- create an ordered “signature” of the top‑2 causes
    SELECT year,
           GROUP_CONCAT(cause, ' | ') AS sig
    FROM (
        SELECT year, cause
        FROM   top2
        ORDER  BY year, rn           -- ensure stable order: #1 then #2
    )
    GROUP BY year
),
sig_usage AS (         -- how many years share each signature?
    SELECT sig, COUNT(*) AS yrs_with_sig
    FROM   signatures
    GROUP  BY sig
)
SELECT s.year
FROM   signatures s
JOIN   sig_usage  u  ON u.sig = s.sig
WHERE  u.yrs_with_sig = 1         -- signature appears in only one year
ORDER  BY s.year;
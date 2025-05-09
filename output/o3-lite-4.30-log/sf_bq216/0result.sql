WITH focal_vec AS (
    SELECT
        f.index            AS idx,
        f.value::FLOAT     AS val
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."ABS_AND_EMB" fp,
         LATERAL FLATTEN(input => fp."embedding_v1") f
    WHERE fp."publication_number" = 'US-9741766-B2'
),
focal_year AS (
    SELECT TO_NUMBER(SUBSTR("filing_date",1,4)) AS yr
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS"
    WHERE "publication_number" = 'US-9741766-B2'
    LIMIT 1
),
candidates AS (
    SELECT ae."publication_number",
           ae."embedding_v1"
    FROM "PATENTS_GOOGLE"."PATENTS_GOOGLE"."ABS_AND_EMB"   ae
    JOIN "PATENTS_GOOGLE"."PATENTS_GOOGLE"."PUBLICATIONS"  p
      ON p."publication_number" = ae."publication_number"
    JOIN focal_year
      ON TO_NUMBER(SUBSTR(p."filing_date",1,4)) = focal_year.yr
    WHERE ae."publication_number" <> 'US-9741766-B2'
)
SELECT
    c."publication_number"
FROM candidates c
CROSS JOIN LATERAL FLATTEN(input => c."embedding_v1") cv
JOIN focal_vec fv
  ON fv.idx = cv.index
GROUP BY c."publication_number"
ORDER BY SUM(fv.val * cv.value::FLOAT) DESC NULLS LAST
LIMIT 5;
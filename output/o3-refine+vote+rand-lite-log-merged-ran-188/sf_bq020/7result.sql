WITH trans AS (
    SELECT
        "reference_name",
        COUNT(*) AS trans_cnt
    FROM "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_TRANSCRIPTOME_201703"
    GROUP BY "reference_name"
),
gen AS (
    SELECT
        "reference_name",
        COUNT(*) AS gen_cnt
    FROM "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_201703"
    GROUP BY "reference_name"
),
total AS (
    SELECT
        COALESCE(trans."reference_name", gen."reference_name")         AS reference_name,
        COALESCE(trans.trans_cnt, 0) + COALESCE(gen.gen_cnt, 0)        AS total_cnt
    FROM trans
    FULL JOIN gen
      ON trans."reference_name" = gen."reference_name"
)
SELECT
    r."name" AS reference_sequence_name
FROM
    "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_REFERENCE_201703" r
JOIN total t
  ON r."name" = t.reference_name
ORDER BY
    (t.total_cnt / NULLIF(r."length", 0)) * 1000 DESC NULLS LAST
LIMIT 1;
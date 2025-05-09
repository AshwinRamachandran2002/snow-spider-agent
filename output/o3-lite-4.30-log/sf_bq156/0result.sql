WITH tp53_mut AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
drg2_expr AS (
    SELECT "ParticipantBarcode",
           AVG(LOG(10, "normalized_count" + 1)) AS "expr"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
flagged AS (
    SELECT e."expr",
           CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "is_mut"
    FROM drg2_expr e
    LEFT JOIN tp53_mut m
      ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (
    SELECT "is_mut",
           COUNT(*)              AS "N",
           SUM("expr")           AS "S",
           SUM(POWER("expr", 2)) AS "Q"
    FROM flagged
    GROUP BY "is_mut"
),
pivot AS (
    SELECT
        MIN(CASE WHEN "is_mut" = 1 THEN "N" END) AS "N_y",
        MIN(CASE WHEN "is_mut" = 1 THEN "S" END) AS "S_y",
        MIN(CASE WHEN "is_mut" = 1 THEN "Q" END) AS "Q_y",
        MIN(CASE WHEN "is_mut" = 0 THEN "N" END) AS "N_n",
        MIN(CASE WHEN "is_mut" = 0 THEN "S" END) AS "S_n",
        MIN(CASE WHEN "is_mut" = 0 THEN "Q" END) AS "Q_n"
    FROM stats
),
vars AS (
    SELECT *,
           ("Q_y" - ("S_y" * "S_y") / "N_y") / ("N_y" - 1) AS "var_y",
           ("Q_n" - ("S_n" * "S_n") / "N_n") / ("N_n" - 1) AS "var_n"
    FROM pivot
)
SELECT ROUND(
           ("S_y" / "N_y" - "S_n" / "N_n") /
           SQRT(("var_y" / "N_y") + ("var_n" / "N_n"))
       , 2) AS "t_score"
FROM vars
WHERE "N_y" >= 10
  AND "N_n" >= 10
  AND "var_y" > 0
  AND "var_n" > 0;
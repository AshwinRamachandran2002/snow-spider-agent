WITH mc3_lgg AS (   -- LGG tumour samples in MC3 with FILTER='PASS'
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode" AS "SampleBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"  = 'LGG'
      AND  "FILTER" = 'PASS'
),

mutated_patients AS (   -- LGG patients carrying a PASS TP53 mutation
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "FILTER"      = 'PASS'
      AND  "Hugo_Symbol" = 'TP53'
),

expr_raw AS (   -- DRG2 expression (log10(normalized_count+1)) for the MC3 tumour samples
    SELECT
           e."ParticipantBarcode",
           LOG(10, e."normalized_count" + 1) AS "log_expr"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
           JOIN mc3_lgg m
             ON  e."ParticipantBarcode" = m."ParticipantBarcode"
             AND e."SampleBarcode"      = m."SampleBarcode"
    WHERE  e."Study"  = 'LGG'
      AND  e."Symbol" = 'DRG2'
),

patient_mean AS (   -- per‑patient average of the log‑transformed expression
    SELECT
           "ParticipantBarcode",
           AVG("log_expr") AS "avg_log_expr"
    FROM   expr_raw
    GROUP  BY "ParticipantBarcode"
),

labelled AS (   -- tag each patient as TP53‑mutated (YES/NO)
    SELECT
           p."ParticipantBarcode",
           p."avg_log_expr",
           CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "TP53_mut"
    FROM   patient_mean p
           LEFT JOIN mutated_patients m
                  ON p."ParticipantBarcode" = m."ParticipantBarcode"
),

group_stats AS (   -- size, mean, variance for each group
    SELECT
           "TP53_mut",
           COUNT(*)                AS n,
           AVG("avg_log_expr")     AS mean,
           VAR_SAMP("avg_log_expr") AS var
    FROM   labelled
    GROUP  BY "TP53_mut"
)

SELECT
       yes.n                      AS "Ny",
       no.n                       AS "Nn",
       yes.mean                   AS "avg_y",
       no.mean                    AS "avg_n",
       (yes.mean - no.mean)
       /
       SQRT( (yes.var / yes.n) + (no.var / no.n) )   AS "tscore"
FROM   (SELECT * FROM group_stats WHERE "TP53_mut" = 'YES') yes,
       (SELECT * FROM group_stats WHERE "TP53_mut" = 'NO')  no;
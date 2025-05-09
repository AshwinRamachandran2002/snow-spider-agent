WITH mutated_patients AS (   -- LGG patients whose tumors carry a PASS‑filtered TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER" = 'PASS'
),
lgg_samples AS (             -- every LGG tumor sample present in the MC3 table
    SELECT DISTINCT
           "ParticipantBarcode",
           "Tumor_SampleBarcode" AS "SampleBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),
drg2_expr AS (               -- log10‑transformed DRG2 expression for those samples
    SELECT
        s."ParticipantBarcode",
        LOG(10, e."normalized_count" + 1) AS "log_expr"       -- use LOG(base, value) for base‑10 log
    FROM lgg_samples s
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
          ON e."SampleBarcode" = s."SampleBarcode"
         AND e."Symbol" = 'DRG2'
),
patient_avg AS (             -- per‑patient mean log expression
    SELECT
        "ParticipantBarcode",
        AVG("log_expr") AS "avg_expr"
    FROM drg2_expr
    GROUP BY "ParticipantBarcode"
),
flagged AS (                 -- tag each patient by TP53 mutation status
    SELECT
        p."ParticipantBarcode",
        p."avg_expr",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "TP53_mut"
    FROM patient_avg p
    LEFT JOIN mutated_patients m
           ON p."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (                   -- group sums needed for Welch’s t‑test
    SELECT
        "TP53_mut",
        COUNT(*)                          AS N,
        SUM("avg_expr")                   AS S,
        SUM(POWER("avg_expr", 2))         AS Q
    FROM flagged
    GROUP BY "TP53_mut"
),
calc AS (                    -- derive Ns, means, variances
    SELECT
        (SELECT N FROM stats WHERE "TP53_mut" = 'YES')                                     AS Ny,
        (SELECT N FROM stats WHERE "TP53_mut" = 'NO')                                      AS Nn,
        (SELECT S / N FROM stats WHERE "TP53_mut" = 'YES')                                 AS avg_y,
        (SELECT S / N FROM stats WHERE "TP53_mut" = 'NO')                                  AS avg_n,
        (SELECT (Q - POWER(S,2)/N) / (N - 1) FROM stats WHERE "TP53_mut" = 'YES')          AS var_y,
        (SELECT (Q - POWER(S,2)/N) / (N - 1) FROM stats WHERE "TP53_mut" = 'NO')           AS var_n
)
SELECT
    Ny,
    Nn,
    avg_y,
    avg_n,
    (avg_y - avg_n) / SQRT( var_y / Ny + var_n / Nn )  AS tscore
FROM calc;
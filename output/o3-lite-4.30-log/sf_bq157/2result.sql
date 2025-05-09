WITH maf_lgg AS (                                   -- unique LGG tumour samples in MAF
    SELECT DISTINCT
           "Tumor_SampleBarcode"  AS sample_barcode,
           "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),
expr_samples AS (                                   -- DRG2 expression for those samples
    SELECT
        m."ParticipantBarcode",
        LOG(10, e."normalized_count" + 1) AS g
    FROM maf_lgg m
    JOIN "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
      ON e."SampleBarcode" = m.sample_barcode
    WHERE e."Study"  = 'LGG'
      AND e."Symbol" = 'DRG2'
),
expr_by_pt AS (                                     -- average per patient across samples
    SELECT
        "ParticipantBarcode",
        AVG(g) AS g
    FROM expr_samples
    GROUP BY "ParticipantBarcode"
),
tp53_mut AS (                                       -- LGG patients with PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
stats AS (                                          -- helper sums for YES / NO
    SELECT
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS grp,
        COUNT(*)                                    AS N,
        SUM(g)                                      AS S,
        SUM(g * g)                                  AS Q
    FROM expr_by_pt p
    LEFT JOIN tp53_mut t
           ON p."ParticipantBarcode" = t."ParticipantBarcode"
    GROUP BY 1
),
calc AS (
    SELECT
        MAX(CASE WHEN grp='YES' THEN N END) AS Ny,
        MAX(CASE WHEN grp='NO'  THEN N END) AS Nn,
        MAX(CASE WHEN grp='YES' THEN S END) AS Sy,
        MAX(CASE WHEN grp='NO'  THEN S END) AS Sn,
        MAX(CASE WHEN grp='YES' THEN Q END) AS Qy,
        MAX(CASE WHEN grp='NO'  THEN Q END) AS Qn
    FROM stats
),
final AS (
    SELECT
        Ny, Nn,
        Sy / Ny                                       AS avg_y,
        Sn / Nn                                       AS avg_n,
        (Qy - Sy*Sy/Ny) / (Ny - 1)                    AS var_y,
        (Qn - Sn*Sn/Nn) / (Nn - 1)                    AS var_n
    FROM calc
)
SELECT
    ROUND( (avg_y - avg_n) / SQRT(var_y / Ny + var_n / Nn), 4 ) AS t_score
FROM final;
/* Welch’s T-score: DRG2 expression (log10(normalized_count+1) averaged per patient)
   LGG patients WITH vs WITHOUT a PASS TP53 mutation                                   */

WITH maf_lgg AS (          -- every LGG participant represented in the MC3 table
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),
tp53_mut AS (              -- LGG participants carrying a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
expr_per_pt AS (           -- mean log10 DRG2 expression per participant
    SELECT
        r."ParticipantBarcode",
        AVG( LOG(10, r."normalized_count" + 1) ) AS g
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" r
    JOIN maf_lgg m
      ON r."ParticipantBarcode" = m."ParticipantBarcode"
    WHERE r."Study"  = 'LGG'
      AND r."Symbol" = 'DRG2'
    GROUP BY r."ParticipantBarcode"
),
grp_sums AS (             -- counts (N), sums (S) and sums-of-squares (Q) per group
    SELECT
        CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS grp,
        COUNT(*)                      AS N,
        SUM(g)                        AS S,
        SUM(g * g)                    AS Q
    FROM expr_per_pt e
    LEFT JOIN tp53_mut t
      ON e."ParticipantBarcode" = t."ParticipantBarcode"
    GROUP BY grp
),
pivot AS (                -- pivot YES / NO into individual columns
    SELECT
        MAX(CASE WHEN grp='YES' THEN N END)  AS Ny,
        MAX(CASE WHEN grp='NO'  THEN N END)  AS Nn,
        MAX(CASE WHEN grp='YES' THEN S END)  AS Sy,
        MAX(CASE WHEN grp='NO'  THEN S END)  AS Sn,
        MAX(CASE WHEN grp='YES' THEN Q END)  AS Qy,
        MAX(CASE WHEN grp='NO'  THEN Q END)  AS Qn
    FROM grp_sums
)
SELECT
    Ny,
    Nn,
    Sy / Ny                                                   AS avg_y,
    Sn / Nn                                                   AS avg_n,
    ( (Sy / Ny) - (Sn / Nn) ) /
    SQRT( ( (Qy - (Sy*Sy)/Ny) / (Ny - 1) ) / Ny
        + ( (Qn - (Sn*Sn)/Nn) / (Nn - 1) ) / Nn )             AS tscore
FROM pivot;
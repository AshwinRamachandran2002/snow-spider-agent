/* Kruskal-Wallis H-statistic for IGF2 expression across ICD-O-3 histology groups */

WITH expr AS (  -- 1. log10-transformed IGF2 counts, drop “[ … ]” codes
    SELECT
        e."ParticipantBarcode",
        LOG(10, e."normalized_count" + 1)  AS "log_expr",
        c."icd_o_3_histology"
    FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED  e
    JOIN  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED            c
          ON e."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE e."Symbol"            = 'IGF2'
      AND e."normalized_count"  IS NOT NULL
      AND c."icd_o_3_histology" NOT RLIKE '^\[.*\]$'          -- exclude bracketed values
),

rank_raw AS (  -- 2. raw ranks
    SELECT
        expr.*,
        RANK() OVER (ORDER BY "log_expr") AS "rnk"
    FROM expr
),

ranked AS (    -- 3. average rank for ties
    SELECT
        "ParticipantBarcode",
        "icd_o_3_histology",
        AVG("rnk") OVER (PARTITION BY "log_expr") AS "avg_rank"
    FROM rank_raw
),

grp AS (       -- 4. per-group sums (keep groups with >1 sample)
    SELECT
        "icd_o_3_histology",
        COUNT(*)                  AS n_i,
        SUM("avg_rank")           AS S_i,
        SUM(POWER("avg_rank",2))  AS Q_i
    FROM ranked
    GROUP BY "icd_o_3_histology"
    HAVING COUNT(*) > 1
),

tot AS (       -- 5. overall totals
    SELECT
        COUNT(*)   AS g_groups,
        SUM(n_i)   AS N_total,
        SUM(S_i)   AS S_tot,
        SUM(Q_i)   AS Q_tot
    FROM grp
),

sum_term AS (  -- 6. Σ(Sᵢ² / nᵢ)
    SELECT SUM(POWER(S_i,2) / n_i) AS S2_over_n
    FROM grp
)

SELECT
    tot.g_groups  AS "total_groups",
    tot.N_total   AS "total_samples",
    (tot.N_total - 1)
      * ( sum_term.S2_over_n - POWER(tot.S_tot,2) / tot.N_total )
      / ( tot.Q_tot          - POWER(tot.S_tot,2) / tot.N_total )  AS "Kruskal_Wallis_H"
FROM tot, sum_term
ORDER BY "Kruskal_Wallis_H" DESC NULLS LAST;
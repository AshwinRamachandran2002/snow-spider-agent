WITH clinical AS (   -- BRCA cases with known histology
    SELECT 
        "patient_id"                AS participant,
        "histological_type"         AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
      AND TRIM("histological_type") NOT IN ('[Not Available]','[Unknown]','Unknown','')
), 
mutation AS (        -- reliable CDH1 mutations in BRCA
    SELECT DISTINCT 
        "ParticipantBarcode"        AS participant
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
), 
clinical_mut AS (    -- merge clinical & mutation info
    SELECT 
        c.histology,
        CASE WHEN m.participant IS NOT NULL THEN 'Mutated' ELSE 'WildType' END AS mutation_status
    FROM clinical c
    LEFT JOIN mutation m
      ON c.participant = m.participant
), 
counts AS (          -- contingency table
    SELECT 
        histology,
        mutation_status,
        COUNT(*)                       AS n
    FROM clinical_mut
    GROUP BY histology, mutation_status
), 
row_totals AS (
    SELECT histology, SUM(n) AS row_total
    FROM counts
    GROUP BY histology
), 
col_totals AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM counts
    GROUP BY mutation_status
), 
filtered_hist AS (   -- keep histologies with >10 total
    SELECT histology
    FROM row_totals
    WHERE row_total > 10
), 
filtered_status AS ( -- keep mutation statuses with >10 total
    SELECT mutation_status
    FROM col_totals
    WHERE col_total  > 10
), 
filtered_counts AS ( -- contingency table after filtering
    SELECT c.histology, c.mutation_status, c.n
    FROM counts c
    JOIN filtered_hist    fh ON c.histology       = fh.histology
    JOIN filtered_status  fs ON c.mutation_status = fs.mutation_status
), 
re_row_totals AS (
    SELECT histology, SUM(n) AS row_total
    FROM filtered_counts
    GROUP BY histology
), 
re_col_totals AS (
    SELECT mutation_status, SUM(n) AS col_total
    FROM filtered_counts
    GROUP BY mutation_status
), 
grand_total AS (
    SELECT SUM(n) AS g_total
    FROM filtered_counts
), 
expected AS (        -- expected counts under independence
    SELECT 
        fc.histology,
        fc.mutation_status,
        fc.n                                                  AS observed,
        (rr.row_total * rc.col_total) / gt.g_total::FLOAT     AS expected
    FROM filtered_counts fc
    JOIN re_row_totals rr   ON fc.histology       = rr.histology
    JOIN re_col_totals rc   ON fc.mutation_status = rc.mutation_status
    CROSS JOIN grand_total gt
), 
chi_square AS (      -- χ² statistic
    SELECT SUM(POWER(observed - expected, 2) / expected) AS chi_square_value
    FROM expected
)
SELECT chi_square_value
FROM chi_square;
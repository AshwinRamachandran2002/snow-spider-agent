/*--------------------------------------------------------------------
  Chi‑square test of association between histological type and CDH1
  mutation status in BRCA patients.
--------------------------------------------------------------------*/
WITH brca_participants AS (          -- BRCA cases present in mutation data
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study" = 'BRCA'
),

clinical_brca AS (                  -- add histology (non‑null)
    SELECT  c."bcr_patient_barcode" AS participant,
            c."histological_type"   AS histological_type        -- explicit alias
    FROM    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
            JOIN brca_participants bp
              ON bp."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE   c."histological_type" IS NOT NULL
),

cdh1_mutated AS (                   -- reliable CDH1 mutation carriers
    SELECT DISTINCT "ParticipantBarcode" AS participant
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"       = 'BRCA'
      AND  "Hugo_Symbol" = 'CDH1'
      AND  "FILTER"      = 'PASS'
),

patient_mut_flag AS (               -- flag each patient as Mutated / Not‑mutated
    SELECT  cb.participant,
            cb.histological_type,
            CASE WHEN cm.participant IS NOT NULL THEN 1 ELSE 0 END AS mutated_flag
    FROM    clinical_brca cb
            LEFT JOIN cdh1_mutated cm
                   ON cb.participant = cm.participant
),

cell_counts AS (                    -- contingency‑table observed counts
    SELECT  histological_type,
            mutated_flag,
            COUNT(*) AS observed
    FROM    patient_mut_flag
    GROUP BY histological_type, mutated_flag
),

row_totals AS (
    SELECT  histological_type,
            SUM(observed) AS row_total
    FROM    cell_counts
    GROUP BY histological_type
),

col_totals AS (
    SELECT  mutated_flag,
            SUM(observed) AS col_total
    FROM    cell_counts
    GROUP BY mutated_flag
),

filtered_histology AS (             -- keep rows with > 10 cases
    SELECT histological_type
    FROM   row_totals
    WHERE  row_total > 10
),

filtered_mutflag AS (               -- keep columns with > 10 cases
    SELECT mutated_flag
    FROM   col_totals
    WHERE  col_total > 10
),

filtered_counts AS (                -- reduced contingency table
    SELECT  c.*
    FROM    cell_counts       c
            JOIN filtered_histology h ON h.histological_type = c.histological_type
            JOIN filtered_mutflag   f ON f.mutated_flag      = c.mutated_flag
),

re_row_totals AS (
    SELECT  histological_type,
            SUM(observed) AS row_total
    FROM    filtered_counts
    GROUP BY histological_type
),

re_col_totals AS (
    SELECT  mutated_flag,
            SUM(observed) AS col_total
    FROM    filtered_counts
    GROUP BY mutated_flag
),

re_grand_total AS (
    SELECT SUM(observed) AS grand_total
    FROM   filtered_counts
),

expected_counts AS (                -- expected frequencies
    SELECT  fc.histological_type,
            fc.mutated_flag,
            fc.observed,
            rt.row_total,
            ct.col_total,
            gt.grand_total,
            (rt.row_total * ct.col_total)::FLOAT / gt.grand_total AS expected
    FROM    filtered_counts fc
            JOIN re_row_totals rt ON rt.histological_type = fc.histological_type
            JOIN re_col_totals ct ON ct.mutated_flag      = fc.mutated_flag
            CROSS JOIN re_grand_total gt
),

chi_square_calc AS (                -- χ² statistic
    SELECT SUM( POWER(observed - expected, 2) / expected ) AS chi_square_value
    FROM   expected_counts
)

SELECT chi_square_value
FROM   chi_square_calc;
/*  Chi-square statistic for association between histological type
    and reliable CDH1 mutation status in BRCA patients               */

WITH reliable_mutations AS (   -- 1.  BRCA tumours with reliable (PASS) CDH1 calls
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"          = 'BRCA'
      AND "Hugo_Symbol"    = 'CDH1'
      AND "FILTER"         = 'PASS'
),
patient_histology AS (         -- 2.  BRCA clinical records with known histology
    SELECT 
        "bcr_patient_barcode"  AS "ParticipantBarcode",
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym"            = 'BRCA'
      AND "histological_type" IS NOT NULL
),
patient_status AS (            -- 3.  Assign mutation status
    SELECT
        ph."ParticipantBarcode",
        ph."histological_type",
        CASE WHEN rm."ParticipantBarcode" IS NOT NULL 
             THEN 'Mutated' ELSE 'Wildtype' END     AS "mutation_status"
    FROM patient_histology ph
    LEFT JOIN reliable_mutations rm 
           ON ph."ParticipantBarcode" = rm."ParticipantBarcode"
),
counts AS (                    -- 4.  Contingency counts
    SELECT
        "histological_type",
        "mutation_status",
        COUNT(*) AS n_cases
    FROM patient_status
    GROUP BY "histological_type", "mutation_status"
),
/* 5.  Filter rows/columns having marginal totals ≤10                 */
row_totals  AS (SELECT "histological_type", SUM(n_cases) AS row_total
                FROM counts GROUP BY "histological_type"),
col_totals  AS (SELECT "mutation_status",  SUM(n_cases) AS col_total
                FROM counts GROUP BY "mutation_status"),
filtered_counts AS (
    SELECT c.*
    FROM counts            c
    JOIN row_totals        r USING ("histological_type")
    JOIN col_totals        k USING ("mutation_status")
    WHERE r.row_total  > 10
      AND k.col_total  > 10
),
/* 6.  Re-compute totals on the filtered table                        */
row_tot2 AS (SELECT "histological_type", SUM(n_cases) AS row_total
             FROM filtered_counts GROUP BY "histological_type"),
col_tot2 AS (SELECT "mutation_status",  SUM(n_cases) AS col_total
             FROM filtered_counts GROUP BY "mutation_status"),
grand_tot AS (SELECT SUM(n_cases) AS grand_total FROM filtered_counts),
/* 7.  Chi-square components                                          */
chi_components AS (
    SELECT 
        fc."histological_type",
        fc."mutation_status",
        fc.n_cases                                           AS observed,
        (rt.row_total * ct.col_total)::FLOAT / gt.grand_total AS expected,
        POWER(fc.n_cases - ((rt.row_total * ct.col_total)::FLOAT / gt.grand_total), 2)
        / ((rt.row_total * ct.col_total)::FLOAT / gt.grand_total)                   AS chi_part
    FROM filtered_counts fc
    JOIN row_tot2  rt USING ("histological_type")
    JOIN col_tot2  ct USING ("mutation_status")
    CROSS JOIN grand_tot gt
),
/* 8.  Final chi-square statistic                                     */
chi_square AS (
    SELECT SUM(chi_part) AS chi_square_value
    FROM chi_components
)

SELECT chi_square_value
FROM chi_square;
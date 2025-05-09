/*  Chi-square statistic: histological type  vs.  reliable CDH1-mutation status in BRCA  */

WITH clinical AS (   -- BRCA cases with a known histological type
    SELECT
        "bcr_patient_barcode"                     AS "patient",
        "histological_type"                       AS "hist_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
      AND TRIM("histological_type") <> ''
),
mutated AS (        -- participants carrying a reliable (FILTER='PASS') CDH1 mutation
    SELECT DISTINCT
        "ParticipantBarcode"                      AS "patient"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
),
combined AS (       -- merge clinical and mutation data, create Yes/No flag
    SELECT
        c."patient",
        c."hist_type",
        CASE WHEN m."patient" IS NULL THEN 'No_Mut' ELSE 'CDH1_Mut' END AS "mut_status"
    FROM clinical c
    LEFT JOIN mutated m
           ON c."patient" = m."patient"
),
/* keep only histological categories with >10 total cases                */
hist_ok AS (
    SELECT "hist_type"
    FROM   combined
    GROUP  BY "hist_type"
    HAVING COUNT(*) > 10
),
filtered AS (
    SELECT *
    FROM   combined
    WHERE  "hist_type" IN (SELECT "hist_type" FROM hist_ok)
),
counts AS (         -- contingency-table cell counts
    SELECT
        "hist_type",
        "mut_status",
        COUNT(*) AS "n"
    FROM filtered
    GROUP BY "hist_type", "mut_status"
),
totals AS (         -- add row, column and grand totals
    SELECT
        "hist_type",
        "mut_status",
        "n",
        SUM("n") OVER (PARTITION BY "hist_type")          AS "row_total",
        SUM("n") OVER (PARTITION BY "mut_status")         AS "col_total",
        SUM("n") OVER ()                                  AS "grand_total"
    FROM counts
),
chi_components AS ( -- chi-square contribution for each cell
    SELECT
        ("n" - ("row_total" * "col_total" / "grand_total")) * 
        ("n" - ("row_total" * "col_total" / "grand_total")) / 
        ("row_total" * "col_total" / "grand_total")       AS "chi_comp"
    FROM totals
    WHERE "col_total" > 10     -- ensure mutation status marginal >10
)
SELECT
    ROUND(SUM("chi_comp"), 4)  AS "chi_square_value"
FROM chi_components;
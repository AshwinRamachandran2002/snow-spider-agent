WITH seqs AS (
    SELECT
        TRY_TO_DOUBLE("RepetitionTime")  AS tr,
        TRY_TO_DOUBLE("EchoTime")        AS te,
        TRY_TO_DOUBLE("SliceThickness")  AS thk
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE LOWER("collection_name") = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            "SeriesDescription" ILIKE '%t2_tse_tra%' OR
            "SeriesDescription" ILIKE '%adc%'
          )
)
SELECT 'combined_overall_average' AS metric,
       ROUND(AVG(tr) + AVG(te) + AVG(thk), 4) AS value
FROM seqs;
WITH series_sizes AS (   -- size of every CT series (MiB)
    SELECT  "PatientID",
            "SeriesInstanceUID",
            SUM("instance_size")/1048576.0    AS series_mib      -- bytes → MiB
    FROM    IDC.IDC_V17.DICOM_ALL
    WHERE   "collection_id" = 'nlst'
      AND   "Modality"      = 'CT'
    GROUP BY "PatientID", "SeriesInstanceUID"
), patient_avg_series AS (       -- average series size per patient
    SELECT  "PatientID",
            AVG(series_mib)      AS patient_avg_series_mib
    FROM    series_sizes
    GROUP BY "PatientID"
), patient_slice_tolerance AS (  -- slice‑interval tolerance per patient
    SELECT  "PatientID",
            MAX(iv) - MIN(iv)    AS slice_tolerance
    FROM   ( SELECT "PatientID",
                    TRY_TO_NUMBER(
                        COALESCE("SpacingBetweenSlices","SliceThickness")
                    ) AS iv
             FROM   IDC.IDC_V17.DICOM_ALL
             WHERE  "collection_id" = 'nlst'
               AND  "Modality"      = 'CT'
           ) AS t
    WHERE  iv IS NOT NULL
    GROUP BY "PatientID"
), slice_top3 AS (               -- top‑3 patients by slice tolerance
    SELECT  pst."PatientID",
            pas.patient_avg_series_mib
    FROM    patient_slice_tolerance pst
    JOIN    patient_avg_series      pas USING ("PatientID")
    ORDER BY pst.slice_tolerance DESC NULLS LAST, pst."PatientID"
    LIMIT 3
), patient_exposure_diff AS (    -- exposure difference per patient
    SELECT  "PatientID",
            MAX(ev) - MIN(ev)    AS exposure_diff
    FROM   ( SELECT "PatientID",
                    TRY_TO_NUMBER("Exposure") AS ev
             FROM   IDC.IDC_V17.DICOM_ALL
             WHERE  "collection_id" = 'nlst'
               AND  "Modality"      = 'CT'
           ) AS t
    WHERE  ev IS NOT NULL
    GROUP BY "PatientID"
), exposure_top3 AS (            -- top‑3 patients by exposure difference
    SELECT  ped."PatientID",
            pas.patient_avg_series_mib
    FROM    patient_exposure_diff ped
    JOIN    patient_avg_series    pas USING ("PatientID")
    ORDER BY ped.exposure_diff DESC NULLS LAST, ped."PatientID"
    LIMIT 3
), results AS (                  -- average (MiB) of the three patients in each group
    SELECT 'Top 3 by Slice Interval' AS group_label,
           ROUND(AVG(patient_avg_series_mib), 4) AS average_series_size_mib
    FROM   slice_top3
    UNION ALL
    SELECT 'Top 3 by Max Exposure',
           ROUND(AVG(patient_avg_series_mib), 4)
    FROM   exposure_top3
)
SELECT group_label,
       average_series_size_mib
FROM   results;
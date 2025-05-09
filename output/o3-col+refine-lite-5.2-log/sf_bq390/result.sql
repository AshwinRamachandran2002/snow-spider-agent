WITH t2_studies AS (   -- studies that contain T2‑weighted axial MR series
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%T2%'
      AND "SeriesDescription" ILIKE '%AXIAL%'
),
seg_studies AS (       -- studies that have “Peripheral zone” segmentations
    SELECT DISTINCT s."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS s
    JOIN IDC.IDC_V17.DICOM_PIVOT dp
          ON s."SeriesInstanceUID" = dp."SeriesInstanceUID"
    WHERE dp."collection_id" = 'qin_prostate_repeatability'
      AND LOWER(CAST(s."SegmentedPropertyType" AS STRING)) LIKE '%peripheral zone%'
)
SELECT DISTINCT t2."StudyInstanceUID"
FROM t2_studies t2
JOIN seg_studies seg
  ON t2."StudyInstanceUID" = seg."StudyInstanceUID"
ORDER BY t2."StudyInstanceUID";
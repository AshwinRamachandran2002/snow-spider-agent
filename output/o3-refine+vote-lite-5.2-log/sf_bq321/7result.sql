SELECT COUNT(DISTINCT "StudyInstanceUID") AS unique_study_count
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        /* DWI series (MR) */
        UPPER("SeriesDescription") LIKE '%DWI%'
      /* T2‑weighted axial series (MR) */
      OR (UPPER("SeriesDescription") LIKE '%T2%' AND "Modality" = 'MR')
      /* Apparent Diffusion Coefficient series (MR) */
      OR UPPER("SeriesDescription") LIKE '%APPARENT DIFFUSION COEFFICIENT%'
      OR UPPER("SeriesDescription") LIKE '%ADC%'
      /* T2‑weighted axial segmentations (SEG) */
      OR (UPPER("SeriesDescription") LIKE '%T2%' AND "Modality" = 'SEG')
      );
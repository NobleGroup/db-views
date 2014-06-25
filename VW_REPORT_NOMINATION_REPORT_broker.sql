SELECT PK.PROFITCENTER,
             RTRIM (PK.COUNTERPARTY)
          || ' '
          || RTRIM (NVL (PK.XCPPROFITCENTER, ' '))
             AS COUNTERPARTY,
          PK.PRODUCT,
          PK.VALUATIONSTATUS AS TRADE_STATUS,
          PK.TRADE,
          PK.POSITION,
          PK.POSITIONTYPE,
          PK.XPOSITIONSTATUS AS POSITION_STATUS,
          PK.INCOTERMS,
          PK.BEGTIME AS BEG_TIME,
          PK.ENDTIME AS END_TIME,
          UPPER (TO_CHAR (PK.POSBEGTIME, 'YYYY.MM')) AS BEG_MONTH,
          UPPER (TO_CHAR (PK.ENDTIME - 1, 'YYYY.MM')) AS END_MONTH,
          PK.XDELIVERYPERIOD --TO_CHAR (TO_DATE (XDELIVERYPERIOD, 'YYYY MONTH'), 'YYYY.MM')
             AS REALIZED_PERIOD,
          PK.LOCATION,
          PK.MINTOLERANCE AS TOL_MIN,
          PK.MAXTOLERANCE AS TOL_MAX,
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                NVL (AVAILABLE_FORECAST.FORECAST, 0) * (-1)
             ELSE
                NVL (AVAILABLE_FORECAST.FORECAST, 0)
          END
             AS TOT_FORECAST,
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                NVL (AVAILABLE_NOM.NOM, 0) * (-1)
             ELSE
                NVL (AVAILABLE_NOM.NOM, 0)
          END
             AS TOT_NOM,
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                (NVL (PHYS_ACTUAL.ACTUAL, 0)
                 + NVL (BOOKOUT_ACTUAL.BOOKOUT_ACTUAL, 0))
                * (-1)
             ELSE
                NVL (PHYS_ACTUAL.ACTUAL, 0)
                + NVL (BOOKOUT_ACTUAL.BOOKOUT_ACTUAL, 0)
          END
             AS TOT_ACT,
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                NVL (PHYS_ACTUAL.ACTUAL, 0) * (-1)
             ELSE
                NVL (PHYS_ACTUAL.ACTUAL, 0)
          END
             AS PHYS_ACT,
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                -1 * NVL (BOOKOUT_ACTUAL.BOOKOUT_ACTUAL, 0)
             ELSE
                NVL (BOOKOUT_ACTUAL.BOOKOUT_ACTUAL, 0)
          END
             AS BOOKOUT_ACT,
          --       FORECAST_NOM must be computed asf :
          --      [TOT_FORECAST] - [TOT_NOM] - [BOOKOUT_ACT]
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                (  NVL (AVAILABLE_FORECAST.FORECAST, 0)
                 - NVL (AVAILABLE_NOM.NOM, 0)
                 - NVL (BOOKOUT_ACTUAL.BOOKOUT_ACTUAL, 0))
                * (-1)
             ELSE
                (  NVL (AVAILABLE_FORECAST.FORECAST, 0)
                 - NVL (AVAILABLE_NOM.NOM, 0)
                 - NVL (BOOKOUT_ACTUAL.BOOKOUT_ACTUAL, 0))
          END
             AS FORECAST_NOM,
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                -1
                * (NVL (AVAILABLE_FORECAST.FORECAST, 0)
                   - NVL (AVAILABLE_ACTUAL.ACTUAL, 0))
             ELSE
                NVL (AVAILABLE_FORECAST.FORECAST, 0)
                - (NVL (AVAILABLE_ACTUAL.ACTUAL, 0))
          END
             AS FORECAST_TOT_ACT,
          --          [TOT_NOM] - [PHYS_ACT]
          CASE
             WHEN PK.POSITIONTYPE = 'SELL'
             THEN
                -1
                * (NVL (AVAILABLE_NOM.NOM, 0) - NVL (PHYS_ACTUAL.ACTUAL, 0))
             ELSE
                NVL (AVAILABLE_NOM.NOM, 0) - NVL (PHYS_ACTUAL.ACTUAL, 0)
          END
             AS NOM_PHYS_ACT,
           PK.TRADEDATE AS TRADEDATE,
           PK.PRICEDIFF AS PRICEDIFF,
           PK.BROKER AS BROKER,
           PK.BROKERDETAIL AS BROKERDETAIL
     -- select count(*)
     FROM (SELECT T.XPROFITCENTER AS PROFITCENTER,
                  T.COUNTERPARTY,
                  T.XCPPROFITCENTER,
                  T.MINTOLERANCE,
                  T.MAXTOLERANCE,
                  PP.PRODUCT,
                  T.TRADE,
                  PP.POSITION,
                  PP.POSITIONTYPE,
                  PP.XDELIVERYPERIOD,
                  PP.BEGTIME,
                  PP.ENDTIME,
                  PP.LOCATION,
                  PP.BEGTIME AS POSBEGTIME,
                  PP.XREMAININGLOTS AS REMAININGLOTS,
                  PP.INCOTERMS,
                  PP.XPOSITIONSTATUS,
                  T.VALUATIONSTATUS,
                  T.TRADEDATE,
                  FEE.PRICEDIFF,
                  T.BROKER,
                  T.BROKERDETAIL
             -- select count(*)
             FROM TRADE T
                  INNER JOIN PHYSICALPOSITION PP
                     ON     PP.TRADE = T.TRADE
                        AND T.STATUS = 'ACTIVE'
                        AND T.VALUATIONSTATUS <> 'CLOSE'
                        AND PP.XPOSITIONSTATUS <> 'CLOSED'
                  INNER JOIN PRODUCT PRD
                     ON PRD.PRODUCT = PP.PRODUCT
                  LEFT JOIN FEE ON ( FEE.TRADE || NVL(FEE.FEECODE, 0) ) = ( PP.TRADE || NVL( PP.FEECODE, 0 ))  AND FEE.FEEMETHOD LIKE 'COMMODITY PRICE%' ) PK
          LEFT OUTER JOIN ( -- Quantity Status Lifecycle : FORECAST --> SCHEDULE --> NOM --> ACTUAL
                           SELECT   PP.POSITION, SUM (PQ.MASS) AS FORECAST
                               FROM PHYSICALPOSITION PP
                                    INNER JOIN TRADE T
                                       ON     T.TRADE = PP.TRADE
                                          AND T.STATUS = 'ACTIVE'
                                          AND T.VALUATIONSTATUS <> 'CLOSE'
                                          AND PP.XPOSITIONSTATUS <> 'CLOSED'
                                    INNER JOIN PHYSICALQUANTITY PQ
                                       ON PQ.POSITION = PP.POSITION
                                          AND RTRIM (PQ.QUANTITYSTATUS) =
                                                 'FORECAST'
                           GROUP BY PP.POSITION, PP.POSITIONTYPE) AVAILABLE_FORECAST
             ON AVAILABLE_FORECAST.POSITION = PK.POSITION
          LEFT OUTER JOIN ( -- Quantity Status Lifecycle : FORECAST --> SCHEDULE --> NOM --> ACTUAL
                           SELECT   PP.POSITION, SUM (PQ.MASS) AS NOM
                               -- select count(*)
                               FROM PHYSICALPOSITION PP
                                    INNER JOIN TRADE T
                                       ON     T.TRADE = PP.TRADE
                                          AND T.STATUS = 'ACTIVE'
                                          AND T.VALUATIONSTATUS <> 'CLOSE'
                                          AND PP.XPOSITIONSTATUS <> 'CLOSED'
                                    INNER JOIN PHYSICALQUANTITY PQ
                                       ON PQ.POSITION = PP.POSITION
                                          AND RTRIM (PQ.QUANTITYSTATUS) =
                                                 'NOM'
                           GROUP BY PP.POSITION) AVAILABLE_NOM
             ON AVAILABLE_NOM.POSITION = PK.POSITION
          LEFT OUTER JOIN ( -- Quantity Status Lifecycle : FORECAST --> SCHEDULE --> NOM --> ACTUAL
                           SELECT   PP.POSITION, SUM (PQ.MASS) AS ACTUAL
                               -- select count(*)
                               FROM PHYSICALPOSITION PP
                                    INNER JOIN TRADE T
                                       ON     T.TRADE = PP.TRADE
                                          AND T.STATUS = 'ACTIVE'
                                          AND T.VALUATIONSTATUS <> 'CLOSE'
                                          AND PP.XPOSITIONSTATUS <> 'CLOSED'
                                    INNER JOIN PHYSICALQUANTITY PQ
                                       ON PQ.POSITION = PP.POSITION
                                          AND RTRIM (PQ.QUANTITYSTATUS) =
                                                 'ACTUAL'
                           GROUP BY PP.POSITION) AVAILABLE_ACTUAL
             ON AVAILABLE_ACTUAL.POSITION = PK.POSITION
          LEFT OUTER JOIN ( -- Quantity Status Lifecycle : FORECAST --> SCHEDULE --> NOM --> ACTUAL
                           SELECT   PP.POSITION, SUM (PQ.MASS) AS ACTUAL
                               -- select count(*)
                               FROM PHYSICALPOSITION PP
                                    INNER JOIN TRADE T
                                       ON     T.TRADE = PP.TRADE
                                          AND T.STATUS = 'ACTIVE'
                                          AND T.VALUATIONSTATUS <> 'CLOSE'
                                          AND PP.XPOSITIONSTATUS <> 'CLOSED'
                                    INNER JOIN PHYSICALQUANTITY PQ
                                       ON PQ.POSITION = PP.POSITION
                                          AND RTRIM (PQ.QUANTITYSTATUS) =
                                                 'ACTUAL'
                                          AND PQ.CARRIERMODE <> 'BOOKOUT'
                                    LEFT OUTER JOIN SHIPMENT S
                                       ON S.SHIPMENT = PQ.SHIPMENT
                           GROUP BY PP.POSITION) PHYS_ACTUAL
             ON PHYS_ACTUAL.POSITION = PK.POSITION
          LEFT OUTER JOIN ( -- Quantity Status Lifecycle : FORECAST --> SCHEDULE --> NOM --> ACTUAL
                           SELECT   PP.POSITION,
                                    SUM (PQ.MASS) AS BOOKOUT_ACTUAL
                               FROM PHYSICALPOSITION PP
                                    INNER JOIN TRADE T
                                       ON     T.TRADE = PP.TRADE
                                          AND T.STATUS = 'ACTIVE'
                                          AND T.VALUATIONSTATUS <> 'CLOSE'
                                          AND PP.XPOSITIONSTATUS <> 'CLOSED'
                                    INNER JOIN PHYSICALQUANTITY PQ
                                       ON PQ.POSITION = PP.POSITION
                                          AND RTRIM (PQ.QUANTITYSTATUS) =
                                                 'ACTUAL'
                                          AND PQ.CARRIERMODE = 'BOOKOUT'
                           GROUP BY PP.POSITION) BOOKOUT_ACTUAL
             ON BOOKOUT_ACTUAL.POSITION = PK.POSITION;
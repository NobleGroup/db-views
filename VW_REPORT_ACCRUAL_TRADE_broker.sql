select "PROFITCENTER","TRADE","POSITION","POSITIONTYPE","SHIPMENT","FEE","FEETRADE","COUNTERPARTY","CURR","COSTFAMILY","INCACCOUNT","EXPACCOUNT","MEASURE","OPERATORNAME","BLDATE","DESCRIPTION","CALCAMOUNTTOINVOICE","AMOUNTINVOICED","BILLING","EXRATE","USDBILLING","PAYSTATUS","PRICEDIFF","FEEMETHOD","PRICEQUANTITY","MASS","CREATIONDATE","CREATIONNAME","REVISIONDATE","REVISIONNAME","VESSEL","OPSINCHARGE","LAYCANFRO","LAYCANTO","CARRIERMODE","INVOICEDATE","INCOTERM","LOCATION","INVOICE","REPORTMODE","FEELEVEL","TIMEPERIOD","TRADECLASS","PRICING","REMAININGLOTS","PRICEDORUNPRICED","SETTLEACCTCODE","PRICEINDEX","PRIMARYORSECONDARY","FEEPOSITION","FEECREATIONDATE","FEETIMEPERIOD","SUNCUSTOMERCODE","SUNCOMMODITYCODE","PRODUCT","SHIPMENTESTIMATE","ACCTSTATUS","CUSTOMTABLE", "BROKER", "BROKERDETAIL" from (
SELECT Max(profitcenter)                              AS PROFITCENTER,
       Max(trade)                                     AS TRADE,
       position                                       AS POSITION,
       MAX(positiontype)                           AS POSITIONTYPE,
       shipment                                       AS SHIPMENT,
       fee                                            AS FEE,
       Max(feetrade)                                  AS FEETRADE,
       Max(counterparty)                              AS COUNTERPARTY,
       Max(currency)                                  AS CURR,
       Max(costfamily)                                AS COSTFAMILY,
        Max(incaccount)                                AS INCACCOUNT,
       Max(expaccount)                                AS EXPACCOUNT,
       measure                                        AS MEASURE,
       Max(operatorname)                              AS OPERATORNAME,
       Nvl(Max(bldate),Max(invoicedate))              AS BLDATE,
       Max(description)                                AS DESCRIPTION,
       Round(Sum(calcamounttoinvoice),2)              AS CALCAMOUNTTOINVOICE,
       Round(Sum(amountinvoiced),2)                   AS AMOUNTINVOICED,
       Round(Sum(calcamounttoinvoice),2) - Round(Sum(amountinvoiced),2) AS Billing,
       CASE WHEN MAX(exrate2) > 0 THEN MAX(exrate2)
           ELSE MAX(exrate)
       END                                    AS EXRATE,
       Round((Round(Sum(calcamounttoinvoice),2) - Round(Sum(amountinvoiced),2))*CASE WHEN MAX(exrate2) > 0 THEN MAX(exrate2)
           ELSE MAX(exrate)
      END,2) AS USDBilling,
       Max(paystatus)                                 AS PAYSTATUS,
       Max(pricediff)                                 AS PRICEDIFF,
       Max(feemethod)                                 AS FEEMETHOD,
       Max(pricequantity)                             AS PRICEQUANTITY,
       CASE WHEN MAX(mass)=-999999999999999 THEN 0 ELSE MAX(mass) END                          AS MASS,
       MAX(creationdate)                              AS CREATIONDATE,
       MAX(creationname)                              AS CREATIONNAME,
       MAX(revisiondate)                              AS REVISIONDATE,
       MAX(revisionname)                              AS REVISIONNAME,
       MAX(VESSEL)                                    AS VESSEL,
       MAX(OPSINCHARGE)                               AS OPSINCHARGE,
       MAX(LAYCANFRO)                                 AS LAYCANFRO,
       MAX(LAYCANTO)                                  AS LAYCANTO,
       MAX(CARRIERMODE)                               AS CARRIERMODE,
       MAX(INVOICEDATE)                               AS INVOICEDATE,
       Max(INCOTERM)                                  AS INCOTERM,
       Max(LOCATION)                                  AS LOCATION,
       Max(INVOICE)                                   AS INVOICE,
       CASE WHEN ABS(Sum(calcamounttoinvoice))>0 AND ABS(Sum(amountinvoiced))=0 THEN 'ACCRUAL'
            WHEN ABS(Sum(calcamounttoinvoice))=0 AND ABS(Sum(amountinvoiced))>0 THEN 'UNMATCHED INVOICE'
            WHEN ABS(SUM(calcamounttoinvoice))=0
            AND ABS(SUM(amountinvoiced))      =0 AND MAX(invoice) IS NULL
            THEN 'ZERO PRICE'
            WHEN SUM(calcamounttoinvoice)=SUM(amountinvoiced) AND MAX(invoice) IS NOT NULL
            THEN 'MATCHED'
            WHEN ABS(Sum(calcamounttoinvoice))>0 AND ABS(Sum(amountinvoiced))>0 AND SUM(calcamounttoinvoice)<>SUM(amountinvoiced) THEN 'OVER/UNDER BILLING' END AS REPORTMODE,
       CASE WHEN Max(feetrade) is null THEN 'SHIPMENT' ELSE 'TRADE' END AS FEELEVEL,
       To_char(Max(bldate),'YYYY MONTH') AS TIMEPERIOD,
       MAX(tradeclass)                                AS TRADECLASS,
       MAX(pricing)                                   AS PRICING,
       MAX(remaininglots)                             AS REMAININGLOTS,
       CASE WHEN MAX(remaininglots)=0 THEN 'PRICED' ELSE 'UNPRICED' END                        AS PRICEDORUNPRICED,
        Max(SETTLEACCTCODE) AS SETTLEACCTCODE,
      Max(priceindex) AS PRICEINDEX,
      'SECONDARY' AS PRIMARYORSECONDARY,
       Max(feeposition) as FEEPOSITION,
      MAX(creationdate)                              AS FEECREATIONDATE,
      To_char(Max(feecreationdate),'YYYY MONTH') AS FEETIMEPERIOD,
      Max(suncustomercode) AS SUNCUSTOMERCODE,
      Max(suncommoditycode) AS SUNCOMMODITYCODE,
      Max(product) AS PRODUCT,
      MAX(SHIPMENTESTIMATE) AS SHIPMENTESTIMATE,
      MAX(ACCTSTATUS) AS ACCTSTATUS,
      FEE AS CUSTOMTABLE,
      broker,
      brokerdetail
FROM   (SELECT Max(Nvl(FE.xprofitcenter,PP.xprofitcenter)) AS PROFITCENTER,
               Max(TR.trade)         AS TRADE,
               MAX(TR.tradeclass)          AS TRADECLASS,
               MAX(tr.xcontractpricing)    AS PRICING,
               PQ.position           AS POSITION,
               MAX(PP.positiontype)           AS POSITIONTYPE,
               MAX(pp.xremaininglots)      AS REMAININGLOTS,
               SH.shipment           AS SHIPMENT,
               FE.fee                AS FEE,
               Max(FE.trade)         AS FEETRADE,
               Max(FE.counterparty)  AS COUNTERPARTY,
               Max(FE.currency)      AS CURRENCY,
               Max(FT.costfamily)    AS COSTFAMILY,
               Max(FT.incaccount)    AS INCACCOUNT,
               Max(FT.expaccount)    AS EXPACCOUNT,
               PQ.measure            AS MEASURE,
               Max(SH.creationname)  AS OPERATORNAME,
               Max(Nvl(VA.actualdate,SH.bookoutdate))    AS BLDATE,
               Max(FE.description)   AS DESCRIPTION,
               ROUND(Max(CASE
                     WHEN FE.paystatus LIKE 'PAY%' THEN
                       CASE
                          WHEN FE.feemethod LIKE 'FIXED%' THEN
                            -FE.pricediff * ( ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4) /
                            NVL(TOTAMNT.AMT,1)
                            --AND pq.shipment    =FE.shipment
                            )
                          ELSE
                            -ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4) * FE.pricediff
                          END
                     ELSE
                       CASE
                          WHEN FE.feemethod LIKE 'FIXED%' THEN
                            FE.pricediff * ( ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4) /
                            NVL(TOTAMNT.AMT,1)
                            --AND pq.shipment    =FE.shipment
                            )
                          ELSE
                            ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4) * FE.pricediff
                          END
                   END),2)              AS CALCAMOUNTTOINVOICE,
               0                     AS AMOUNTINVOICED,
               Max(FE.paystatus)     AS PAYSTATUS,
               Max(FE.pricediff)     AS PRICEDIFF,
               Max(FE.feemethod)     AS FEEMETHOD,
               0                     AS PRICEQUANTITY,
               (CASE
                 WHEN (Nvl(Max(FE.PAYSTATUS),Max(PP.positiontype)) LIKE 'BUY%' OR Nvl(Max(FE.PAYSTATUS),Max(PP.positiontype)) LIKE 'PAY%') THEN
                  MAX(ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4))
                 ELSE -MAX(ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4))
               END )          AS MASS,
               Max(Nvl(cex.exrate,1))       AS EXRATE,
               MAX(fe.creationdate)                              AS CREATIONDATE,
               MAX(fe.creationname)                              AS CREATIONNAME,
               MAX(fe.revisiondate)                              AS REVISIONDATE,
               MAX(fe.revisionname)                              AS REVISIONNAME,
               MAX(sh.VESSEL)                                    AS VESSEL,
               MAX(sh.xopsid)                                    AS OPSINCHARGE,
               MAX(sh.xlaycanbegtime)                            AS LAYCANFRO,
               MAX(sh.xlaycanendtime)                            AS LAYCANTO,
               MAX(pq.carriermode)                               AS CARRIERMODE,
               null                                            AS INVOICEDATE,
               Max(pp.INCOTERMS)                                     AS INCOTERM,
               Max(pp.LOCATION)                                     AS LOCATION,
               null                                                 AS INVOICE,
               Max(VA.SETTLEACCTCODE) AS SETTLEACCTCODE,
               Max(fe.priceindex) AS PRICEINDEX,
               Max(fe.position) as FEEPOSITION,
               MAX(fe.creationdate)                              AS FEECREATIONDATE,
               Max(CT.xsuncode) AS SUNCUSTOMERCODE,
               Max(P.xsuncommoditycode) AS SUNCOMMODITYCODE,
               Max(P.product) AS PRODUCT,
               Max(ft.shipmentestimate) AS SHIPMENTESTIMATE,
               '' AS ACCTSTATUS,
               '' AS FINTRANSACT,
               -1 AS EXRATE2,
               TR.broker,
               TR.brokerdetail
        FROM   physicalquantity PQ
               INNER JOIN physicalposition PP
                       ON PP.position = PQ.position
               LEFT JOIN trade TR
                       ON TR.trade = PP.trade
               INNER JOIN (select * from (select xprofitcenter,priceindex,fee,creationname,creationdate,revisionname,revisiondate,description,feetype,currency,paystatus,
                                counterparty,company,pricediff,shipment,trade,position,feemethod,measure,row_number()
                                over (partition by trade,description order by feestatus asc) as rn
                                from fee) where rn=1) FE
                       ON ( ( FE.position IS NOT NULL
                              AND FE.position = PQ.position )
                             OR FE.position IS NULL )
                          AND ( ( FE.measure IS NOT NULL
                                  AND FE.measure = PQ.measure )
                                 OR FE.measure IS NULL ) AND (FE.trade=tr.trade)
                          --AND FE.shipment = PQ.shipment
               INNER JOIN feetype FT
                       ON FT.feetype = FE.feetype
               LEFT OUTER JOIN shipment SH
                       ON PQ.shipment = SH.shipment
               LEFT OUTER JOIN voyageactual VA
                       ON VA.measure = PQ.measure
                          AND VA.position = PQ.position
               LEFT JOIN counterparty CT on CT.counterparty=FE.counterparty
               LEFT JOIN product P on P.product=PP.product
               LEFT JOIN (SELECT pp.position AS position,DECODE(SUM(ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4)),0,1,SUM(ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4))) AS AMT
                  FROM physicalquantity pq,
                    physicalposition pp
                  WHERE pp.position = pq.position
                  AND pq.quantitystatus LIKE 'ACTUAL%'
                  AND pq.posstatus   = 1
                  GROUP BY pp.position
                  --AND pq.shipment    =FE.shipment
                  ) TOTAMNT ON TOTAMNT.POSITION = FE.POSITION
                LEFT OUTER JOIN (select * from (
                select ((BIDRATE+OFFERRATE)/2) as exrate, quotecurrency, basecurrency, pricedate,row_number()
                over (partition by basecurrency ORDER BY pricedate desc) as rn
                from currexchrate where  quotecurrency='USD')
                where rn=1) cex ON cex.basecurrency=fe.currency
        WHERE  PQ.posstatus = 1
               AND PQ.quantitystatus = 'ACTUAL'
               --AND FT.shipmentestimate = 0
               --AND FE.company LIKE 'NRSA%'
               AND ((FE.feemethod like 'FIXED%' AND (FE.position is not null or FE.measure is not null))OR
               (FE.feemethod like 'RECVOLUME%' AND PP.positiontype like 'SELL%')OR
               (FE.feemethod like 'DELVOLUME%' AND PP.positiontype like 'BUY%'))
               AND FE.shipment IS NULL --EXCLUDE SHIPMENT LEVEL
               --AND FE.trade IS NOT NULL
               AND FE.description NOT LIKE 'PROVISIONAL%'
               AND FE.description NOT LIKE 'PRIMARY%'
               AND FE.description NOT LIKE 'FIXED PREPAID - SALES%'
               AND FE.description NOT LIKE 'FIXED PREPAID - PURCHASE%'
               AND FE.feemethod NOT LIKE 'COMMODITY%'
               AND FE.description NOT LIKE 'COMMODITY%'
               AND FE.description NOT LIKE 'CIRCLE%'
               AND FE.description NOT LIKE 'STRING%'
               AND FE.description NOT LIKE 'BOOKOUT%'
               AND FE.description NOT LIKE 'WASHOUT%'
               AND FE.description NOT LIKE 'FR CARRYING CHARGE%'
               AND FE.description NOT LIKE 'FR CARRY CHARGE%'
               AND FE.description NOT LIKE 'FR WHEAT CARRY CHARGE%'
               AND FE.description NOT LIKE 'MARGIN COST%'
               AND FE.description NOT LIKE 'PRICE ADJUSTMENT%'
               AND fe.pricediff<>0
               AND TR.status like 'ACTIVE%'
               AND TR.tradestatus not like 'PROSPECTIVE%'
               --AND TR.valuationstatus like 'OPEN%'
               AND TR.execution like '%PHYSICAL%'
        --and pq.position=131337 and fe.fee=261773 and sh.shipment=803584
        GROUP  BY PQ.position,
                  SH.shipment,
                  FE.fee,
                  PQ.measure,
                  TR.broker,
                  TR.brokerdetail
        UNION ALL
        SELECT
              Max(Nvl(FE.xprofitcenter,PP.xprofitcenter)) AS PROFITCENTER,
               Max(FD.trade)         AS TRADE,
               MAX(TR.tradeclass)          AS TRADECLASS,
               MAX(tr.xcontractpricing)    AS PRICING,
               FD.position           AS POSITION,
               MAX(PP.positiontype)           AS POSITIONTYPE,
               MAX(pp.xremaininglots)      AS REMAININGLOTS,
               SH.shipment           AS SHIPMENT,
               FD.fee                AS FEE,
              Max(FE.trade)         AS FEETRADE,
               Max(FE.counterparty)  AS COUNTERPARTY,
               Max(FE.currency)      AS CURRENCY,
               Max(FT.costfamily)    AS COSTFAMILY,
               Max(FT.incaccount)    AS INCACCOUNT,
               Max(FT.expaccount)    AS EXPACCOUNT,
               CASE WHEN FD.measure IS NULL THEN PQ.measure ELSE FD.measure END            AS MEASURE,
               Max(SH.creationname)  AS OPERATORNAME,
               Max(Nvl(VA.actualdate,fd.invoicedate))    AS BLDATE,
               Max(FD.description)   AS DESCRIPTION,
               0                     AS CALCAMOUNTTOINVOICE,
              ROUND(CASE
                WHEN ( MAX(fd.measure) IS NOT NULL ) THEN
                  SUM( fd.credit - fd.debit)
                ELSE
                  SUM(( fd.credit - fd.debit ) * ( ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4) /
                  NVL(TOTAMNT.AMT,1)
                  ))
                END,2)
                AS
                  AMOUNTINVOICED,
               Max(FE.paystatus)     AS PAYSTATUS,
               Max(FE.pricediff)     AS PRICEDIFF,
               Max(FE.feemethod)     AS FEEMETHOD,
               Max(FD.pricequantity) AS PRICEQUANTITY,
               -999999999999999                     AS MASS,
               -1       AS EXRATE,
               MAX(fe.creationdate)                              AS CREATIONDATE,
               MAX(fe.creationname)                              AS CREATIONNAME,
               MAX(fe.revisiondate)                              AS REVISIONDATE,
               MAX(fe.revisionname)                              AS REVISIONNAME,
               MAX(sh.VESSEL)                                    AS VESSEL,
               MAX(sh.xopsid)                                    AS OPSINCHARGE,
               MAX(sh.xlaycanbegtime)                            AS LAYCANFRO,
               MAX(sh.xlaycanendtime)                            AS LAYCANTO,
               MAX(pq.carriermode)                               AS CARRIERMODE,
               MAX(fd.invoicedate)                               AS INVOICEDATE,
               Max(pp.INCOTERMS)                                     AS INCOTERM,
               Max(pp.LOCATION)                                     AS LOCATION,
               Max(fd.invoice)                                    AS INVOICE,
               Max(VA.SETTLEACCTCODE) AS SETTLEACCTCODE,
               Max(fe.priceindex) AS PRICEINDEX,
              Max(fe.position) as FEEPOSITION,
               MAX(fe.creationdate)                              AS FEECREATIONDATE,
               Max(Nvl(CT.xsuncode,CT2.xsuncode)) AS SUNCUSTOMERCODE,
               Max(P.xsuncommoditycode) AS SUNCOMMODITYCODE,
               Max(P.product) AS PRODUCT,
               Max(ft.shipmentestimate) as SHIPMENTESTIMATE,
               MAX(FD.ACCTSTATUS) AS ACCTSTATUS,
               MAX(FD.FINTRANSACT) AS FINTRANSACT,
               Max(DECODE(FD.TRANSACTIONTYPE,'AP',Nvl(cex3.exrate,1),Nvl(cex2.exrate,1)))       AS EXRATE2,
               TR.broker,
               TR.brokerdetail
        FROM   findetail FD
               INNER JOIN fintransact FTT ON FTT.fintransact=FD.fintransact
               INNER JOIN trade TR
                       ON FD.trade = TR.trade  AND TR.status like 'ACTIVE%'
                       AND TR.tradestatus not like 'PROSPECTIVE%'
                       --AND TR.valuationstatus like 'OPEN%'
                       AND TR.execution like '%PHYSICAL%'
               INNER JOIN physicalposition PP
                       ON FD.position = PP.position
               INNER JOIN fee FE
                       ON FD.fee = FE.fee
               LEFT OUTER JOIN physicalquantity PQ
                       ON FD.position = PQ.position AND PQ.posstatus = 1 AND PQ.quantitystatus = 'ACTUAL'
                          --AND FE.shipment = PQ.shipment
                          AND ( ( FD.measure IS NOT NULL
                                  AND FD.measure = PQ.measure )
                                 OR FD.measure IS NULL )
               LEFT OUTER JOIN shipment SH
                       ON PQ.shipment = SH.shipment
               LEFT OUTER JOIN voyageactual VA
                       ON PQ.measure = VA.measure
                          AND FD.position = VA.position
               LEFT OUTER JOIN feetype FT
                       ON FT.feetype = FE.feetype
                          --AND FT.shipmentestimate = 0
               LEFT JOIN counterparty CT on (CT.counterparty=FTT.xcounterparty)
               LEFT JOIN counterparty CT2 on (CT2.counterparty=FE.counterparty)
               LEFT JOIN product P on P.product=PP.product
               LEFT JOIN (SELECT pp.position AS position,DECODE(SUM(ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4)),0,1,SUM(ROUND(UNITCONVERT(PQ.massunit,PQ.mass),4))) AS AMT
                  FROM physicalquantity pq,
                    physicalposition pp
                  WHERE pp.position = pq.position
                  AND pq.quantitystatus LIKE 'ACTUAL%'
                  AND pq.posstatus   = 1
                  GROUP BY pp.position
                  --AND pq.shipment    =FE.shipment
                  ) TOTAMNT ON TOTAMNT.POSITION = FD.POSITION
               LEFT OUTER JOIN (select * from (
                select ((BIDRATE+OFFERRATE)/2) as exrate, quotecurrency, basecurrency, pricedate,row_number()
                    over (partition by basecurrency ORDER BY pricedate desc) as rn
                    from currexchrate where  quotecurrency='USD')
                ) cex2 ON cex2.basecurrency=fe.currency AND To_date(cex2.pricedate,'dd mm yyyy') = To_date(fd.invoicedate,'dd mm yyyy')
                    LEFT OUTER JOIN (select * from (
                select ((BIDRATE+OFFERRATE)/2) as exrate, quotecurrency, basecurrency, pricedate,row_number()
                    over (partition by basecurrency ORDER BY pricedate desc) as rn
                    from currexchrate where  quotecurrency='USD')
                ) cex3 ON cex3.basecurrency=fe.currency AND To_date(cex3.pricedate,'dd mm yyyy') = To_date(ftt.duedate,'dd mm yyyy')
        WHERE
               FD.invoice IS NOT NULL
               AND FD.confirmstatus = 1
               AND FD.fee IS NOT NULL
               AND FD.grossvalue <> 0
               AND FD.description NOT LIKE 'PROVISIONAL%'
               AND FD.description NOT LIKE 'PRIMARY%'
               AND FD.description NOT LIKE 'FIXED PREPAID - SALES%'
               AND FD.description NOT LIKE 'FIXED PREPAID - PURCHASE%'
               AND FD.description NOT LIKE 'COMMODITY%'
               AND FD.description NOT LIKE 'CIRCLE%'
               AND FD.description NOT LIKE 'STRING%'
               AND FD.description NOT LIKE 'BOOKOUT%'
               AND FD.description NOT LIKE 'WASHOUT%'
               AND FD.description NOT LIKE 'FR CARRYING CHARGE%'
               AND FD.description NOT LIKE 'FR CARRY CHARGE%'
               AND FD.description NOT LIKE 'FR WHEAT CARRY CHARGE%'
               AND FD.description NOT LIKE 'MARGIN COST%'
               AND FD.description NOT LIKE 'PRICE ADJUSTMENT%'
               AND FD.transactiontype IN ( 'AP', 'AR' )
               --EXCLUDE DERIVATE 'JE'
               AND FD.account NOT LIKE '163%' --EXCLUDE THESE KIND OF ACCOUNT
               AND FD.account NOT LIKE 'WASHOUT%'
               AND FD.account NOT LIKE 'CREDITOR%'
               AND FD.account NOT LIKE 'DEPTORS%'
               AND FD.account NOT LIKE 'BJPM%'
               AND FD.settleacctcode IS NULL
               AND FD.quantitystatus <> 'BOOKOUT' --EXCLUDE WASHOUT
               AND (/*FE.company LIKE 'NRSA%' AND*/ fe.pricediff<>0
               AND FE.shipment IS NULL --EXCLUDE SHIPMENT LEVEL
               --AND FE.trade IS NOT NULL
               AND ((FE.feemethod like 'FIXED%' AND (FE.position is not null or FE.measure is not null or FE.trade is not null))
               OR ((FE.feemethod like 'RECVOLUME%' AND PP.positiontype like 'SELL%')OR
              (FE.feemethod like 'DELVOLUME%' AND PP.positiontype like 'BUY%')))OR(FE.fee IS NULL))
        --and pq.position=121207 and fe.fee=307372 and sh.shipment=803621
        GROUP  BY FD.position,
                  SH.shipment,
                  FD.fee,
                  TR.broker,
                  TR.brokerdetail,
                  CASE WHEN FD.measure IS NULL THEN PQ.measure ELSE FD.measure END)
GROUP  BY position,
          shipment,
          fee,
          measure,
          broker,
          brokerdetail
ORDER  BY profitcenter,
          shipment,
          costfamily,
          trade,
          position,
          fee)
WHERE
((ABS(CALCAMOUNTTOINVOICE)>0 OR ABS(AMOUNTINVOICED)>0)) AND
Nvl(BLDATE,INVOICEDATE) >= TO_DATE ('2012 01 01', 'yyyy mm dd')
AND Nvl(BLDATE,INVOICEDATE) <= sysdate
;

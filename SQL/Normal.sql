--declare @CompanyId int = 8;
--declare @BranchId int = 10;
--declare @JobTypeId int = 0;
--declare @CustomerId int = 0;
--declare @SalesRepresentativeId int = 0;
--declare @ChargePortId int = 0;
--declare @ArrivalPortId int = 0;
--declare @AgentId int = 0;
--declare @AccountId int=0;
--declare @ExportCompanyId int = 0;
--declare @FirstDate datetime = '1/1/2021';
--declare @LastDate datetime = '2/2/2044';
--declare @JobId int = 100000146;
--declare @CmbReportStatus int = 0;
--declare @chargeType int = 0;
--DECLARE @CostCenterId INT = 0;
--DECLARE @CustomerGroupId INT = 0;
--DECLARE @FromValue INT = 0;
--Declare @OperationId int=0;
--DECLARE @ToValue INT = 0;


with InvoiceCount as
(SELECT JobId,InvoiceId,DutyId , count(InvoiceId) AS COUNT 

              FROM CC_PayDutiesDtl 
			  left outer join CC_InvoicesDtl on CC_InvoicesDtl.MasterId=CC_PayDutiesDtl.InvoiceId
			  where ISNULL(InvoiceId,0)>0 and ISNULL(CC_PayDutiesDtl.Value,0)>0   
              GROUP BY DutyId,JobId,InvoiceId),
 InvoiceDtl as(SELECT BandId,MasterId, sum(TotalInLocal) AS TotalInLocal,sum(CC_InvoicesDtl.Quantity) as Quantity,
 sum(CC_InvoicesDtl.Cost) AS Cost

              FROM CC_InvoicesDtl join CC_Invoices on CC_InvoicesDtl.MasterId=CC_Invoices.Id
			  where ISNULL(CC_Invoices.Deleted,0)=0 and ISNULL(CC_InvoicesDtl.Total,0)>0   
              GROUP BY BandId,MasterId),
JOB_COMPLETED_OPERATION AS (
             SELECT CC_Jobs.Id AS                                   JobId,
                    CC_JobFollowUp.OperationId,
					CC_JobFollowUp.Notes as CompletedOperationNotes,
                    CAST(CC_JobFollowUp.TransactDate_Gregi AS DATE) TransactDate_Gregi
             FROM CC_Jobs
                      JOIN CC_JobFollowUp
                           ON CC_JobFollowUp.Id = (SELECT TOP 1 Id
                                                   FROM CC_JobFollowUp JFU
                                                   WHERE CC_Jobs.Id = JFU.JobId
                                                     AND (@OperationId = '0' OR
                                                          (JFU.OperationId IN (SELECT VALUE
                                                                               FROM fn_Split(@OperationId, ','))))
                                                   ORDER BY JFU.TransactDate_Gregi DESC, JFU.Id DESC)
         )
select

  sp.NameA                         AS CustomerNameA,
  sp.NameE                         AS CustomerNameE,
  sp.Code                          AS CustomerCode,
  CC_Jobs.Code                     AS JobCode,
  CC_PayDuties.Code                AS PayDutiesCode,
  CC_PayDuties.Id                  AS PayDutiesId,
  CC_Agents.NameA                         AS AgentNameA,
  CC_Agents.NameE                         AS AgentNameE,
  cd.JobId,
  CC_ExpensesAndInvoiceBands.NameA as BandNameA,
  CC_ExpensesAndInvoiceBands.NameE as BandNamee,
  case when isnull(cd.IsAppliedTax,0)=1 then 0 else  isnull(cd.TaxValue,0) end as TaxValue,
  cd.Value - isnull(cd.TaxValue,0) as  Value ,
  isnull(cd.RefundValue,0) as RefundValue,
  CC_Invoices.Id                   AS InvoiceId,
  CC_Invoices.Code                 AS InvoiceCode,
  case
   when (select sum(InvoiceCount.COUNT) from InvoiceCount
  where cd.DutyId=InvoiceCount.DutyId and cd.InvoiceId=InvoiceCount.InvoiceId and cd.JobId=InvoiceCount.JobId
 GROUP BY DutyId,JobId,InvoiceId )>1  then  (((cd.Value-ISNULL(cd.RefundValue,0)) / InvoiceDtl.Cost)* InvoiceDtl.TotalInLocal )
 else isnull(InvoiceDtl.TotalInLocal,0) end       AS InvoiceValue,
  isnull(InvoiceDtl.TotalInLocal,0) as TotalValue,
  isnull(InvoiceDtl.Quantity,0) as Quantity,
  --case when CC_Invoices.Id>0 then 0 else cd.Remain end   as RemainOld,

    case 
 when (select sum(InvoiceCount.COUNT) from InvoiceCount
  where cd.DutyId=InvoiceCount.DutyId and cd.InvoiceId=InvoiceCount.InvoiceId and cd.JobId=InvoiceCount.JobId
 GROUP BY DutyId,JobId,InvoiceId )>1 then  cd.[Value]-(((cd.Value / InvoiceDtl.Cost) * InvoiceDtl.TotalInLocal))

 else  (cd.[Value]-ISNULL(cd.RefundValue,0))- isnull(InvoiceDtl.TotalInLocal,0) end       AS Remain,

  CC_PayDuties.TransactDate_Gregi,
  cd.VoucherDate
from CC_PayDuties
  inner join CC_PayDutiesDtl cd on cd.MasterId = CC_PayDuties.Id
  LEFT OUTER JOIN CC_Invoices ON cd.InvoiceId = CC_Invoices.Id
  LEFT OUTER JOIN InvoiceDtl ON CC_Invoices.Id = InvoiceDtl.MasterId and cd.DutyId = InvoiceDtl.BandId
  left outer join CC_Jobs on cd.JobId = CC_Jobs.Id
  left outer join Sys_Partners sp on CC_Jobs.CustomerId = sp.Id
  left outer join CC_ExpensesAndInvoiceBands on cd.DutyId = CC_ExpensesAndInvoiceBands.Id
  
  left outer join
  Sys_Ports AS ChargePort ON CC_Jobs.ChargePortId = ChargePort.Id
  LEFT OUTER JOIN
  Sys_Ports AS ArrivalPort ON CC_Jobs.ArrivalPortId = ArrivalPort.Id
  LEFT OUTER JOIN
  Sys_Countries ON CC_Jobs.OriginCountryId = Sys_Countries.Id
  LEFT OUTER JOIN
  CC_Agents ON CC_Jobs.AgentId = CC_Agents.Id
  LEFT OUTER JOIN JOB_COMPLETED_OPERATION  ON CC_Jobs.Id = JOB_COMPLETED_OPERATION.JobId
  LEFT OUTER JOIN
  CC_ExportCompanies ON CC_Jobs.ExportCompanyId = CC_ExportCompanies.Id
  LEFT OUTER JOIN
  GL_ChartOfCostCenter ON CC_Jobs.CostCenterId = GL_ChartOfCostCenter.Id
where (@CmbReportStatus = 0 and CC_PayDuties.CompanyId = @CompanyId and CC_PayDuties.BranchId in (@BranchId)
       and ISNULL(CC_PayDuties.Deleted, 0) = 0 AND ISNULL(cd.Total, 0) > 0
       --and cd.Remain = 0
       and (@JobTypeId = '0' or (CC_Jobs.JobTypeId in (select Value
                                                       from fn_Split(@JobTypeId, ','))))
       and (@CustomerId = '0' or (CC_Jobs.CustomerId in (select Value
                                                         from fn_Split(@CustomerId, ','))))
       AND (@CustomerGroupId = '0' OR (ISNULL(sp.PartnerGroupId, 0) IN (SELECT Value
                                                                        FROM fn_Split(@CustomerGroupId, ','))))
	 and (@SalesRepresentativeId = '0' or CC_Jobs.CustomerId in (select CustomerId from Sys_SalesRepresentativeDtl
	             where MasterId in (select Value from fn_Split(@SalesRepresentativeId, ','))))
       and (@ChargePortId = '0' or (CC_Jobs.ChargePortId in (select Value
                                                             from fn_Split(@ChargePortId, ','))))
       and (@ArrivalPortId = '0' OR (CC_Jobs.ArrivalPortId in (select Value
                                                               from fn_Split(@ArrivalPortId, ','))))
       and (@AgentId = '0' or (CC_Jobs.AgentId in (select Value
                                                   from fn_Split(@AgentId, ','))))
       and (@ExportCompanyId = '0' OR (CC_Jobs.ExportCompanyId in (select Value
                                                                   from fn_Split(@ExportCompanyId, ','))))
       and (@JobId = '0' OR (CC_Jobs.Id in (select Value
                                            from fn_Split(@JobId, ','))))
		and (@OperationId = '0' OR (JOB_COMPLETED_OPERATION.OperationId in (select Value
                                            from fn_Split(@OperationId, ','))))
       AND (@CostCenterId = '0' OR (CC_Jobs.CostCenterId IN (SELECT Value
                                                             FROM fn_Split(@CostCenterId, ','))))
	AND (@AccountId = '0' OR (cd.DutyId in(
	            select CC_ExpensesAndInvoiceBandsAccount.MasterId 
	                     from CC_ExpensesAndInvoiceBandsAccount where CC_ExpensesAndInvoiceBandsAccount.AccountId
						 in (select Value from fn_Split(@AccountId, ',')))))

       and (@chargeType = '0' OR (cd.DutyId in (select Value
                                                from fn_Split(@chargeType, ','))))
       and cast(CC_PayDuties.TransactDate_Gregi as date) >= @FirstDate and cast(CC_PayDuties.TransactDate_Gregi as date) <= @LastDate
       and (@FromValue = 0 or cd.Value >= @FromValue) and (@ToValue = 0 or cd.Value <= @ToValue)
      )
      or

      (@CmbReportStatus = 1 and CC_PayDuties.CompanyId = @CompanyId and CC_PayDuties.BranchId in (@BranchId)
       and ISNULL(CC_PayDuties.Deleted, 0) = 0 AND ISNULL(cd.Total, 0) > 0
       and ISNULL(cd.InvoiceId, 0) = 0 
	   --and ISNULL(cd.Remain, 0) > 0
       --	and cd.Remain != 0
       and (@JobTypeId = '0' or (CC_Jobs.JobTypeId in (select Value
                                                       from fn_Split(@JobTypeId, ','))))
       and (@CustomerId = '0' or (CC_Jobs.CustomerId in (select Value
                                                         from fn_Split(@CustomerId, ','))))
       AND (@CustomerGroupId = '0' OR (ISNULL(sp.PartnerGroupId, 0) IN (SELECT Value
                                                                        FROM fn_Split(@CustomerGroupId, ','))))
	  and (@SalesRepresentativeId = '0' or CC_Jobs.CustomerId in (select CustomerId from Sys_SalesRepresentativeDtl
	             where MasterId in (select Value from fn_Split(@SalesRepresentativeId, ','))))
       and (@ChargePortId = '0' or (CC_Jobs.ChargePortId in (select Value
                                                             from fn_Split(@ChargePortId, ','))))
       and (@ArrivalPortId = '0' OR (CC_Jobs.ArrivalPortId in (select Value
                                                               from fn_Split(@ArrivalPortId, ','))))
       and (@AgentId = '0' or (CC_Jobs.AgentId in (select Value
                                                   from fn_Split(@AgentId, ','))))
       and (@ExportCompanyId = '0' OR (CC_Jobs.ExportCompanyId in (select Value
                                                                   from fn_Split(@ExportCompanyId, ','))))
       and (@JobId = '0' OR (CC_Jobs.Id in (select Value
                                            from fn_Split(@JobId, ','))))
 	
	and (@OperationId = '0' OR (JOB_COMPLETED_OPERATION.OperationId in (select Value
                                            from fn_Split(@OperationId, ','))))
       AND (@CostCenterId = '0' OR (CC_Jobs.CostCenterId IN (SELECT Value
                                                             FROM fn_Split(@CostCenterId, ','))))
       and (@chargeType = '0' OR (cd.DutyId in (select Value
                                                from fn_Split(@chargeType, ','))))
AND (@AccountId = '0' OR (cd.DutyId in(
	 select CC_ExpensesAndInvoiceBandsAccount.MasterId 
	                     from CC_ExpensesAndInvoiceBandsAccount where CC_ExpensesAndInvoiceBandsAccount.AccountId
						 in (select Value from fn_Split(@AccountId, ',')))))
       and cast(CC_PayDuties.TransactDate_Gregi as date) >= @FirstDate and cast(CC_PayDuties.TransactDate_Gregi as date) <= @LastDate
       and (@FromValue = 0 or cd.Value >= @FromValue) and (@ToValue = 0 or cd.Value <= @ToValue)
	   and ISNULL(cd.Value,0) > isnull(cd.RefundValue,0) --ticket(14396)

      )
      or (@CmbReportStatus = 2 and CC_PayDuties.CompanyId = @CompanyId and CC_PayDuties.BranchId in (@BranchId)
          and ISNULL(CC_PayDuties.Deleted, 0) = 0 AND ISNULL(cd.Total, 0) > 0
          --  AND cd.Remain != cd.Value
          and ISNULL(cd.InvoiceId, 0) != 0
          and (@JobTypeId = '0' or (CC_Jobs.JobTypeId in (select Value
                                                          from fn_Split(@JobTypeId, ','))))
          AND (@CustomerGroupId = '0' OR (ISNULL(sp.PartnerGroupId, 0) IN (SELECT Value
                                                                           FROM fn_Split(@CustomerGroupId, ','))))
          and (@CustomerId = '0' or (CC_Jobs.CustomerId in (select Value
                                                            from fn_Split(@CustomerId, ','))))
		 and (@SalesRepresentativeId = '0' or CC_Jobs.CustomerId in (select CustomerId from Sys_SalesRepresentativeDtl
	             where MasterId in (select Value from fn_Split(@SalesRepresentativeId, ','))))
          and (@ChargePortId = '0' or (CC_Jobs.ChargePortId in (select Value
                                                                from fn_Split(@ChargePortId, ','))))
          and (@ArrivalPortId = '0' OR (CC_Jobs.ArrivalPortId in (select Value
                                                                  from fn_Split(@ArrivalPortId, ','))))
          and (@AgentId = '0' or (CC_Jobs.AgentId in (select Value
                                                      from fn_Split(@AgentId, ','))))
          and (@ExportCompanyId = '0' OR (CC_Jobs.ExportCompanyId in (select Value
                                                                      from fn_Split(@ExportCompanyId, ','))))
          and (@JobId = '0' OR (CC_Jobs.Id in (select Value
                                               from fn_Split(@JobId, ','))))
and (@OperationId = '0' OR (JOB_COMPLETED_OPERATION.OperationId in (select Value
                                            from fn_Split(@OperationId, ','))))
          AND (@CostCenterId = '0' OR (CC_Jobs.CostCenterId IN (SELECT Value
                                                                FROM fn_Split(@CostCenterId, ','))))
          and (@chargeType = '0' OR (cd.DutyId in (select Value
                                                   from fn_Split(@chargeType, ','))))
	AND (@AccountId = '0' OR (cd.DutyId in(select CC_ExpensesAndInvoiceBandsAccount.MasterId 
	                     from CC_ExpensesAndInvoiceBandsAccount where CC_ExpensesAndInvoiceBandsAccount.AccountId
						 in (select Value from fn_Split(@AccountId, ',')))))					   
          and cast(CC_PayDuties.TransactDate_Gregi as date) >= @FirstDate and cast(CC_PayDuties.TransactDate_Gregi as date) <= @LastDate
          and (@FromValue = 0 or cd.Value >= @FromValue) and (@ToValue = 0 or cd.Value <= @ToValue)

      )

union all
select
  sp.NameA                         AS CustomerNameA,
  sp.NameE                         AS CustomerNameE,
  sp.Code                          AS CustomerCode,
  CC_Jobs.Code                     AS JobCode,
  ''               AS PayDutiesCode,
  ''                  AS PayDutiesId,
    CC_Agents.NameA                         AS AgentNameA,
  CC_Agents.NameE                         AS AgentNameE,
  CC_Invoices.JobId,
  CC_ExpensesAndInvoiceBands.NameA as BandNameA,
  CC_ExpensesAndInvoiceBands.NameE as BandNamee,
   0 as TaxValue,
    0 as Value,
  0 as RefundValue,
  CC_Invoices.Id                   AS InvoiceId,
  CC_Invoices.Code                 AS InvoiceCode,
  isnull(InvoiceDtl.TotalInLocal,0)     AS InvoiceValue,
  isnull(InvoiceDtl.TotalInLocal,0) as TotalValue,
  isnull(InvoiceDtl.Quantity,0) as Quantity,

     0 - isnull(InvoiceDtl.TotalInLocal,0)  AS Remain,

   '' as TransactDate_Gregi,
  '' as VoucherDate
from 
CC_Invoices
   left outer join CC_InvoicesDtl InvoiceDtl on InvoiceDtl.MasterId = CC_Invoices.Id
   left outer join CC_Jobs  on CC_Invoices.JobId = CC_Jobs.Id
  left outer join Sys_Partners sp on CC_Jobs.CustomerId = sp.Id
  left outer join CC_ExpensesAndInvoiceBands on InvoiceDtl.BandId = CC_ExpensesAndInvoiceBands.Id
  left outer join
  Sys_Ports AS ChargePort ON CC_Jobs.ChargePortId = ChargePort.Id
  LEFT OUTER JOIN
  Sys_Ports AS ArrivalPort ON CC_Jobs.ArrivalPortId = ArrivalPort.Id
  LEFT OUTER JOIN
  Sys_Countries ON CC_Jobs.OriginCountryId = Sys_Countries.Id
  LEFT OUTER JOIN
  CC_Agents ON CC_Jobs.AgentId = CC_Agents.Id
  LEFT OUTER JOIN
  CC_ExportCompanies ON CC_Jobs.ExportCompanyId = CC_ExportCompanies.Id
  
   left outer join  CC_JobFollowUp ON CC_JobFollowUp.Id = (SELECT TOP 1 Id FROM CC_JobFollowUp JFU
               WHERE CC_Jobs.Id = JFU.JobId AND (@OperationId = '0' OR(JFU.OperationId IN (SELECT VALUE
       FROM fn_Split(@OperationId, ','))))ORDER BY JFU.TransactDate_Gregi DESC, JFU.Id DESC)
  LEFT OUTER JOIN
  GL_ChartOfCostCenter ON CC_Jobs.CostCenterId = GL_ChartOfCostCenter.Id
where (@CmbReportStatus != 1 and CC_Invoices.CompanyId = @CompanyId and CC_Invoices.BranchId in (@BranchId)
       and ISNULL(CC_Invoices.Deleted, 0) = 0 AND ISNULL(InvoiceDtl.Total, 0) > 0
	   and ISNULL(CC_ExpensesAndInvoiceBands.PriceEqualToCost,0)=1
       and (InvoiceDtl.MasterId not in(select isnull(CC_PayDutiesDtl.InvoiceId,0) from CC_PayDutiesDtl join CC_PayDuties on CC_PayDuties.Id=CC_PayDutiesDtl.MasterId
	  where  CC_PayDutiesDtl.JobId=CC_Jobs.Id AND  ISNULL(CC_PayDuties.Deleted, 0)=0))
       and (@JobTypeId = '0' or (CC_Jobs.JobTypeId in (select Value
                                                       from fn_Split(@JobTypeId, ','))))
       and (@CustomerId = '0' or (CC_Jobs.CustomerId in (select Value
                                                         from fn_Split(@CustomerId, ','))))
       AND (@CustomerGroupId = '0' OR (ISNULL(sp.PartnerGroupId, 0) IN (SELECT Value
                                                                        FROM fn_Split(@CustomerGroupId, ','))))
	   and (@SalesRepresentativeId = '0' or CC_Jobs.CustomerId in (select CustomerId from Sys_SalesRepresentativeDtl
	             where MasterId in (select Value from fn_Split(@SalesRepresentativeId, ','))))
       and (@ChargePortId = '0' or (CC_Jobs.ChargePortId in (select Value
                                                             from fn_Split(@ChargePortId, ','))))
       and (@ArrivalPortId = '0' OR (CC_Jobs.ArrivalPortId in (select Value
                                                               from fn_Split(@ArrivalPortId, ','))))
       and (@AgentId = '0' or (CC_Jobs.AgentId in (select Value
                                                   from fn_Split(@AgentId, ','))))
       and (@ExportCompanyId = '0' OR (CC_Jobs.ExportCompanyId in (select Value
                                                                   from fn_Split(@ExportCompanyId, ','))))
       and (@JobId = '0' OR (CC_Jobs.Id in (select Value
                                            from fn_Split(@JobId, ','))))
and (@OperationId = '0' OR (CC_JobFollowUp.OperationId in (select Value
                                            from fn_Split(@OperationId, ','))))
       AND (@CostCenterId = '0' OR (CC_Jobs.CostCenterId IN (SELECT Value
                                                             FROM fn_Split(@CostCenterId, ','))))
       and (@chargeType = '0' OR (InvoiceDtl.BandId in (select Value
                                                from fn_Split(@chargeType, ','))))
	  AND (@AccountId = '0' OR (InvoiceDtl.BandId in(select CC_ExpensesAndInvoiceBandsAccount.MasterId 
	                     from CC_ExpensesAndInvoiceBandsAccount where CC_ExpensesAndInvoiceBandsAccount.AccountId
						 in (select Value from fn_Split(@AccountId, ',')))))	
       and cast(CC_Invoices.TransactDate_Gregi as date) >= @FirstDate and cast(CC_Invoices.TransactDate_Gregi as date) <= @LastDate
       and (@FromValue = 0 or InvoiceDtl.Total >= @FromValue) and (@ToValue = 0 or InvoiceDtl.Total <= @ToValue))
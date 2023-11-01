BEGIN
    DECLARE
        @CompanyId INT=1,
        @BranchId INT=1,
        @JobTypeId INT=0,
        @JobId INT=0,
		@TransJobTypeId int=0,
		@TransJobId INT=0,
        @CustomerId INT=0,
        @TransportationType INT=0,
        @LockStatus INT=0,
		@RouteStartingFrom INT=0,
		@RouteEndingIn INT=0,
		 @RouteContaining INT=0,
        @SupplierId INT = 0,
        @DriverId INT = 0,
        @TruckId INT=0,
        @RouteId INT=0,
        @EmptyReturn INT=0,
        @DocumentsReceive INT=0,
        @FirstDate DATETIME='2023-08-01',
        @LastDate DATETIME='2023-08-21',
        @HasInvoice INT = 0,
        @DeliverdStatus INT=0,
        @ContainerNo NVARCHAR(MAX)='',
		@PurchaseOrder NVARCHAR(MAX)='',
        @OperationId INT=0,
        @PendingOperationId INT=0,
        @SearchDateBy INT=1,
        @CostCenterId INT=0,
		@DriverGroupId INT=0,
		@TruckGroupId INT=0,
		@WaybillId INT=0,
		@WaybillsWithoutSource INT=0,
		@SupplierInvoice INT = 0;
		

with SupplierInvoice as
(
	 select top 5000
	        ROW_NUMBER() over( partition by Hdr.Id  order by Hdr.Id desc) as CountWaybills,
			count(Hdr.Id) as CountHdrId,
			Hdr.Id as WaybillId,
			--IsNull(Trans_SupplierInvoices.Deleted,0) as d,
			isnull(Hdr.SupplierId,0) as SupplierWaybill,
			IIf( (isnull(Dtl.WaybillId,0)>0 and isNull(Trans_SupplierInvoices.Deleted,0) = 0 ) 
								or (isnull(Dtl.WaybillId,0)=0)
								Or((isnull(Dtl.WaybillId,0)>0 and isNull(Trans_SupplierInvoices.Deleted,0) > 0)) ,1,0) as CheckWaybillInvoiced ,-- الاشعار له فاتورة
			IIf(isnull(Dtl.WaybillId,0)>0 and isNull(Trans_SupplierInvoices.Deleted,0) = 0 ,1,0) as WaybillHasInvoiced, -- الاشعار مفوتر وليس محذوف
			IIf((isnull(Dtl.WaybillId,0)=0 ) Or((isnull(Dtl.WaybillId,0)>0 and isNull(Trans_SupplierInvoices.Deleted,0)  > 0)),1,0) as WaybillNotInviced -- الاشعار غير مفوتر
		from Trans_Waybill Hdr
		Left Join Trans_SupplierInvoicesDtl Dtl ON Dtl.WaybillId = Hdr.Id 
		Left Join Trans_SupplierInvoices  ON Dtl.MasterId = Trans_SupplierInvoices.Id 
		where 
			isNull(Hdr.Deleted,0) = 0 
			AND (((@SearchDateBy = '0' OR @SearchDateBy = '1')
        AND Cast(Hdr.NoteDate_Gregi as date) >= @FirstDate
        AND Cast(Hdr.NoteDate_Gregi as date) <= @LastDate)
        OR
           ((@SearchDateBy = '2'
               AND Cast(Hdr.CustomerLoadingDate_Gregi as date) >= @FirstDate
               AND Cast(Hdr.CustomerLoadingDate_Gregi as date) <= @LastDate
               ))
			    OR
           ((@SearchDateBy = '3'
               AND Cast(Hdr.DocumentsReceivedDate_Gregi As date) >= @FirstDate
               AND Cast(Hdr.DocumentsReceivedDate_Gregi As date) <= @LastDate
               ))
			    OR
           ((@SearchDateBy = '4'
               AND Cast(Hdr.Post_Date As date) >= @FirstDate
               AND Cast(Hdr.Post_Date As date) <= @LastDate
               ))
        )
		AND Hdr.CompanyId = @CompanyId
      AND Hdr.BranchId IN (@BranchId)
		Group by
			Hdr.Id,
			Trans_SupplierInvoices.Deleted,
			Hdr.SupplierId,
			Dtl.WaybillId
)


    SELECT Top 5000 
			Trans_Waybill.Id,
           Trans_Waybill.TransferredQuantity              TransQTY,
           Trans_Waybill.Code,
           CASE
               WHEN Trans_Waybill.Source = 2 THEN CC_Jobs.Code
               WHEN Trans_Waybill.Source = 3 THEN Trans_Jobs.Code
               ELSE '' END                             AS JobCode,
           CASE
               WHEN Trans_Waybill.Source = 2 THEN
                   (SELECT TOP (1) Quantity FROM View_JobGoods WHERE JobId = CC_Jobs.Id)
               WHEN Trans_Waybill.Source = 3 THEN
                   (SELECT TOP (1) Quantity FROM View_TransJobGoods WHERE JobId = Trans_Jobs.Id)
               ELSE '' END                             AS 'GoodsNameA',
           CASE
               WHEN Trans_Waybill.Source = 2 THEN
                   (SELECT TOP (1) Quantity FROM View_JobGoods WHERE JobId = CC_Jobs.Id)
               WHEN Trans_Waybill.Source = 3 THEN
                   (SELECT TOP (1) Quantity FROM View_TransJobGoods WHERE JobId = Trans_Jobs.Id)
               ELSE '' END                             AS 'GoodsNameE',
           CASE
               WHEN Trans_Waybill.Source = 2 THEN CC_Jobs.GrossWeight
               ELSE Trans_Waybill.Weight END           AS Weight,
           Trans_Waybill.MasterBLNO,
           Trans_Waybill.NoteDate_Gregi,
           Trans_Waybill.CustomerLoadingDate_Gregi,
           isnull(Trans_Waybill.CustomerLoadingDate_Gregi, '2010-01-01'),
           Trans_Waybill.Receiver,
           Trans_Waybill.ReceiverAddress,
           Trans_Waybill.ReceiverTel,
		   Trans_Waybill.TransportationType,
           Trans_Waybill.TransferredQuantity,
           Trans_Waybill.ContainerNo,
           Trans_Waybill.GoodsDescription,
           Trans_Waybill.TransportationFees,
           Trans_Waybill.CustomerPrice,
           Priv_Users.NameA                            AS 'UserNameA',
           Priv_Users.NameE                            AS 'UserNameE',
           Trans_Routes.NameA                          AS 'RouteNameA',
           Trans_Routes.NameE                          AS 'RouteNameE',
           Customers.NameA                             AS 'CustomerNameA',
           Customers.NameE                             AS 'CustomerNameE',
           Sys_Branches.NameA                          AS 'BranchNameA',
           Sys_Branches.NameE                          AS 'BranchNameE',
           Sys_Branches.Id                             AS 'BranchId',
           Customers.Address,
           Customers.Telephone,
           CC_Vessels.NameA                            AS 'VesselNameA',
           CC_Vessels.NameE                            AS 'VesselNameE',

           Trans_Drivers.NameA                         AS 'DriverNameA',
           Trans_Drivers.NameE                         AS 'DriverNameE',
           Trans_Drivers.Code                          AS 'DriverCode',
           Trans_Trucks.PlateNo,
		   Suppliers.Code                             AS 'SupplierCode',
           Suppliers.NameA                             AS 'SupplierNameA',
           Suppliers.NameE                             AS 'SupplierNameE',
           CC_GoodsTypes.NameA                         AS 'GoodsTypeNameA',
           CC_GoodsTypes.NameE                         AS 'GoodsTypeNameE',
           CASE
               WHEN Trans_Waybill.ISDocumentsReceived = 0 THEN 'Not Received'
               ELSE 'Received' END                     AS ISDocumentsReceivedE,
           CASE
               WHEN Trans_Waybill.ISDocumentsReceived = 0 THEN 'لم يتم استلام '
               ELSE 'تم استلام ' END                   AS ISDocumentsReceivedA,
           CASE
               WHEN Trans_Waybill.ISDeliveredToCustomer = 0 THEN 'Not Delivered'
               ELSE 'Delivered' END                    AS ISDeliveredToCustomerE,
           CASE
               WHEN Trans_Waybill.ISDeliveredToCustomer = 0 THEN 'لم يتم التسليم '
               ELSE 'تم التسليم' END                   AS ISDeliveredToCustomerA,
           (isnull(Trans_Waybill.TransportAllowances, 0) + ISNULL(Trans_Waybill.TransportationFees, 0) +
            isnull(Trans_Waybill.DieselAllowances, 0)) AS TransportationExpense,
		
		   IIf(Trans_Waybill.TransportationType=1,Concat(Trans_Drivers.Code,'  ',Trans_Drivers.NameE), 
					iif(isnull(Trans_Waybill.DriverId,0)=0 or isnull(Trans_Waybill.SupplierId,0)>0,
										Concat(Suppliers.Code,'  ',Suppliers.NameE),
										Concat(Trans_Drivers.Code,'  ',Trans_Drivers.NameE) ) ) AS 'DriverName_E',
		   IIf(Trans_Waybill.TransportationType=1,Concat(Trans_Drivers.Code,'  ',Trans_Drivers.NameA), 
					iif(isnull(Trans_Waybill.DriverId,0)=0 or isnull(Trans_Waybill.SupplierId,0)>0,
										Concat(Suppliers.Code,'  ',Suppliers.NameA),
										Concat(Trans_Drivers.Code,'  ',Trans_Drivers.NameA) ) ) AS 'DriverName_A'
    FROM Trans_Waybill with(nolock)
             LEFT OUTER JOIN Trans_WaybillDtl with(nolock) ON Trans_Waybill.Id = Trans_WaybillDtl.MasterId
             LEFT OUTER JOIN Sys_Branches with(nolock) ON Trans_Waybill.BranchId = Sys_Branches.Id

             LEFT OUTER JOIN Priv_Users with(nolock) ON Trans_Waybill.Create_Uid = Priv_Users.id
             LEFT OUTER JOIN Trans_Routes with(nolock) ON Trans_Waybill.RouteId = Trans_Routes.Id
             LEFT OUTER JOIN GL_ChartOfCostCenter with(nolock) ON Trans_Routes.CostCenterId = GL_ChartOfCostCenter.Id
             LEFT OUTER JOIN Sys_Partners Customers with(nolock) ON Trans_Waybill.CustomerId = Customers.Id
             LEFT OUTER JOIN CC_Vessels with(nolock) ON Trans_Waybill.VesselId = CC_Vessels.Id
             LEFT OUTER JOIN Trans_Drivers with(nolock) ON Trans_Waybill.DriverId = Trans_Drivers.Id
             LEFT OUTER JOIN Trans_Trucks with(nolock) ON Trans_Waybill.TruckId = Trans_Trucks.Id
             LEFT OUTER JOIN Sys_Partners Suppliers with(nolock) ON Trans_Waybill.SupplierId = Suppliers.Id
             LEFT OUTER JOIN CC_Jobs  with(nolock) ON Trans_Waybill.JobId = CC_Jobs.Id
			  
             LEFT OUTER JOIN CC_GoodsTypes with(nolock) ON Trans_Waybill.GoodsTypeId = CC_GoodsTypes.Id
             LEFT OUTER JOIN Trans_Jobs with(nolock) ON Trans_Waybill.TransJobId = Trans_Jobs.Id
			 join SupplierInvoice on SupplierInvoice.WaybillId = Trans_Waybill.Id
    WHERE isnull(Trans_Waybill.Deleted, 0) = 0 
      AND Trans_Waybill.CompanyId = @CompanyId
      AND Trans_Waybill.BranchId IN (@BranchId)
	  AND (@WaybillId = '0' OR (Trans_Waybill.Id IN (SELECT Value FROM fn_Split(@WaybillId, ','))))
	  AND (@WaybillsWithoutSource = '0' OR (@WaybillsWithoutSource='1' and Trans_Waybill.Source=1))
	  AND (@TransJobTypeId = '0' OR (Trans_Jobs.JobTypeId IN (SELECT Value FROM fn_Split(@TransJobTypeId, ','))))
      AND (@JobTypeId = '0' OR (CC_Jobs.JobTypeId IN (SELECT Value FROM fn_Split(@JobTypeId, ','))))
	  AND ((@JobId = '0' AND @TransJobId = '0') OR (isnull(Trans_Waybill.JobId, 0) IN (SELECT Value FROM fn_Split(@JobId, ','))))
      AND ((@JobId = '0' AND @TransJobId = '0') OR (isnull(Trans_Waybill.TransJobId, 0) IN (SELECT Value FROM fn_Split(@TransJobId, ','))))
	  AND (@CustomerId = '0' OR (Trans_Waybill.CustomerId IN (SELECT Value FROM fn_Split(@CustomerId, ','))))
      AND (@TransportationType = '0' OR
      (Trans_Waybill.TransportationType IN (SELECT Value FROM fn_Split(@TransportationType, ','))))
      AND (@SupplierId = '0' OR (Trans_Waybill.SupplierId IN (SELECT Value FROM fn_Split(@SupplierId, ','))))
      AND (@DriverId = '0' OR (Trans_Waybill.DriverId IN (SELECT Value FROM fn_Split(@DriverId, ','))))
      AND (@TruckId = '0' OR (Trans_Waybill.TruckId IN (SELECT Value FROM fn_Split(@TruckId, ','))))
	  AND (@DriverGroupId = '0' OR (Trans_Drivers.DriverGroupId IN (SELECT Value FROM fn_Split(@DriverGroupId, ','))))
		  AND (@TruckGroupId = '0' OR (Trans_Trucks.TruckGroupId IN (SELECT Value FROM fn_Split(@TruckGroupId, ','))))
      AND (@RouteId = '0' OR (Trans_Waybill.RouteId IN (SELECT Value FROM fn_Split(@RouteId, ','))))
      AND (@CostCenterId = '0' OR (Trans_Routes.CostCenterId IN (SELECT Value FROM fn_Split(@CostCenterId, ','))))
      AND (@EmptyReturn = '0' OR (@EmptyReturn = '1' AND ISNULL(Trans_Waybill.ISEmptyReturned, 0) = 0) OR
           (@EmptyReturn = '2' AND ISNULL(Trans_Waybill.ISEmptyReturned, 0) = 1))
      AND (@DocumentsReceive = '0' OR (@DocumentsReceive = '1' AND ISNULL(Trans_Waybill.ISDocumentsReceived, 0) = 0) OR
           (@DocumentsReceive = '2' AND ISNULL(Trans_Waybill.ISDocumentsReceived, 0) = 1))
      AND (@LockStatus = '0' OR (@LockStatus = '1' AND ISNULL(Trans_Waybill.Post, 0) = 1) OR
           (@LockStatus = '2' AND ISNULL(Trans_Waybill.Post, 0) = 0))
      AND (((@SearchDateBy = '0' OR @SearchDateBy = '1')
        AND Cast(Trans_Waybill.NoteDate_Gregi as date) >= @FirstDate
        AND Cast(Trans_Waybill.NoteDate_Gregi as date) <= @LastDate)
        OR
           ((@SearchDateBy = '2'
               AND Cast(Trans_Waybill.CustomerLoadingDate_Gregi as date) >= @FirstDate
               AND Cast(Trans_Waybill.CustomerLoadingDate_Gregi as date) <= @LastDate
               ))
			    OR
           ((@SearchDateBy = '3'
               AND Cast(Trans_Waybill.DocumentsReceivedDate_Gregi As date) >= @FirstDate
               AND Cast(Trans_Waybill.DocumentsReceivedDate_Gregi As date) <= @LastDate
               ))
			    OR
           ((@SearchDateBy = '4'
               AND Cast(Trans_Waybill.Post_Date As date) >= @FirstDate
               AND Cast(Trans_Waybill.Post_Date As date) <= @LastDate
               ))
        )

      AND (
            (@HasInvoice = 0)
            OR
            (@HasInvoice = 1 AND (Trans_Waybill.HasCCInvoice = 1 OR Trans_Waybill.HasInvoice = 1))
            OR
            (@HasInvoice = 2 AND (Trans_Waybill.HasCCInvoice != 1 AND Trans_Waybill.HasInvoice != 1))
        )
		AND 
       (
			(@SupplierInvoice = 0  and  SupplierInvoice.CheckWaybillInvoiced = 1  and  SupplierInvoice.CountWaybills = 1) 
			OR
			(@SupplierInvoice = 1 and (SupplierInvoice.CheckWaybillInvoiced = 1 and  SupplierInvoice.WaybillHasInvoiced > 0)) OR -- تم عمل فاتورة للناقل ولم يتم مسحها
			---- تم عمل فاتورة ناقل لكن تم مسحها
			(@SupplierInvoice = 2 and WaybillNotInviced > 0 and SupplierInvoice.CheckWaybillInvoiced = 1 and SupplierInvoice.CountWaybills = 1 and SupplierInvoice.SupplierWaybill > 0 )
									)
      AND (@DeliverdStatus = '0' OR (@DeliverdStatus = '1' AND ISNULL(Trans_Waybill.ISDocumentsReceived, 0) = 1 AND
                                     ISNULL(Trans_Waybill.ISDeliveredToCustomer, 0) = 1) OR
           (@DeliverdStatus = '2' AND ISNULL(Trans_Waybill.ISDocumentsReceived, 0) = 0))
      AND (@OperationId = '0' OR (Trans_WaybillDtl.OperationId IN (SELECT Value FROM fn_Split(@OperationId, ','))))
      AND (@PendingOperationId = '0' OR
           (Trans_WaybillDtl.OperationId NOT IN (SELECT Value FROM fn_Split(@PendingOperationId, ','))))
      AND (@ContainerNo = '' OR ContainerNo LIKE '%' + @ContainerNo + '%')
	  	  AND (@PurchaseOrder = '' OR TransPurchaseOrder LIKE '%' + @PurchaseOrder + '%' OR CCPurchaseOrder LIKE '%' + @PurchaseOrder + '%') 
	    AND (@RouteStartingFrom = '0'   --Agent There is no Route that start From Agent
		OR @RouteStartingFrom = '1'and isnull(Trans_Waybill.GoodsTransport,0) in(1,2,3,10) --port
		OR @RouteStartingFrom = '2'and isnull(Trans_Waybill.GoodsTransport,0) in(4,5,6,7,12) --Yard
		OR @RouteStartingFrom = '3'and isnull(Trans_Waybill.GoodsTransport,0) in(8,9,11,13)) --Customer

		 AND (@RouteEndingIn = '0'  
		OR @RouteEndingIn = '1'and isnull(Trans_Waybill.GoodsTransport,0) in(8,10,12,15,16,18) --port
		OR @RouteEndingIn = '2'and isnull(Trans_Waybill.GoodsTransport,0) in(1,2,4,7,13,14) --Yard
		OR @RouteEndingIn = '3'and isnull(Trans_Waybill.GoodsTransport,0) in(9,17) --Customer
		OR @RouteEndingIn = '4'and isnull(Trans_Waybill.GoodsTransport,0) in(3,5,6,11))--Agent

		 AND (@RouteContaining = '0'  
		OR @RouteContaining = '1'and isnull(Trans_Waybill.GoodsTransport,0) in(1,2,3,8,10,12,15,16,18) --port
		OR @RouteContaining = '2'and isnull(Trans_Waybill.GoodsTransport,0) in(1,2,4,5,6,7,12,13,14,16) --Yard
		OR @RouteContaining = '3'and isnull(Trans_Waybill.GoodsTransport,0) in(2,3,4,5,9,8,11,13,17,18) --Customer
		OR @RouteContaining = '4'and isnull(Trans_Waybill.GoodsTransport,0) in(3,5,6,9,11,14,15,16,17,18))--Agent


			 order by Trans_Waybill.Id 
END




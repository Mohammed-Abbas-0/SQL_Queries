-- Indexes  Region
			Create nonClustered Index IX_MasterId on CC_JobGoods(MasterId)
			INCLUDE (Quantity,GoodsTypeId)
			WITH (DROP_EXISTING=ON,  FILLFACTOR=90);

			Create nonClustered Index IX_GoodsTransport on Trans_Waybill(GoodsTransport)
			INCLUDE (Id,TransferredQuantity,Code,Source,CustomerLoadingDate_Gregi,NoteDate_Gregi,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);

			Create nonClustered Index IX_MasterId on Trans_JobGoods(MasterId)
			INCLUDE (Quantity,GoodsTypeId)
			WITH (DROP_EXISTING=ON,  FILLFACTOR=90);

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_Deleted')
			Begin
				Create nonClustered Index IX_Deleted on Trans_Waybill(Deleted)
				INCLUDE (Id,TransferredQuantity,Code,Source,CustomerLoadingDate_Gregi,NoteDate_Gregi,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_Source')
			Begin
				Create nonClustered Index IX_Source on Trans_Waybill(Source)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_ISDocumentsReceived')
			Begin
				Create nonClustered Index IX_ISDocumentsReceived on Trans_Waybill(ISDocumentsReceived)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,Source,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_Post')
			Begin
				Create nonClustered Index IX_Post on Trans_Waybill(Post)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,Source,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_NoteDate_Gregi')
			Begin
				Create nonClustered Index IX_NoteDate_Gregi on Trans_Waybill(NoteDate_Gregi)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,Source,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_CustomerLoadingDate_Gregi')
			Begin
				Create nonClustered Index IX_CustomerLoadingDate_Gregi on Trans_Waybill(CustomerLoadingDate_Gregi)
				INCLUDE (Id,TransferredQuantity,Code,NoteDate_Gregi,Source,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_DocumentsReceivedDate_Gregi')
			Begin
				Create nonClustered Index IX_DocumentsReceivedDate_Gregi on Trans_Waybill(DocumentsReceivedDate_Gregi)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,Source,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_Post_Date')
			Begin
				Create nonClustered Index IX_Post_Date on Trans_Waybill(Post_Date)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,Source,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_HasCCInvoice')
			Begin
				Create nonClustered Index IX_HasCCInvoice on Trans_Waybill(HasCCInvoice)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,Source,
							TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END

			IF NOT EXISTS(SELECT name FROM sys.indexes WHERE name = 'IX_HasInvoice')
			Begin
				Create nonClustered Index IX_HasInvoice on Trans_Waybill(HasInvoice)
				INCLUDE (Id,TransferredQuantity,Code,CustomerLoadingDate_Gregi,NoteDate_Gregi,Source,
						
						TransportationType,GoodsDescription,TransportationFees,CustomerPrice,ISDocumentsReceived,TransportAllowances,
							DieselAllowances,DriverId,SupplierId,BranchId,JobId,TruckId,VesselId,CustomerId,RouteId,Create_Uid,GoodsTypeId,TransJobId);
			END
		-- END


;